using PetoiBittle
using Logging

Logging.global_logger(ConsoleLogger(Logging.Debug))

port = PetoiBittle.find_bittle_port()

@info "Using port $(port) to connect to PetoiBittle"

connection = PetoiBittle.connect(port)

@info "Sleeping for 5 seconds to let the Petoi Bittle initialize"
sleep(5)

task = PetoiBittle.MoveJoints(
    (id = 8, angle = 0),
    (id = 12, angle = 0),
    (id = 9, angle = 0),
    (id = 13, angle = 0),
    (id = 11, angle = 0),
    (id = 15, angle = 0),
    (id = 10, angle = 0),
    (id = 14, angle = 0)
)
PetoiBittle.send_command(connection, task)

@info "Sleeping before disconnecting for 5seconds..."
sleep(5)

PetoiBittle.disconnect(connection)
