using PetoiBittle
using Logging
using Plots

Logging.global_logger(ConsoleLogger(Logging.Info))

port = PetoiBittle.find_bittle_port()

@info "Using port $(port) to connect to PetoiBittle"

connection = PetoiBittle.connect(port)

@info "Sleeping for 5 seconds to let the Petoi Bittle initialize"
sleep(5)

@info "Getting into calibration position"
PetoiBittle.send_command(connection, PetoiBittle.Skill("calib"))

@info "Calibrating gyro"
PetoiBittle.send_command(connection, PetoiBittle.GyroCalibrate())
@info "Collecting measurements for sensor noise estimation"

measurement_for_noise_estimations = []

time_to_collect = 5 # in seconds
sleep_between = 0.1 # in seconds
n_measurement_for_noise_estimations = time_to_collect / sleep_between

for i in 1:n_measurement_for_noise_estimations
    command = PetoiBittle.GyroStats()
    measurement_for_noise_estimation = PetoiBittle.send_command(connection, command)
    @info measurement_for_noise_estimation
    push!(measurement_for_noise_estimations, measurement_for_noise_estimation)
    sleep(sleep_between)
end

@info "Running Bayesian Analysis with RxInfer"

using RxInfer, Rocket

measurement_to_vector(measurement::PetoiBittle.GyroStatsOutput) = [
    measurement.yaw,
    measurement.pitch,
    measurement.roll,
    measurement.acceleration_x,
    measurement.acceleration_y,
    measurement.acceleration_z,
]

vmeasurements = measurement_to_vector.(measurement_for_noise_estimations)
mean_measurements = mean(vmeasurements)
cov_measurements = cov(vmeasurements)

# We first will estimate the measurement noise for each sensor assuming stationary noise
@model function estimate_stationary_noise(vmeasurements, dimensions, mean)
    W ~ Uninformative()
    for i in eachindex(vmeasurements)
        vmeasurements[i] ~ MvNormal(mean=mean, precision=W)
    end
end

result = infer(
    model=estimate_stationary_noise(dimensions=6, mean=mean_measurements),
    data=(vmeasurements=vmeasurements,)
)

observation_noise_precision = mean(result.posteriors[:W])

@info "Estimated observation noise precision is" observation_noise_precision

@info "Creating reactive Kalman Filter with RxInfer"

@model function reactive_kalman_filter(
    current_observation,
    previous_state_mean,
    previous_state_covariance,
    observation_noise_precision
)
    previous_state ~ MvNormal(
        mean=previous_state_mean,
        covariance=previous_state_covariance
    )
    current_state ~ MvNormal(mean=previous_state, covariance=diageye(6))
    current_observation ~ MvNormal(mean=current_state, precision=observation_noise_precision)
end

@initialization function initialize_reactive_kalman_filter()
    q(current_state) = MvNormalMeanCovariance(mean_measurements, cov_measurements)
end

@autoupdates function autoupdate_reactive_kalman_filter()
    (previous_state_mean, previous_state_covariance) = mean_cov(q(current_state))
end

datastream = Rocket.RecentSubject(Vector{Float64})
observations_for_reactive_kalman_filter = Rocket.labeled(Val((:current_observation, )), Rocket.combineLatest(datastream))

info_subscription = Rocket.subscribe!(datastream, (d) -> @info("Got new data $(d)"))

engine = infer(
    model = reactive_kalman_filter(observation_noise_precision = observation_noise_precision),
    datastream = observations_for_reactive_kalman_filter, 
    autoupdates = autoupdate_reactive_kalman_filter(),
    initialization = initialize_reactive_kalman_filter(),
    returnvars = (:current_state, ),
    autostart = false
)

posteriors = []
posteriors_subscription = subscribe!(engine.posteriors[:current_state], (q) -> push!(posteriors, q))

RxInfer.start(engine)

@info "Move the PetoiBittle now"

time_to_collect = 30 # in seconds
sleep_between = 0.1 # in seconds
n_measurements = time_to_collect / sleep_between

for i in 1:n_measurements
    command = PetoiBittle.GyroStats()
    measurement = PetoiBittle.send_command(connection, command)
    Rocket.next!(datastream, measurement_to_vector(measurement))
    sleep(sleep_between)
end

RxInfer.stop(engine)

estimated_mean = mean.(posteriors)
estimated_var = std.(posteriors)

pyaw = plot(getindex.(estimated_mean, 1), ribbon = 3getindex.(estimated_var, 1, 1); title = "Filtered yaw")
ppitch = plot(getindex.(estimated_mean, 2), ribbon = 3getindex.(estimated_var, 2, 2); title = "Filtered pitch")
proll = plot(getindex.(estimated_mean, 3), ribbon = 3getindex.(estimated_var, 3, 3); title = "Filtered roll")
paccx = plot(getindex.(estimated_mean, 4), ribbon = 3getindex.(estimated_var, 4, 4); title = "Filtered acc x")
paccy = plot(getindex.(estimated_mean, 5), ribbon = 3getindex.(estimated_var, 5, 5); title = "Filtered acc y")
paccz = plot(getindex.(estimated_mean, 6), ribbon = 3getindex.(estimated_var, 6, 6); title = "Filtered acc z")

p = plot(pyaw, ppitch, proll, paccx, paccy, paccz, size=(1920, 1080), layout=@layout([a b c; d e f]))

savefig(p, joinpath(@__DIR__, "3_gyro_stats.png"))
@info "Saved output in `3_gyro_stats.png`"

Rocket.unsubscribe!(info_subscription)
Rocket.unsubscribe!(posteriors_subscription)

@info "Sleeping for 5 seconds before disconnecting"
sleep(5)

PetoiBittle.disconnect(connection)

