using PetoiBittle
using Logging

Logging.global_logger(ConsoleLogger(Logging.Debug))

port = PetoiBittle.find_bittle_port()

@info "Using port $(port) to connect to PetoiBittle"

connection = PetoiBittle.connect(port)

@info "Sleeping for 5 seconds to let the Petoi Bittle initialize"
sleep(5)

# The high-level convenience verbs read like plain English. Each is exactly equivalent to
# `PetoiBittle.send_command(connection, <Command>())`, but much friendlier to start with.

@info "Stretch, then sit"
PetoiBittle.stretch(connection)
sleep(3)
PetoiBittle.sit(connection)
sleep(3)

@info "Walk forward for a few seconds, then trot left"
PetoiBittle.walk_forward(connection)
sleep(4)
PetoiBittle.trot_left(connection)
sleep(4)

@info "Say hello, then stop and balance"
PetoiBittle.greet(connection)
sleep(3)
PetoiBittle.balance(connection)
sleep(2)

@info "Fold down into the sleep posture"
PetoiBittle.nap(connection)
sleep(3)

PetoiBittle.disconnect(connection)
