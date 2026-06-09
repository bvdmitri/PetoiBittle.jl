<div align="center">
  <img src="docs/src/assets/logo.svg" alt="PetoiBittle.jl logo" width="200">
</div>

# PetoiBittle

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://bvdmitri.github.io/PetoiBittle.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bvdmitri.github.io/PetoiBittle.jl/dev/)
[![Build Status](https://github.com/bvdmitri/PetoiBittle.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/bvdmitri/PetoiBittle.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/bvdmitri/PetoiBittle.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/bvdmitri/PetoiBittle.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## About

This repository contains a Julia package to connect to and control Petoi Bittle robot dog.

## On the use of AI in this repository

The foundation of this package was designed and written by a human. That includes the
non-allocating serial command architecture (the `Command` interface, the preallocated
buffer, the transport seam that lets tests run without hardware), the package conventions
(`public` over `export`, Preferences.jl for configuration), and the strict test-driven
development workflow that every change follows: a failing test first, then the
implementation that makes it pass.

AI (Claude) was then used to scale that foundation out. The most mechanical part of
supporting "as many commands as possible" is translating Petoi's C++ OpenCat header (the
`CMD_NAME` token table in `types.hpp`) into Julia. AI did exactly that: it turned that table
into the data-driven list of built-in skills (`src/commands/generated/skills_table.jl`),
generated the matching command types, convenience verbs, and docstrings from it, ported the
remaining hand-written commands, and drafted the per-command documentation, all while
following the existing patterns and the same strict TDD loop.

Where the upstream protocol is undocumented (for example the exact wire format of some
sensor and pin reads), no command was fabricated. Instead the package exposes honest
low-level primitives (`RawCommand` / `RawQuery`) and marks anything provisional as such.
Every AI-assisted test and command is meant to be reviewed by a human (and the assertions
check exact on-the-wire bytes precisely so that review is easy).

## Examples 

The repository has a couple of examples implemented in the `examples/` folder. You can run the examples by name, e.g.

```bash
julia --project=examples -e 'using Pkg; Pkg.instantiate()'
julia --project=examples examples/0_scan_ports.jl
```

## License

This template is licensed under MIT (see the LICENSE file).
