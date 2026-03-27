# civ-deckbuilder

[![Pages](https://img.shields.io/badge/GitHub%20Pages-live-32cd32)](https://conjius.github.io/civ-deckbuilder/)
[![CI](https://github.com/conjius/civ-deckbuilder/actions/workflows/ci.yml/badge.svg)](https://github.com/conjius/civ-deckbuilder/actions/workflows/ci.yml)
[![Stable](https://img.shields.io/github/v/release/conjius/civ-deckbuilder?label=stable)](https://github.com/conjius/civ-deckbuilder/releases/latest)
[![Nightly](https://img.shields.io/github/v/release/conjius/civ-deckbuilder?include_prereleases&label=nightly)](https://github.com/conjius/civ-deckbuilder/releases)

Stack: [![macOS](https://img.shields.io/badge/-macOS-999?logo=apple&logoColor=white&style=flat-square)](https://github.com/conjius/civ-deckbuilder/releases/latest)&nbsp;&nbsp;[![Godot 4.6](https://img.shields.io/badge/-Godot%204.6-478CBF?logo=godotengine&logoColor=white&style=flat-square)](https://godotengine.org/article/godot-4-6-release/)&nbsp;&nbsp;[![Python 3.12.0](https://img.shields.io/badge/-Python%203.12.0-3776AB?logo=python&logoColor=white&style=flat-square)](https://www.python.org/downloads/)&nbsp;&nbsp;[![GitHub Actions](https://img.shields.io/badge/-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white&style=flat-square)](https://github.com/conjius/civ-deckbuilder/actions)

<p align="center">
  <a href="https://conjius.github.io/civ-deckbuilder/screenshot-main.png"><img src="https://conjius.github.io/civ-deckbuilder/screenshot-main.png" width="48%" alt=""></a>
  &nbsp;
  <a href="https://conjius.github.io/civ-deckbuilder/screenshot-gallery.png"><img src="https://conjius.github.io/civ-deckbuilder/screenshot-gallery.png" width="48%" alt=""></a>
</p>

A hex-based civilization strategy game with deckbuilding mechanics, built in Godot 4.6.
Explore a procedurally generated world, play cards to move, scout, gather resources, and
settle - all driven by a single visible deck of action and resource cards.

## Prerequisites

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

Press **F5** in the Godot editor to run the game.
