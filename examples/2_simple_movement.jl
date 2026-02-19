using PetoiBittle
using Logging

Logging.global_logger(ConsoleLogger(Logging.Debug))

port = PetoiBittle.find_bittle_port()

@info "Using port $(port) to connect to PetoiBittle"

connection = PetoiBittle.connect(port)

@info "Sleeping for 5 seconds to let the Petoi Bittle initialize"
sleep(5)

for angle in 0:-2:-70
    task = PetoiBittle.MoveJoints(
        (id = 8, angle = angle),
        (id = 12, angle = -2angle),
        (id = 9, angle = angle),
        (id = 13, angle = -2angle),
        (id = 11, angle = 0),
        (id = 15, angle = 0),
        (id = 10, angle = 0),
        (id = 14, angle = 0)
    )
    PetoiBittle.send_task(connection, task)
    sleep(0.2)
end

@info "Sleeping for 5 seconds before disconnecting"
sleep(5)

PetoiBittle.disconnect(connection)
