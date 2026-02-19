using PetoiBittle
using Logging

Logging.global_logger(ConsoleLogger(Logging.Debug))

@info PetoiBittle.find_bittle_port(verbose = true)
