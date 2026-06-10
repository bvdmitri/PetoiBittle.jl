# Live IMU dashboard: real-time Bayesian filtering of Petoi Bittle gyro data with RxInfer + GLMakie.
#
# The demo runs two inference pipelines over the same raw IMU stream:
#   - "calibrated": uses per-axis sensor bias and observation noise precision learned
#     with RxInfer during an initial stationary calibration phase;
#   - "uncalibrated": same sliding-window model, but assumes zero bias and a naive
#     overconfident noise precision, so it stays offset and jittery.
# The dashboard shows a 3D view of the robot orientation (solid box = calibrated,
# translucent ghost = uncalibrated) and three time-series panels (yaw, pitch, roll)
# overlaying calibrated, uncalibrated, and raw measurements.
#
# Runs indefinitely until CTRL-C or the Makie window is closed. Example invocations:
#
#   julia --project=examples examples/5_live_imu_dashboard.jl --simulate
#   julia --project=examples examples/5_live_imu_dashboard.jl --window-size 100 --show-raw false

using PetoiBittle
using Logging
using ArgParse
using GLMakie
using RxInfer
using Printf

Logging.global_logger(ConsoleLogger(Logging.Info))

# Without this, CTRL-C kills the process before the `finally` block (robot teardown) runs
# when the script is executed as `julia script.jl`.
Base.exit_on_sigint(false)

# ------------------------------------------------------------------
# Command line arguments
# ------------------------------------------------------------------

argsettings = ArgParseSettings(
    description = "Live IMU dashboard: real-time Bayesian filtering of Petoi Bittle gyro data"
)

@add_arg_table! argsettings begin
    "--simulate"
    help = "run without hardware using a synthetic IMU generator"
    action = :store_true
    "--port"
    help = "serial port of the robot; auto-discovered when omitted"
    arg_type = String
    default = ""
    "--rate"
    help = "polling rate in Hz"
    arg_type = Float64
    default = 20.0
    "--window-size"
    help = "number of samples in the sliding inference window"
    arg_type = Int
    default = 20
    "--history"
    help = "show only the last N seconds in the time-series charts"
    arg_type = Float64
    default = 10.0
    "--calib-seconds"
    help = "duration of the stationary calibration phase in seconds"
    arg_type = Float64
    default = 5.0
    "--infer-stride"
    help = "run inference every N polled samples"
    arg_type = Int
    default = 2
    "--process-std"
    help = "random-walk std (degrees per step) of the latent state"
    arg_type = Float64
    default = 1.0
    "--show-uncalibrated"
    help = "overlay the uncalibrated estimate (true/false)"
    arg_type = Bool
    default = true
    "--show-raw"
    help = "overlay raw unfiltered measurements (true/false)"
    arg_type = Bool
    default = true
end

args = parse_args(argsettings)

const POLL_PERIOD = 1.0 / args["rate"]
const WINDOW_SIZE = args["window-size"]
const HISTORY_SECONDS = args["history"]
const INFER_STRIDE = args["infer-stride"]
const PROCESS_VARIANCE = abs2(args["process-std"])

# The uncalibrated pipeline assumes the sensor is nearly perfect (std of 0.1 degrees,
# far below the real noise level). This overconfidence makes its estimate chase every
# raw fluctuation, which is exactly how a model with unestimated parameters misbehaves.
const UNCALIBRATED_W = 100.0

# ------------------------------------------------------------------
# Helpers: rotations and yaw unwrapping
# ------------------------------------------------------------------

# ZYX intrinsic Euler angles: yaw about z (up), pitch about y, roll about x (forward = +x).
# Note: the sign of the pitch reported by the Petoi firmware may need flipping when
# compared against the physical robot; adjust empirically if the box tilts the wrong way.
function euler_to_quat(yaw_deg, pitch_deg, roll_deg)
    cy, sy = cos(deg2rad(yaw_deg) / 2), sin(deg2rad(yaw_deg) / 2)
    cp, sp = cos(deg2rad(pitch_deg) / 2), sin(deg2rad(pitch_deg) / 2)
    cr, sr = cos(deg2rad(roll_deg) / 2), sin(deg2rad(roll_deg) / 2)
    return Makie.Quaternionf( # (x, y, z, w); Quaternionf(0, 0, 0, 1) is the identity
        sr * cp * cy - cr * sp * sy,
        cr * sp * cy + sr * cp * sy,
        cr * cp * sy - sr * sp * cy,
        cr * cp * cy + sr * sp * sy,
    )
