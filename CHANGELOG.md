# Changelog

All notable changes to PetoiBittle.jl are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-09

Initial release.

### Added

- Serial connection handling: `connect`, `disconnect`, and port discovery with
  `find_bittle_port` and `is_bittle_port`.
- `Command` interface with `send_command`, the `before_command` / `after_command`
  callbacks, and a response-type protocol (`command_return_type`, `validate_return_type`,
  `deserialize_from_bytes`).
- Commands: `MoveJoints`, `GyroStats`, `GyroCalibrate` (with automatic save), `Rest`, and `Skill`.
- Zero-allocation byte serializers and parsers for the serial protocol.
- Configurable constants via Preferences.jl: `buffer_capacity`, `baud_rate`, `max_retries`,
  and `default_timeout`.
- Public API marked with the `public` keyword (via Compat.jl for Julia 1.10 support).
- Documentation, doctests, and a test suite checked with Aqua.jl and JET.jl.

[1.0.0]: https://github.com/bvdmitri/PetoiBittle.jl/releases/tag/v1.0.0
