#!/usr/bin/env python3
"""Generate HTML documentation from GDScript files."""

import os
import re
import sys
from pathlib import Path

SCRIPT_DIRS = ["scripts", "resources/cards"]
OUTPUT_DIR = "build/docs"

CLASS_RE = re.compile(r"^class_name\s+(\w+)")
EXTENDS_RE = re.compile(r"^extends\s+(.+)")
FUNC_RE = re.compile(r"^(static\s+)?func\s+(\w+)\(([^)]*)\)(\s*->\s*(.+))?\s*:")
SIGNAL_RE = re.compile(r"^signal\s+(\w+)(\(([^)]*)\))?")
VAR_RE = re.compile(r"^(static\s+)?(var|const)\s+(\w+)(\s*:\s*(\S+))?(\s*=\s*(.+))?")
EXPORT_RE = re.compile(r"^@export")
DOC_RE = re.compile(r"^##\s?(.*)")


def parse_file(path):
    """Parse a GDScript file and extract documentation."""
    with open(path) as f:
        lines = f.readlines()

    info = {
        "path": str(path),
        "class_name": None,
        "extends": None,
        "doc": [],
        "signals": [],
        "constants": [],
        "exports": [],
        "variables": [],
        "functions": [],
    }

    doc_buffer = []
    is_export = False

    for line in lines:
        stripped = line.strip()

        doc_match = DOC_RE.match(stripped)
        if doc_match:
            doc_buffer.append(doc_match.group(1))
            continue

        class_match = CLASS_RE.match(stripped)
        if class_match:
            info["class_name"] = class_match.group(1)
            info["doc"] = doc_buffer[:]
            doc_buffer.clear()
            continue

        extends_match = EXTENDS_RE.match(stripped)
        if extends_match:
            info["extends"] = extends_match.group(1).strip()
            doc_buffer.clear()
            continue

        if EXPORT_RE.match(stripped):
            is_export = True
            continue

        signal_match = SIGNAL_RE.match(stripped)
        if signal_match:
            info["signals"].append({
                "name": signal_match.group(1),
                "params": signal_match.group(3) or "",
                "doc": " ".join(doc_buffer),
            })
            doc_buffer.clear()
            continue

        var_match = VAR_RE.match(stripped)
        if var_match:
            is_static = bool(var_match.group(1))
            kind = var_match.group(2)
            name = var_match.group(3)
            type_hint = var_match.group(5) or ""
            default = var_match.group(7) or ""
            if name.startswith("_"):
                doc_buffer.clear()
                is_export = False
                continue
            entry = {
                "name": name,
                "type": type_hint,
                "default": default.strip(),
                "doc": " ".join(doc_buffer),
                "static": is_static,
            }
            if kind == "const":
                info["constants"].append(entry)
            elif is_export:
                info["exports"].append(entry)
            else:
                info["variables"].append(entry)
            doc_buffer.clear()
            is_export = False
            continue

        func_match = FUNC_RE.match(stripped)
        if func_match:
            name = func_match.group(2)
            if name.startswith("_"):
                doc_buffer.clear()
                continue
            info["functions"].append({
                "name": name,
                "params": func_match.group(3).strip(),
                "return_type": (func_match.group(5) or "").strip(),
                "static": bool(func_match.group(1)),
                "doc": " ".join(doc_buffer),
            })
            doc_buffer.clear()
            continue

        if stripped and not stripped.startswith("#"):
            doc_buffer.clear()
            is_export = False

    return info


