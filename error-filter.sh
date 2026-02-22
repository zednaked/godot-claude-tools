#!/usr/bin/env bash
# error-filter.sh — Filtra log do Godot, mantém só o que importa
# Uso: bash error-filter.sh < godot.log
#  ou: godot --headless 2>&1 | bash error-filter.sh

grep -E \
  'ERROR|SCRIPT ERROR|At:|Stack Trace|GDScriptAnalyzer|GDScriptParser|FATAL|assert|Assertion|Exception|at function|at line|parse error|Compile Error|Error loading|ERROR: Failed|Cannot|Invalid|Unhandled' \
  | grep -vE \
  'Vulkan|RADV|AMD|Mesa|glsl|SPIR-V|shader|audio|AudioServer|Mixer|stream|OGG|WAV|MP3|renderer|RenderingServer|DisplayServer|OS: |CPU: |Video Adapter|Video Memory|VRAM|Initialize|OpenGL|GL_|EGL|ANGLE|Mono:|GodotSharp.*assemblies|dotnet|nuget'
