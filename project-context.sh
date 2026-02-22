#!/usr/bin/env bash
# project-context.sh — Resume projeto Godot inteiro para Claude Code
# Uso: bash project-context.sh <diretório-do-projeto>

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Diretório não encontrado: $PROJECT_DIR" >&2
    exit 1
fi

SCENE_MAP="$(dirname "$0")/scene-map.py"
SCRIPT_OUTLINE="$(dirname "$0")/script-outline.py"

if [[ ! -f "$SCENE_MAP" ]]; then
    SCENE_MAP="$HOME/.claude/tools/godot/scene-map.py"
fi
if [[ ! -f "$SCRIPT_OUTLINE" ]]; then
    SCRIPT_OUTLINE="$HOME/.claude/tools/godot/script-outline.py"
fi

PROJECT_GODOT=$(find "$PROJECT_DIR" -maxdepth 2 -name "project.godot" | head -1)

echo "# Projeto Godot: $(realpath "$PROJECT_DIR")"
echo "# Gerado em: $(date '+%Y-%m-%d %H:%M')"
echo ""

# --- project.godot resumo ---
if [[ -f "$PROJECT_GODOT" ]]; then
    echo "## project.godot"
    grep -E '(application/|config/name|config/version|features|main_scene)' "$PROJECT_GODOT" | head -20
    echo ""
fi

# --- Cenas ---
TSCN_FILES=$(find "$PROJECT_DIR" -name "*.tscn" | sort)
TSCN_COUNT=$(echo "$TSCN_FILES" | grep -c '.')

echo "## Cenas ($TSCN_COUNT arquivos .tscn)"
echo ""

for f in $TSCN_FILES; do
    echo "---"
    python3 "$SCENE_MAP" "$f" 2>/dev/null || echo "ERRO ao processar: $f"
    echo ""
done

# --- Scripts GDScript ---
GD_FILES=$(find "$PROJECT_DIR" -name "*.gd" | sort)
GD_COUNT=$(echo "$GD_FILES" | grep -c '.')

echo "## Scripts GDScript ($GD_COUNT arquivos .gd)"
echo ""

for f in $GD_FILES; do
    echo "---"
    python3 "$SCRIPT_OUTLINE" "$f" 2>/dev/null || echo "ERRO ao processar: $f"
    echo ""
done

# --- Scripts C# ---
CS_FILES=$(find "$PROJECT_DIR" -name "*.cs" | grep -v '\.generated\.' | grep -v 'AssemblyInfo' | sort)
CS_COUNT=$(echo "$CS_FILES" | grep -c '.')

if [[ $CS_COUNT -gt 0 ]]; then
    echo "## Scripts C# ($CS_COUNT arquivos .cs)"
    echo ""

    for f in $CS_FILES; do
        echo "---"
        python3 "$SCRIPT_OUTLINE" "$f" 2>/dev/null || echo "ERRO ao processar: $f"
        echo ""
    done
fi

echo "# Fim do contexto do projeto"
