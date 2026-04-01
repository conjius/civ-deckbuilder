# Project: Civ x Slay the Spire

## Workflow Rules

- **Never commit or push without explicit user approval.** Stage changes, report what's ready, and wait for the go-ahead.
- **Always stage all changes before reporting a task as done.** Use `git add` on every changed file so the user can review a complete diff.
- **Always TDD.** Write failing tests first, then implement until they pass. This applies to new features, bug fixes, and refactors alike.
- **Run all tests, build, and lint before reporting a task as done.** Use `gdlint scripts/**/*.gd resources/**/*.gd` for linting. Do not report back until everything passes.
- **Comments must be non-trivial.** Only add comments where the logic is genuinely non-obvious. Remove noisy/redundant comments from both test and production code.
- **Use OOP principles in design.** Prefer inheritance, polymorphism, modularity, and delegation. Keep classes focused and responsibilities clear.
- **Refactors are welcome when TDD'd.** Refactor when something needs an overhaul to become simpler. Always have tests covering the behavior before and after.
- **Never add your own identity to git commits.** Do not include "Co-Authored-By: Claude" or any Claude/AI attribution in commit messages, code, or anywhere in the repo. Always use only the user's git identity.
- **Never add "Generated with Claude Code" or similar attribution.** Do not add AI attribution lines to PR descriptions, commit messages, code comments, or anywhere else. All output should appear as if written solely by the user.
- **Never add a test plan to PR descriptions.** Keep PR descriptions concise — summary only, no test plan section.
- **Always read a file before editing it.** Use the Read tool on the exact lines you plan to change. Never attempt an edit based on memory or assumptions from a prior read — the file may have changed.

## Development Notes

- Always kill the Godot process after debug testing. Use `kill $GODOT_PID` after every test run. Only kill Godot instances you started — never blindly `pkill`/`pgrep` Godot, as the user may have the editor open.
- Godot 4.6 has strict type inference — never use `:=` when the return type is Variant. Use explicit type annotations.
- Hand-written .tscn files can have serialization issues with typed arrays. Prefer setting data in code.
- Set `mouse_filter = 2` (IGNORE) on UI containers that should pass clicks through to the 3D world.

## Godot & GDScript Gotchas

- **SurfaceTool winding order matters**: Top-face triangles must use CCW winding (center → c0 → c1) for normals to face up. Getting this backwards makes faces invisible or lit incorrectly.
- **ImmediateMesh for dynamic geometry**: Use `ImmediateMesh` (not `SurfaceTool`) for meshes that change every frame (e.g., the arrow indicator). Call `clear_surfaces()` before rebuilding. Pair with `surface_set_color()` per-vertex for vertex colors.
- **Dictionary get() returns Variant**: `Dictionary.get()` returns `Variant`, so always cast explicitly with `as` (e.g., `tiles.get(coord, null) as Node3D`). Using `:=` here will trigger Godot 4.6 strict type errors.
- **Typed Array literals in function args**: To pass a typed array literal inline, cast it: `[coord] as Array[Vector2i]`. Without the cast, Godot treats it as `Array` and type-checking fails at the call site.
- **Hex top-face vertex order for SurfaceTool**: When building hex prisms, emit the center vertex first (center, c0, c1), not corner-first. Corner-first (c0, center, c1) produces CW winding = wrong normals.
- **ConvexPolygonShape3D from PackedVector3Array**: Build a `PackedVector3Array` of the hull points, then assign to `shape.points`. Don't use `Array[Vector3]` — the `points` property requires `PackedVector3Array`.
- **Raycast tile identification**: `intersect_ray()` returns the `StaticBody3D` collider, not the tile root node. Use `collider.get_parent()` to get back to the HexTile node.
- **@warning_ignore for integer division**: Godot 4.6 warns on implicit integer division. Use `@warning_ignore("integer_division")` above the line (e.g., offset-row to axial conversion `r - q / 2`).
- **Preloading Resources in main.gd**: Card `.tres` resources are preloaded as script-level `var` (not `const`) because `const` preloads can cause cyclic reference issues with custom Resource scripts. The starter deck array is built in `_ready()`, not in the export, to avoid .tscn typed-array serialization bugs.
- **InputEventPanGesture for trackpad zoom**: Mouse wheel events (`MOUSE_BUTTON_WHEEL_UP/DOWN`) don't fire for macOS trackpad pinch/scroll. Handle `InputEventPanGesture` separately and use `event.delta.y` for zoom amount.
- **Fog/highlight overlay meshes**: Overlay MeshInstance3D nodes (HighlightMesh, FogOverlay) are scaled slightly larger (1.02–1.05x) and offset in Y (0.06–0.08) above the tile to prevent z-fighting. Their meshes are assigned in code from the same cache, not in the .tscn.
- **Signal wiring order**: Wire all signals in `_ready()` before calling `start_game()` / `generate_map()`. If `start_game()` fires `turn_started` before the UI signal is connected, the UI misses the first turn update.
- **Card drag uses `_input()` not `_gui_input()`**: `_gui_input()` only fires while the mouse is over the Control. Once dragging moves the card away from under the cursor, `_gui_input()` stops. Use `_input()` to keep tracking mouse motion globally during drag.
- **Unique names (`%Node`) require `unique_name_in_owner = true`**: In .tscn files, the `%NodeName` shorthand only works if the node has `unique_name_in_owner = true` set. Missing this causes null references at runtime with no clear error.
