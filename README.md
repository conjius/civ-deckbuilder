<br><p align="center">
  <a href="https://conjius.github.io/CivDecks/"><img src="https://conjius.github.io/CivDecks/logo.png?v=3" width="480" alt="CivDecks"></a>
  <p align="center">
  <a href="https://conjius.github.io/CivDecks/play/"><img src="https://img.shields.io/badge/Play_in_Browser-32cd32?logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0NCAyNCI+CjxnIHRyYW5zZm9ybT0ic2NhbGUoMC41KSI+CjwhLS0gQ2hyb21lIC0tPgo8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwIDApIj4KPHBhdGggZmlsbD0id2hpdGUiIGZpbGwtcnVsZT0iZXZlbm9kZCIgZD0iTTI0IDJhMjIgMjIgMCAxMDAgNDQgMjIgMjIgMCAwMDAtNDR6bTAgMTNhOSA5IDAgMTAwIDE4IDkgOSAwIDAwMC0xOHoiLz4KPGNpcmNsZSBjeD0iMjQiIGN5PSIyNCIgcj0iNC41IiBmaWxsPSJ3aGl0ZSIvPgo8L2c+CjwhLS0gRmlyZWZveCAtLT4KPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMzYgMCkiPgo8cGF0aCBmaWxsPSJ3aGl0ZSIgZmlsbC1ydWxlPSJldmVub2RkIiBkPSJNMjQgMmEyMiAyMiAwIDEwMCA0NCAyMiAyMiAwIDAwMC00NHptMCAxMy41YTguNSA4LjUgMCAxMDAgMTcgOC41IDguNSAwIDAwMC0xN3oiLz4KPHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0yNCAyQzEzIDIgNCA5IDIgMTlsMjAgNy41YTguNSA4LjUgMCAwMDUtMS41bDI3LTEzQTIyIDIyIDAgMDAyNCAyeiIgb3BhY2l0eT0iMC42Ii8+CjwvZz4KPC9nPgo8L3N2Zz4=&logoWidth=30" alt="Play in Browser"></a>
  &nbsp;
  <a href="https://github.com/conjius/CivDecks/releases/latest"><img src="https://img.shields.io/badge/_Download_for_macOS-2d6ea3" alt=" Download for macOS"></a>
</p>
</p>
A hex-based civilization strategy game with deckbuilding mechanics, built in Godot 4.6.
Explore a procedurally generated world, play cards to move, scout, gather resources, and
settle - all driven by a single visible deck of action and resource cards.
<br>
<br>
<p align="center">
  <a href="https://conjius.github.io/CivDecks/#main"><img src="https://conjius.github.io/CivDecks/screenshot-main.jpg?v=3" width="48%" alt=""></a>
  &nbsp;
  <a href="https://conjius.github.io/CivDecks/#gallery"><img src="https://conjius.github.io/CivDecks/screenshot-gallery.jpg?v=3" width="48%" alt=""></a>
</p>
<p align="center">
  <a href="https://conjius.github.io/CivDecks/"><img src="https://img.shields.io/badge/GitHub%20Pages-live-32cd32" alt="Pages"></a>
  <a href="https://github.com/conjius/CivDecks/actions/workflows/ci.yml"><img src="https://github.com/conjius/CivDecks/actions/workflows/ci.yml/badge.svg" alt="CI/CD"></a>
  <a href="https://github.com/conjius/CivDecks/releases/latest"><img src="https://img.shields.io/github/v/release/conjius/CivDecks?label=stable&v=3" alt="Stable"></a>
  <a href="https://github.com/conjius/CivDecks/releases"><img src="https://img.shields.io/github/v/release/conjius/CivDecks?include_prereleases&label=nightly&v=3" alt="Nightly"></a>
</p>

## Build Prerequisites (macOS-only)

- [**Godot 4.6.1**](https://godotengine.org/download)
- [**Python 3.12+**](https://www.python.org/downloads/release/python-31210/) with **pip**
- **macOS** (primary development platform)
- **gdtoolkit** for linting - `pip install gdtoolkit`


## Build & Run (macOS-only)
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
