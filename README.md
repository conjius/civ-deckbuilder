<br><p align="center">
  <a href="https://conjius.github.io/CivDecks/"><img src="https://conjius.github.io/CivDecks/logo.png?v=3" width="480" alt="CivDecks"></a>
  <p align="center">
  <a href="https://conjius.github.io/CivDecks/play/"><img src="https://img.shields.io/badge/Play_in_Browser-32cd32?logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0NCAyNCI+CjwhLS0gRmlyZWZveCAoYmVoaW5kLCByaWdodCkgLS0+CjxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKDE4IDApIHNjYWxlKDAuNSkiIGZpbGw9IndoaXRlIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBkPSJNMjQgMmEyMiAyMiAwIDEwMCA0NCAyMiAyMiAwIDAwMC00NHptMCAxNS41YTguNSA4LjUgMCAxMDAgMTcgOC41IDguNSAwIDAwMC0xN3oiLz4KPHBhdGggZD0iTTI0IDJDMTMgMiA0IDkgMiAxOWwyMCA3LjVhOC41IDguNSAwIDAxMTAtNS4zTDU2IDEyQTIyIDIyIDAgMDAyNCAyeiIgb3BhY2l0eT0iMC41Ii8+CjxwYXRoIGQ9Ik0yNCA0NmEyMiAyMiAwIDAwMjAuNS0xNEwzMiAyNi41YTguNSA4LjUgMCAwMS0xMCA1LjN6IiBvcGFjaXR5PSIwLjUiLz4KPC9nPgo8IS0tIEVyYXNlciByaW5nIChvdXRlciBvbmx5LCB0aGljaykgLS0+CjxjaXJjbGUgY3g9IjEyIiBjeT0iMTIiIHI9IjE2IiBmaWxsPSJub25lIiBzdHJva2U9IiMzMmNkMzIiIHN0cm9rZS13aWR0aD0iNSIvPgo8IS0tIENocm9tZSAoZnJvbnQsIGxlZnQpIHdpdGggY3V0b3V0IHJpbmcgLS0+CjxnIHRyYW5zZm9ybT0ic2NhbGUoMC41KSIgZmlsbD0id2hpdGUiPgo8cGF0aCBmaWxsLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0yNCAyYTIyIDIyIDAgMTAwIDQ0IDIyIDIyIDAgMDAwLTQ0em0wIDEzYTkgOSAwIDEwMCAxOCA5IDkgMCAwMDAtMTh6Ii8+CjxjaXJjbGUgY3g9IjI0IiBjeT0iMjQiIHI9IjQiLz4KPHBhdGggZD0iTTI0IDE1YTkgOSAwIDAxNy44IDQuNUg0M0EyMiAyMiAwIDAwMjQgMnYxM3oiIG9wYWNpdHk9IjAuODUiLz4KPHBhdGggZD0iTTE2LjIgMTkuNUE5IDkgMCAwMDI0IDMzdjExQTIyIDIyIDAgMDE1IDI0aDE0LjR6IiBvcGFjaXR5PSIwLjg1Ii8+CjxwYXRoIGQ9Ik0zMS44IDI4LjVBOSA5IDAgMDEyNCAzM3YxM2EyMiAyMiAwIDAwMTktMTFIMzEuOHoiIG9wYWNpdHk9IjAuNyIvPgo8L2c+Cjwvc3ZnPg==&logoWidth=60" alt="Play in Browser"></a>
  &nbsp;
  <a href="https://github.com/conjius/CivDecks/releases/latest"><img src="https://img.shields.io/badge/Download_for_macOS-2d6ea3?logo=apple&logoColor=white&logoWidth=28" alt=" Download for macOS"></a>
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
