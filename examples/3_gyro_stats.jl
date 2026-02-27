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
PetoiBittle.send_command(connection, PetoiBittle.Rest())
sleep(2)

@info "Calibrating gyro"
PetoiBittle.send_command(connection, PetoiBittle.GyroCalibrate())
sleep(20)

@info "Starting collecting measurements"
measurements = []

time_to_collect = 10 # in seconds
sleep_between = 0.05 # in seconds
n_measurements = time_to_collect / sleep_between

for i in 1:n_measurements
    command = PetoiBittle.GyroStats()
    measurement = PetoiBittle.send_command(connection, command)
    @info measurement
    push!(measurements, measurement)
    sleep(sleep_between)
end

yaw = map(m -> m.yaw, measurements)
pitch = map(m -> m.pitch, measurements)
roll = map(m -> m.roll, measurements)
accx = map(m -> m.acceleration_x, measurements)
accy = map(m -> m.acceleration_y, measurements)
accz = map(m -> m.acceleration_z, measurements)

pyaw = scatter(yaw; title = "Yaw", color = :red)
ppitch = scatter(pitch; title = "Pitch", color = :blue)
proll = scatter(roll; title = "Roll", color = :green)
paccx = scatter(accx; title = "Acceleration x", color = :red)
paccy = scatter(accy; title = "Acceleration y", color = :blue)
paccz = scatter(accz; title = "Acceleration z", color = :green)

p = plot(pyaw, ppitch, proll, paccx, paccy, paccz, size=(1920, 1080), layout = @layout([a b c; d e f]))

savefig(p, joinpath(@__DIR__, "3_gyro_stats.png"))
@info "Saved output in `3_gyro_stats.png`"

@info "Sleeping for 5 seconds before disconnecting"
sleep(5)

PetoiBittle.disconnect(connection)