end

# Unit vector the robot "looks at" given yaw and pitch (degrees).
heading(yaw_deg, pitch_deg) = Vec3f(
    cosd(pitch_deg) * cosd(yaw_deg),
    cosd(pitch_deg) * sind(yaw_deg),
    -sind(pitch_deg),
)

# The firmware reports yaw in +-180 degrees. We maintain a continuous (unwrapped) yaw so
# the random-walk model never sees a fake +-360 jump when the heading crosses the boundary.
mutable struct YawUnwrapper
    initialized::Bool
    previous_raw::Float64
    unwrapped::Float64
end

YawUnwrapper() = YawUnwrapper(false, 0.0, 0.0)

function unwrap!(u::YawUnwrapper, yaw_raw::Float64)
    if !u.initialized
        u.initialized = true
        u.previous_raw = yaw_raw
        u.unwrapped = yaw_raw
        return u.unwrapped
    end
    u.unwrapped += rem(yaw_raw - u.previous_raw, 360.0, RoundNearest)
    u.previous_raw = yaw_raw
    return u.unwrapped
end

# ------------------------------------------------------------------
# Synthetic IMU for --simulate mode
# ------------------------------------------------------------------

mutable struct SimulatedBittle
    bias::NTuple{3, Float64} # true sensor bias, known only to the generator
    noise_std::Float64
    moving::Bool
    t0::Float64
end

SimulatedBittle() = SimulatedBittle((4.0, -3.0, 2.5), 0.6, false, time())

function poll_gyro(sim::SimulatedBittle)
    if sim.moving
        t = time() - sim.t0
        yaw = 40 * sin(2π * 0.05 * t)
        pitch = 15 * sin(2π * 0.11 * t)
        roll = 10 * sin(2π * 0.07 * t + 1.0)
    else
        yaw = pitch = roll = 0.0
    end
    noise() = sim.noise_std * randn()
    return PetoiBittle.GyroStatsOutput(
        yaw + sim.bias[1] + noise(),
        pitch + sim.bias[2] + noise(),
        roll + sim.bias[3] + noise(),
        0, 0, 0,
    )
end

# ------------------------------------------------------------------
# RxInfer models
# ------------------------------------------------------------------

# Calibration model: jointly estimates the per-axis sensor bias (stationary mean) and the
# observation noise precision from measurements collected while the robot stands still.
# Normal-Gamma is not jointly conjugate under belief propagation, hence the mean-field
# constraint and the explicit initialization of q(w).
@model function calibrate_axis(y)
    bias ~ NormalMeanVariance(0.0, 1.0e4)
    w ~ Gamma(shape = 1.0, rate = 1.0e-2)
    for i in eachindex(y)
        y[i] ~ NormalMeanPrecision(bias, w)
    end
end

calibration_constraints = @constraints begin
    q(bias, w) = q(bias)q(w)
end

calibration_init = @initialization begin
    q(w) = GammaShapeRate(1.0, 1.0)
end

function calibrate(samples::Vector{Float64})
    result = infer(
        model = calibrate_axis(),
        data = (y = samples,),
        constraints = calibration_constraints,
        initialization = calibration_init,
        iterations = 20,
        free_energy = false,
    )
    return (bias = mean(last(result.posteriors[:bias])), w = mean(last(result.posteriors[:w])))
end

