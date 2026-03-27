# civ-deckbuilder

[![Pages](https://img.shields.io/badge/GitHub%20Pages-live-32cd32)](https://conjius.github.io/civ-deckbuilder/)
[![CI/CD](https://github.com/conjius/civ-deckbuilder/actions/workflows/ci.yml/badge.svg)](https://github.com/conjius/civ-deckbuilder/actions/workflows/ci.yml)
[![Stable](https://img.shields.io/github/v/release/conjius/civ-deckbuilder?label=stable)](https://github.com/conjius/civ-deckbuilder/releases/latest)
[![Nightly](https://img.shields.io/github/v/release/conjius/civ-deckbuilder?include_prereleases&label=nightly)](https://github.com/conjius/civ-deckbuilder/releases)


## Description
<p align="center">
  <a href="https://conjius.github.io/civ-deckbuilder/#main"><img src="https://conjius.github.io/civ-deckbuilder/screenshot-main.png?v=1774621545" width="48%" alt=""></a>
  &nbsp;
  <a href="https://conjius.github.io/civ-deckbuilder/#gallery"><img src="https://conjius.github.io/civ-deckbuilder/screenshot-gallery.png?v=1774621545" width="48%" alt=""></a>
</p>

A hex-based civilization strategy game with deckbuilding mechanics, built in Godot 4.6.
Explore a procedurally generated world, play cards to move, scout, gather resources, and
settle - all driven by a single visible deck of action and resource cards.

## Playing

Download the [latest stable build](https://github.com/conjius/civ-deckbuilder/releases/latest), unzip it, and run on macOS.

## Build Prerequisites

- [**Godot 4.6.1**](https://godotengine.org/download)
- [**Python 3.12.0+**](https://www.python.org/downloads/) with **pip**
- **macOS** (primary development platform)
- **gdtoolkit** for linting - `pip install gdtoolkit`


## Build & Run

```bash
open -a Godot project.godot
```

```bash
godot --headless --script tests/test_runner.gd
```

```bash
gdlint scripts/**/*.gd resources/**/*.gd
```

