# Changelog

All notable changes to PetoiBittle.jl are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- High-level convenience verbs for every built-in skill, for example `walk_forward(connection)`,
  `sit(connection)`, `greet(connection)`. Each is equivalent to sending the corresponding command.
- 27 built-in skills generated from a metadata table (`skills_overview`):
  - Gaits: `WalkForward`/`WalkLeft`/`WalkRight`, `TrotForward`/`TrotLeft`/`TrotRight`,
    `CrawlForward`/`CrawlLeft`/`CrawlRight`, `Backward`/`BackwardLeft`/`BackwardRight`,
    `Stepping`, `Bound`.
  - Postures: `Balance`, `Sit`, `Stretch`, `Sleep`, `Zero`, `ButtUp`, `CalibrationPose`.
  - Behaviors: `Greeting`, `CheckAround`, `PushUp`, `Pee`, `MimicDeath`, `BackFlip`.
- Control and state commands: `Pause`, `SwitchGyro`, `Calibrate`, `Recover`.
- Joint control: `MoveJointSequence` (move joints one after another) and `SetAllJoints`
  (set all 16 joints at once via the binary frame command).
- Sound: `PlayMelody` (built-in melody) and `PlayMusic` (a custom sequence of `Tone`s).
- Low-level primitives `RawCommand` and `RawQuery` (returning a `RawResponse`) for firmware
  commands that are not modelled by a dedicated typed command yet, including sensor and pin reads.
- `command_terminator` trait and `NO_TERMINATOR` sentinel so commands can choose their outgoing
  terminator (newline, `~`, or none); zero-allocation token and raw signed-byte serializers.

### Changed

- `send_command` now appends the per-command terminator instead of always using a newline,
  with a buffer-bounds guard. Existing commands are unaffected (they still default to newline).
- Documentation reorganized into per-category command pages (gaits, postures, behaviors, joint
  control, control and state, sound, low-level) plus an auto-generated command overview table.

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