# Sliding-window smoother: a 1D Gaussian random walk observed with known noise precision.
# Fully conjugate, so inference is a single exact belief propagation pass. The sensor bias
# is pre-subtracted from the data (mathematically identical to modeling it as an additive
# term), which lets the calibrated and uncalibrated pipelines share this model.
@model function sliding_window_smoother(y, w, q_var, x0_mean, x0_var)
    x_prev ~ NormalMeanVariance(x0_mean, x0_var)
    for i in eachindex(y)
        x[i] ~ NormalMeanVariance(x_prev, q_var)
        y[i] ~ NormalMeanPrecision(x[i], w)
        x_prev = x[i]
    end
end

function run_window(y::Vector{Float64}, bias::Float64, w::Float64)
    yc = y .- bias
    result = infer(
        model = sliding_window_smoother(w = w, q_var = PROCESS_VARIANCE, x0_mean = yc[1], x0_var = 25.0),
        data = (y = yc,),
        free_energy = false,
    )
    last_state = last(result.posteriors[:x])
    return (mean(last_state), std(last_state))
end

# ------------------------------------------------------------------
# Connect to the robot (or set up the simulator)
# ------------------------------------------------------------------

connection = nothing
simulator = nothing

if args["simulate"]
    @info "Running in simulation mode, no hardware required"
    simulator = SimulatedBittle()
else
    port = isempty(args["port"]) ? PetoiBittle.find_bittle_port() : args["port"]
    @info "Using port $(port) to connect to PetoiBittle"
    connection = PetoiBittle.connect(port)
    @info "Sleeping for 5 seconds to let the Petoi Bittle initialize"
    sleep(5)
    @info "Getting into calibration position"
    PetoiBittle.send_command(connection, PetoiBittle.Skill("calib"))
    @info "Calibrating gyro (takes around 17 seconds)"
    PetoiBittle.send_command(connection, PetoiBittle.GyroCalibrate())
end

poll() = args["simulate"] ? poll_gyro(simulator) : PetoiBittle.send_command(connection, PetoiBittle.GyroStats())

# ------------------------------------------------------------------
# Stationary calibration phase: estimate per-axis bias and noise precision
# ------------------------------------------------------------------

@info "Collecting $(args["calib-seconds"]) seconds of stationary measurements for calibration"

calib_yaw = Float64[]
calib_pitch = Float64[]
calib_roll = Float64[]

# The same unwrapper is reused in the main loop so the yaw reference estimated here and
# the live measurements share one continuous frame, even when the robot's heading sits
# right at the +-180 degrees wrap boundary during calibration.
yaw_unwrapper = YawUnwrapper()

for _ in 1:ceil(Int, args["calib-seconds"] / POLL_PERIOD)
    measurement = poll()
    push!(calib_yaw, unwrap!(yaw_unwrapper, measurement.yaw))
    push!(calib_pitch, measurement.pitch)
    push!(calib_roll, measurement.roll)
    sleep(POLL_PERIOD)
end

@info "Estimating sensor bias and noise precision with RxInfer"

calibration = (
    yaw = calibrate(calib_yaw),
    pitch = calibrate(calib_pitch),
    roll = calibrate(calib_roll),
)

# Yaw heading is arbitrary, so a "yaw bias" is unidentifiable from a stationary pose.
# The stationary yaw mean is instead treated as a shared reference zero, subtracted from
# the raw yaw in BOTH pipelines. Pitch and roll biases are genuine sensor offsets (the
# true pitch/roll is ~0 in the calibration posture) and are corrected only in the
# calibrated pipeline.
yaw_reference = calibration.yaw.bias

calibrated_params = (
    yaw = (bias = 0.0, w = calibration.yaw.w),
    pitch = (bias = calibration.pitch.bias, w = calibration.pitch.w),
    roll = (bias = calibration.roll.bias, w = calibration.roll.w),
)

uncalibrated_params = (
    yaw = (bias = 0.0, w = UNCALIBRATED_W),
    pitch = (bias = 0.0, w = UNCALIBRATED_W),
    roll = (bias = 0.0, w = UNCALIBRATED_W),
)

@info "Calibration finished" calibration.yaw calibration.pitch calibration.roll

