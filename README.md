# civ-deckbuilder

[![CI](https://github.com/conjius/civ-deckbuilder/actions/workflows/ci.yml/badge.svg)](https://github.com/conjius/civ-deckbuilder/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/conjius/civ-deckbuilder)](https://github.com/conjius/civ-deckbuilder/releases/latest)

A hex-based civilization strategy game with deckbuilding mechanics, built in Godot 4.6.
Explore a procedurally generated world, play cards to move, scout, gather resources, and
settle -all driven by a single visible deck of action and resource cards.

## Prerequisites

- **Godot 4.6.1** -[download](https://godotengine.org/download)
- **macOS** (primary development platform)
- **gdtoolkit** for linting -`pip install gdtoolkit`

## Build & Run

```bash
# Open in Godot editor
open -a Godot project.godot

# Or run headless tests
godot --headless --script tests/test_runner.gd

# Lint
gdlint scripts/**/*.gd resources/**/*.gd
```

Press **F5** in the Godot editor to run the game.

## Project Structure

```
scripts/
  logic/        # Core game logic (deck, cards, turns, player state)
  cards/        # Card effects and management
  map/          # Hex map, terrain, fog, trees, mountains
  ui/           # Card hand, gallery, unit info, end turn button
  unit/         # Player and AI units
  camera/       # Strategy camera with pan/zoom/tilt/orbit
  ai/           # AI controller
resources/
  cards/        # Card data (.tres) and schema
  terrain/      # Terrain type definitions
assets/
  models/       # 3D models (boots, mountain, trees, water)
  shaders/      # Fog cloud and screen blur shaders
  icons/        # SVG icons for cards, entities, resources
tests/          # GDScript unit tests
```

## License

All rights reserved.
