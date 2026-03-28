# CivDecks

[![Pages](https://img.shields.io/badge/GitHub%20Pages-live-32cd32)](https://conjius.github.io/CivDecks/)
[![Main CI/CD](https://github.com/conjius/CivDecks/actions/workflows/ci.yml/badge.svg)](https://github.com/conjius/CivDecks/actions/workflows/ci.yml)
[![Stable](https://img.shields.io/github/v/release/conjius/CivDecks?label=stable&v=2)](https://github.com/conjius/CivDecks/releases/latest)
[![Nightly](https://img.shields.io/github/v/release/conjius/CivDecks?include_prereleases&label=nightly&v=2)](https://github.com/conjius/CivDecks/releases)


## Description
<p align="center">
  <a href="https://conjius.github.io/CivDecks/#main"><img src="https://conjius.github.io/CivDecks/screenshot-main.jpg?v=3" width="48%" alt=""></a>
  &nbsp;
  <a href="https://conjius.github.io/CivDecks/#gallery"><img src="https://conjius.github.io/CivDecks/screenshot-gallery.jpg?v=3" width="48%" alt=""></a>
</p>

A hex-based civilization strategy game with deckbuilding mechanics, built in Godot 4.6.
Explore a procedurally generated world, play cards to move, scout, gather resources, and
settle - all driven by a single visible deck of action and resource cards.

## I Just Wanna Play

<p align="center">
  <img src="assets/boot_logo.png" width="120" alt="CivDecks">
  <br><br>
  <a href="https://conjius.github.io/CivDecks/play/">
    <img src="https://img.shields.io/badge/▶_Play_in_Browser-32cd32?style=for-the-badge" alt="Play in Browser">
  </a>
  &nbsp;&nbsp;
  <a href="https://github.com/conjius/CivDecks/releases/latest">
    <img src="https://img.shields.io/badge/⬇_Download_macOS-2d6ea3?style=for-the-badge" alt="Download macOS">
  </a>
</p>

## Build Prerequisites

- [**Godot 4.6.1**](https://godotengine.org/download)
- [**Python 3.12.0+**](https://www.python.org/downloads/) with **pip**
- **macOS** (primary development platform)
- **gdtoolkit** for linting - `pip install gdtoolkit`


## Build & Run
Run the project in Godot:
```bash
open -a Godot project.godot
```
Run the tests in a headless Godot instance:
```bash
godot --headless --script tests/test_runner.gd
```
Run the Linter via `gdlint`:
```bash
gdlint scripts/**/*.gd resources/**/*.gd
```