if args["simulate"]
    @info "Simulator ground truth (compare with the estimates above)" true_bias = simulator.bias true_precision = 1 / abs2(simulator.noise_std)
    simulator.moving = true
    simulator.t0 = time()
end

@info "Warming up the sliding-window inference (first call compiles the model)"
run_window(randn(WINDOW_SIZE), 0.0, 1.0)

# ------------------------------------------------------------------
# Dashboard construction
# ------------------------------------------------------------------

const AXES = (:yaw, :pitch, :roll)

GLMakie.activate!()

fig = Figure(size = (1600, 900))

# --- 3D orientation view ---

ax3 = Axis3(
    fig[1:3, 1];
    aspect = :data,
    title = "Robot orientation",
    limits = (-1.5, 1.5, -1.5, 1.5, -1.5, 1.5),
    viewmode = :fit,
)

quat_cal = Observable(Makie.Quaternionf(0, 0, 0, 1))
quat_uncal = Observable(Makie.Quaternionf(0, 0, 0, 1))
dir_cal = Observable(Vec3f(1, 0, 0))
dir_uncal = Observable(Vec3f(1, 0, 0))

body = Rect3f(Vec3f(-0.5, -0.3, -0.15), Vec3f(1.0, 0.6, 0.3)) # long axis = +x = forward

meshscatter!(ax3, [Point3f(0)]; marker = body, markersize = 1, rotation = quat_cal, color = :dodgerblue)
meshscatter!(
    ax3, [Point3f(0)];
    marker = body, markersize = 1, rotation = quat_uncal,
    color = (:orange, 0.25), transparency = true, visible = args["show-uncalibrated"],
)
arrows3d!(
    ax3, Observable([Point3f(0)]), lift(d -> [1.2f0 * d], dir_cal);
    color = :dodgerblue,
)
arrows3d!(
    ax3, Observable([Point3f(0)]), lift(d -> [1.2f0 * d], dir_uncal);
    color = (:orange, 0.4), transparency = true, visible = args["show-uncalibrated"],
)

# --- time-series panels ---

raw_obs = map(_ -> Observable(Point2f[]), NamedTuple{AXES}(AXES))
cal_obs = map(_ -> Observable(Point2f[]), NamedTuple{AXES}(AXES))
uncal_obs = map(_ -> Observable(Point2f[]), NamedTuple{AXES}(AXES))
band_lo_obs = map(_ -> Observable(Point2f[]), NamedTuple{AXES}(AXES))
band_hi_obs = map(_ -> Observable(Point2f[]), NamedTuple{AXES}(AXES))

function make_series_axis(row::Int, axis::Symbol)
    ax = Axis(fig[row, 2]; title = titlecase(String(axis)), xlabel = row == 3 ? "time (s)" : "", ylabel = "degrees")
    band!(ax, band_lo_obs[axis], band_hi_obs[axis]; color = (:dodgerblue, 0.25), label = "calibrated 3σ")
    lines!(
        ax, uncal_obs[axis];
        color = :orange, linewidth = 1.5, visible = args["show-uncalibrated"], label = "uncalibrated",
    )
    lines!(ax, cal_obs[axis]; color = :dodgerblue, linewidth = 2.5, label = "calibrated")
    # Raw measurements are drawn last so the flaky dots stay visible on top of the curves.
    scatter!(
        ax, raw_obs[axis];
        color = (:gray, 0.6), markersize = 5, visible = args["show-raw"], label = "raw",
    )
    return ax
end

series_axes = (yaw = make_series_axis(1, :yaw), pitch = make_series_axis(2, :pitch), roll = make_series_axis(3, :roll))

# --- numeric readout column ---

# A monospace font keeps the decimal dots vertically aligned in the readout column.
# `findfont` fuzzy-matches, so verify the resolved family before trusting it and fall
# back to the default font when no common monospace candidate is installed.
monospace_font = let candidates = ("Menlo", "Consolas", "Courier New", "DejaVu Sans Mono")
    idx = findfirst(candidates) do name
        font = Makie.FreeTypeAbstraction.findfont(name)
        font !== nothing && startswith(lowercase(font.family_name), lowercase(first(split(name))))
    end
    idx === nothing ? :regular : candidates[idx]
