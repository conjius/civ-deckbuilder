<br><p align="center">
  <a href="https://conjius.github.io/CivDecks/"><img src="https://conjius.github.io/CivDecks/logo.png?v=3" width="480" alt="CivDecks"></a>
  <p align="center">
  <a href="https://conjius.github.io/CivDecks/play/"><img src="https://img.shields.io/badge/Play_in_Browser-32cd32?style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0NCAyNCI+CjxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKDAgMCkgc2NhbGUoMC41KSIgZmlsbD0id2hpdGUiPgo8cGF0aCBmaWxsLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0yNCAyYTIyIDIyIDAgMTAwIDQ0IDIyIDIyIDAgMDAwLTQ0em0wIDE1LjVhOC41IDguNSAwIDEwMCAxNyA4LjUgOC41IDAgMDAwLTE3eiIvPgo8cGF0aCBkPSJNMjQgMkMxMyAyIDQgOSAyIDE5bDIwIDcuNWE4LjUgOC41IDAgMDExMC01LjNMNTYgMTJBMjIgMjIgMCAwMDI0IDJ6IiBvcGFjaXR5PSIwLjUiLz4KPHBhdGggZD0iTTI0IDQ2YTIyIDIyIDAgMDAyMC41LTE0TDMyIDI2LjVhOC41IDguNSAwIDAxLTEwIDUuM3oiIG9wYWNpdHk9IjAuNSIvPgo8L2c+CjxjaXJjbGUgY3g9IjMyIiBjeT0iMTIiIHI9IjE1IiBmaWxsPSJub25lIiBzdHJva2U9IiMzMmNkMzIiIHN0cm9rZS13aWR0aD0iNCIvPgo8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgyMCAwKSBzY2FsZSgwLjUpIiBmaWxsPSJ3aGl0ZSI+CjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgZD0iTTI0IDJhMjIgMjIgMCAxMDAgNDQgMjIgMjIgMCAwMDAtNDR6bTAgMTNhOSA5IDAgMTAwIDE4IDkgOSAwIDAwMC0xOHoiLz4KPGNpcmNsZSBjeD0iMjQiIGN5PSIyNCIgcj0iNCIvPgo8cGF0aCBkPSJNMjQgMTVhOSA5IDAgMDE3LjggNC41SDQzQTIyIDIyIDAgMDAyNCAydjEzeiIgb3BhY2l0eT0iMC44NSIvPgo8cGF0aCBkPSJNMTYuMiAxOS41QTkgOSAwIDAwMjQgMzN2MTFBMjIgMjIgMCAwMTUgMjRoMTQuNHoiIG9wYWNpdHk9IjAuODUiLz4KPHBhdGggZD0iTTMxLjggMjguNUE5IDkgMCAwMTI0IDMzdjEzYTIyIDIyIDAgMDAxOS0xMUgzMS44eiIgb3BhY2l0eT0iMC43Ii8+CjwvZz4KPC9zdmc+" alt="Play in Browser"></a>
  &nbsp;
  <a href="https://github.com/conjius/CivDecks/releases/latest"><img src="https://img.shields.io/badge/Download_for_macOS-2d6ea3?style=for-the-badge&logo=apple&logoColor=white" alt="Download for macOS"></a>
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
