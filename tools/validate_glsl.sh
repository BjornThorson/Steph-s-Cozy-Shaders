#!/usr/bin/env bash
# Offline GLSL compile and stage-link validation; does not emulate Oculus.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v glslangValidator >/dev/null || { echo "Install glslangValidator (glslang-tools)." >&2; exit 1; }
python3 tools/check_shader_pack.py
for file in shaders/*.vsh shaders/*.fsh; do
  case "$file" in *.vsh) stage=vert;; *.fsh) stage=frag;; esac
  glslangValidator -S "$stage" "$file"
  echo "PASS compile: $file"
done
tempdir=$(mktemp -d)
trap 'rm -rf "$tempdir"' EXIT
for pass in final gbuffers_water gbuffers_weather; do
  cp "shaders/$pass.vsh" "$tempdir/$pass.vert"
  cp "shaders/$pass.fsh" "$tempdir/$pass.frag"
  glslangValidator -l "$tempdir/$pass.vert" "$tempdir/$pass.frag" >/dev/null
  echo "PASS link: $pass"
done
echo "All offline GLSL compilation and linking tests passed."