end

value_text = map(_ -> Observable("waiting for data..."), NamedTuple{AXES}(AXES))

for (row, axis) in enumerate(AXES)
    # The monospace formatting keeps every line the same width, so the column can size
    # itself from the labels (tellwidth = true) without the layout jittering.
    Label(
        fig[row, 3], value_text[axis];
        halign = :left, justification = :left, tellheight = false, tellwidth = true,
        fontsize = 15, font = monospace_font,
    )
end

colsize!(fig.layout, 1, Relative(0.4))

axislegend(series_axes.yaw; position = :lt, framevisible = true)

# ------------------------------------------------------------------
# Data buffers
# ------------------------------------------------------------------

mutable struct AxisBuffers
    window::Vector{Float64}              # sliding inference window (last WINDOW_SIZE samples)
    raw_t::Vector{Float64}               # raw history, trimmed to HISTORY_SECONDS
    raw_v::Vector{Float64}
    cal_t::Vector{Float64}               # calibrated estimate history (t, mean, std)
    cal_m::Vector{Float64}
    cal_s::Vector{Float64}
    uncal_t::Vector{Float64}             # uncalibrated estimate history (t, mean, std)
    uncal_m::Vector{Float64}
    uncal_s::Vector{Float64}
end

AxisBuffers() = AxisBuffers((Float64[] for _ in 1:9)...)

buffers = NamedTuple{AXES}((AxisBuffers(), AxisBuffers(), AxisBuffers()))

function trim_history!(ts::Vector{Float64}, vs::Vector{Float64}...; tnow::Float64)
    while !isempty(ts) && first(ts) < tnow - HISTORY_SECONDS
        popfirst!(ts)
        foreach(popfirst!, vs)
    end
end

function push_sample!(b::AxisBuffers, t::Float64, value::Float64)
    push!(b.window, value)
    length(b.window) > WINDOW_SIZE && popfirst!(b.window)
    push!(b.raw_t, t)
    push!(b.raw_v, value)
    trim_history!(b.raw_t, b.raw_v; tnow = t)
end

function update_estimates!(b::AxisBuffers, t::Float64, cal, uncal)
    cal_mean, cal_std = run_window(b.window, cal.bias, cal.w)
    uncal_mean, uncal_std = run_window(b.window, uncal.bias, uncal.w)
    push!(b.cal_t, t); push!(b.cal_m, cal_mean); push!(b.cal_s, cal_std)
    push!(b.uncal_t, t); push!(b.uncal_m, uncal_mean); push!(b.uncal_s, uncal_std)
    trim_history!(b.cal_t, b.cal_m, b.cal_s; tnow = t)
    trim_history!(b.uncal_t, b.uncal_m, b.uncal_s; tnow = t)
end

# Multi-line numeric readout shown next to the chart, e.g.
#   Yaw (calibrated)       0.00 ±  1.00
#   Yaw (uncalibrated)     0.00 ±  0.20
#   Yaw (raw)              0.31241
# The ± value is 3 standard deviations, matching the shaded band. The field widths are
# chosen so that with the monospace font every decimal dot lands in the same column:
# %9.2f and %12.5f both place the dot at the 7th character of the field.
function format_values(axis::Symbol, b::AxisBuffers)
    name = titlecase(String(axis))
    readout = String[]
    if !isempty(b.cal_m)
        push!(readout, @sprintf("%s (calibrated)   %9.2f ± %5.2f", name, last(b.cal_m), 3 * last(b.cal_s)))
    end
    if args["show-uncalibrated"] && !isempty(b.uncal_m)
        push!(readout, @sprintf("%s (uncalibrated) %9.2f ± %5.2f", name, last(b.uncal_m), 3 * last(b.uncal_s)))
    end
    if args["show-raw"] && !isempty(b.raw_v)
        push!(readout, @sprintf("%s (raw)          %12.5f", name, last(b.raw_v)))
    end
    return isempty(readout) ? "waiting for data..." : join(readout, "\n")