def render_html(files_info):
    """Render all parsed files as a single HTML page."""
    nav_items = []
    content_sections = []

    for info in sorted(files_info, key=lambda x: x["class_name"] or Path(x["path"]).stem):
        name = info["class_name"] or Path(info["path"]).stem
        anchor = name.lower()
        nav_items.append(f'<li><a href="#{anchor}">{name}</a></li>')

        section = f'<section id="{anchor}">\n'
        section += f'<h2>{name}</h2>\n'
        if info["extends"]:
            section += f'<p class="extends">extends <code>{info["extends"]}</code></p>\n'
        section += f'<p class="file-path">{info["path"]}</p>\n'
        if info["doc"]:
            section += f'<p class="doc">{" ".join(info["doc"])}</p>\n'

        if info["signals"]:
            section += '<h3>Signals</h3>\n<table>\n'
            section += '<tr><th>Signal</th><th>Description</th></tr>\n'
            for sig in info["signals"]:
                params = f'({sig["params"]})' if sig["params"] else "()"
                section += f'<tr><td><code>{sig["name"]}{params}</code></td>'
                section += f'<td>{sig["doc"]}</td></tr>\n'
            section += '</table>\n'

        if info["constants"]:
            section += '<h3>Constants</h3>\n<table>\n'
            section += '<tr><th>Name</th><th>Type</th><th>Value</th><th>Description</th></tr>\n'
            for c in info["constants"]:
                section += f'<tr><td><code>{c["name"]}</code></td>'
                section += f'<td><code>{c["type"]}</code></td>'
                section += f'<td><code>{c["default"]}</code></td>'
                section += f'<td>{c["doc"]}</td></tr>\n'
            section += '</table>\n'

        if info["exports"]:
            section += '<h3>Exports</h3>\n<table>\n'
            section += '<tr><th>Property</th><th>Type</th><th>Default</th><th>Description</th></tr>\n'
            for e in info["exports"]:
                section += f'<tr><td><code>{e["name"]}</code></td>'
                section += f'<td><code>{e["type"]}</code></td>'
                section += f'<td><code>{e["default"]}</code></td>'
                section += f'<td>{e["doc"]}</td></tr>\n'
            section += '</table>\n'

        if info["functions"]:
            section += '<h3>Methods</h3>\n<table>\n'
            section += '<tr><th>Method</th><th>Returns</th><th>Description</th></tr>\n'
            for fn in info["functions"]:
                static = '<span class="tag">static</span> ' if fn["static"] else ""
                ret = fn["return_type"] or "void"
                section += f'<tr><td>{static}<code>{fn["name"]}({fn["params"]})</code></td>'
                section += f'<td><code>{ret}</code></td>'
                section += f'<td>{fn["doc"]}</td></tr>\n'
            section += '</table>\n'

        section += '</section>\n<hr>\n'
        content_sections.append(section)

    nav_html = "\n".join(nav_items)
    content_html = "\n".join(content_sections)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CivDecks — API Reference</title>
<style>
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{ font-family: system-ui, sans-serif; display: flex; background: #1a1a2e; color: #e0e0e0; }}
nav {{ width: 260px; position: fixed; top: 0; left: 0; height: 100vh; overflow-y: auto;
       background: #16213e; padding: 20px; border-right: 1px solid #333; }}
nav h1 {{ font-size: 18px; margin-bottom: 16px; color: #e8c055; }}
nav ul {{ list-style: none; }}
nav li {{ margin: 4px 0; }}
nav a {{ color: #8ab4f8; text-decoration: none; font-size: 14px; }}
nav a:hover {{ color: #fff; }}
main {{ margin-left: 260px; padding: 32px 40px; max-width: 900px; }}
h2 {{ color: #e8c055; margin: 24px 0 8px; font-size: 22px; }}
h3 {{ color: #ccc; margin: 16px 0 8px; font-size: 16px; }}
.extends {{ color: #888; font-size: 14px; margin-bottom: 4px; }}
.file-path {{ color: #666; font-size: 12px; margin-bottom: 8px; }}
.doc {{ color: #aaa; margin-bottom: 12px; }}
table {{ width: 100%; border-collapse: collapse; margin-bottom: 16px; font-size: 14px; }}
th {{ text-align: left; padding: 6px 10px; background: #1f2f4f; color: #e8c055; }}
td {{ padding: 6px 10px; border-top: 1px solid #2a2a4a; }}
code {{ background: #2a2a4a; padding: 1px 5px; border-radius: 3px; font-size: 13px; }}
hr {{ border: none; border-top: 1px solid #333; margin: 24px 0; }}
.tag {{ background: #3a5a3a; color: #8f8; padding: 1px 6px; border-radius: 3px; font-size: 11px; }}
@media (max-width: 768px) {{
  nav {{ display: none; }}
  main {{ margin-left: 0; padding: 16px; }}
}}
</style>
</head>
<body>
<nav>
<h1>CivDecks API</h1>
<ul>
{nav_html}
</ul>
</nav>
<main>
<h1 style="color:#e8c055;margin-bottom:8px;">CivDecks — API Reference</h1>
<p style="color:#888;margin-bottom:32px;">Auto-generated from GDScript source</p>
{content_html}
</main>
</body>
</html>"""


def main():
    project_root = Path(__file__).parent.parent.parent
    os.chdir(project_root)

    all_files = []
    for d in SCRIPT_DIRS:
        for path in Path(d).rglob("*.gd"):
            if "test_" in path.name:
                continue
            info = parse_file(path)
            if info["functions"] or info["signals"] or info["exports"] or info["constants"]:
                all_files.append(info)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    html = render_html(all_files)
    out_path = os.path.join(OUTPUT_DIR, "index.html")
    with open(out_path, "w") as f:
        f.write(html)
    print(f"Generated docs: {out_path} ({len(all_files)} classes)")


if __name__ == "__main__":
    main()
