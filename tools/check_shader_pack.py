#!/usr/bin/env python3
"""Static preflight for the Forge 1.20.1 / Oculus shader-pack layout."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
shaders = root / "shaders"
required = ["final.vsh", "final.fsh", "gbuffers_water.vsh",
            "gbuffers_water.fsh", "gbuffers_weather.vsh",
            "gbuffers_weather.fsh", "block.properties", "shaders.properties"]
errors = []
for name in required:
    if not (shaders / name).is_file():
        errors.append(f"Missing shaders/{name}")
for name in required:
    if not name.endswith((".vsh", ".fsh")) or not (shaders / name).exists():
        continue
    source = (shaders / name).read_text()
    if not source.startswith("#version 330 compatibility\n"):
        errors.append(f"{name}: expected GLSL 330 compatibility profile")
    if source.count("{") != source.count("}"):
        errors.append(f"{name}: unbalanced braces")
    if not re.search(r"\bvoid\s+main\s*\(", source):
        errors.append(f"{name}: no main()")
if (shaders / "gbuffers_water.vsh").exists():
    source = (shaders / "gbuffers_water.vsh").read_text()
    if not re.search(r"\bin\s+vec2\s+mc_Entity\s*;", source):
        errors.append("gbuffers_water.vsh: mc_Entity must be vec2")
if (shaders / "block.properties").exists():
    source = (shaders / "block.properties").read_text()
    for entry in ("block.1001 = minecraft:water", "block.1002 = minecraft:lava"):
        if entry not in source:
            errors.append(f"block.properties: missing {entry}")
if errors:
    print("Preflight FAILED:")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("Preflight PASSED: expected files, shader headers, entrypoints, fluid mapping and mc_Entity attribute.")
print("Note: this is NOT a GLSL compiler or an in-game Oculus compatibility test.")