end

function update_axis_observables!(axis::Symbol, b::AxisBuffers, tnow::Float64)
    value_text[axis][] = format_values(axis, b)
    raw_obs[axis][] = Point2f.(b.raw_t, b.raw_v)
    cal_obs[axis][] = Point2f.(b.cal_t, b.cal_m)
    uncal_obs[axis][] = Point2f.(b.uncal_t, b.uncal_m)
    band_lo_obs[axis][] = Point2f.(b.cal_t, b.cal_m .- 3 .* b.cal_s)
    band_hi_obs[axis][] = Point2f.(b.cal_t, b.cal_m .+ 3 .* b.cal_s)

    ax = series_axes[axis]
    xlims!(ax, max(0.0, tnow - HISTORY_SECONDS), max(tnow, HISTORY_SECONDS / 10))
    # Manual y-limits from the visible data with 10% padding: `autolimits!` would fight
    # the rolling x-limits and jitter every frame.
    lo, hi = Inf, -Inf
    for vs in (b.raw_v, b.cal_m, b.uncal_m)
        isempty(vs) && continue
        lo = min(lo, minimum(vs))
        hi = max(hi, maximum(vs))
    end
    if !isempty(b.cal_s)
        lo = min(lo, minimum(b.cal_m .- 3 .* b.cal_s))
        hi = max(hi, maximum(b.cal_m .+ 3 .* b.cal_s))
    end
    if isfinite(lo) && isfinite(hi)
        pad = max(0.1 * (hi - lo), 1.0)
        ylims!(ax, lo - pad, hi + pad)
    end
end

# ------------------------------------------------------------------
# Main loop
# ------------------------------------------------------------------

@info "Starting the live dashboard, close the window or press CTRL-C to stop"
if !args["simulate"]
    @info "Move the PetoiBittle around to see the estimates react"
end

display(fig)

t_start = time()
sample_count = 0

try
    while events(fig).window_open[]
        global sample_count += 1
        t_loop = time()
        t = t_loop - t_start

        measurement = poll()
        yaw = unwrap!(yaw_unwrapper, measurement.yaw) - yaw_reference
        push_sample!(buffers.yaw, t, yaw)
        push_sample!(buffers.pitch, t, measurement.pitch)
        push_sample!(buffers.roll, t, measurement.roll)

        if sample_count % INFER_STRIDE == 0 && length(buffers.yaw.window) >= WINDOW_SIZE
            t_infer = time()
            update_estimates!(buffers.yaw, t, calibrated_params.yaw, uncalibrated_params.yaw)
            update_estimates!(buffers.pitch, t, calibrated_params.pitch, uncalibrated_params.pitch)
            update_estimates!(buffers.roll, t, calibrated_params.roll, uncalibrated_params.roll)
            @debug "Inference step took $(round(1000 * (time() - t_infer), digits = 1)) ms"

            quat_cal[] = euler_to_quat(last(buffers.yaw.cal_m), last(buffers.pitch.cal_m), last(buffers.roll.cal_m))
            dir_cal[] = heading(last(buffers.yaw.cal_m), last(buffers.pitch.cal_m))
            quat_uncal[] = euler_to_quat(last(buffers.yaw.uncal_m), last(buffers.pitch.uncal_m), last(buffers.roll.uncal_m))
            dir_uncal[] = heading(last(buffers.yaw.uncal_m), last(buffers.pitch.uncal_m))
        end

        for axis in AXES
            update_axis_observables!(axis, buffers[axis], t)
        end

        sleep(max(0.001, POLL_PERIOD - (time() - t_loop)))
    end
    @info "Window closed, shutting down"
catch e
    if e isa InterruptException
        @info "Interrupted, shutting down"
    else
        rethrow()
    end
finally
    if connection !== nothing
        @info "Returning to rest posture and disconnecting"
        try
            PetoiBittle.send_command(connection, PetoiBittle.Rest())
        catch
        end
        PetoiBittle.disconnect(connection)
    end
end
