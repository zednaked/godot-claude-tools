#!/usr/bin/env bash
# install.sh — Configura godot-claude-tools para Claude Code nesta máquina
# Repo: https://github.com/zedhssv/godot-claude-tools
# Uso: git clone https://github.com/zedhssv/godot-claude-tools && bash godot-claude-tools/install.sh

set -e

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.claude/tools/godot"
# Detecta o diretório de memória do projeto ativo do Claude Code
MEMORY_FILE="$(find "$HOME/.claude/projects" -name "MEMORY.md" 2>/dev/null | head -1)"
# Fallback: cria em local padrão se não encontrar
[[ -z "$MEMORY_FILE" ]] && MEMORY_FILE="$HOME/.claude/MEMORY.md"

log() { echo "[install.sh] $*"; }
run() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        eval "$@"
    fi
}

log "Godot Toolkit para Claude Code"
log "Origem : $SCRIPT_DIR"
log "Destino: $TARGET_DIR"
$DRY_RUN && log "*** MODO DRY-RUN — nenhuma alteração será feita ***"
echo ""

# 1. Criar diretório destino
log "1. Criando $TARGET_DIR ..."
run "mkdir -p '$TARGET_DIR'"

# 2. Criar symlinks para cada ferramenta
log "2. Criando symlinks ..."
TOOLS=(scene-map.py script-outline.py error-filter.sh boiler.sh project-context.sh install.sh)

for tool in "${TOOLS[@]}"; do
    src="$SCRIPT_DIR/$tool"
    dst="$TARGET_DIR/$tool"
    if [[ ! -f "$src" ]]; then
        echo "  AVISO: $src não encontrado, pulando."
        continue
    fi
    if $DRY_RUN; then
        echo "  [dry-run] ln -sf '$src' '$dst'"
    else
        ln -sf "$src" "$dst"
        echo "  Symlink: $dst -> $src"
    fi
done

# 3. Tornar scripts executáveis
log "3. Tornando scripts executáveis ..."
for f in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/*.py; do
    [[ -f "$f" ]] && run "chmod +x '$f'"
done

# 4. Verificar ollama + qwen2.5:3b
log "4. Verificando ollama + qwen2.5:3b ..."
if command -v ollama &>/dev/null; then
    if ollama list 2>/dev/null | grep -q 'qwen2.5:3b'; then
        echo "  OK: ollama e qwen2.5:3b disponíveis."
    else
        echo "  AVISO: ollama encontrado, mas qwen2.5:3b não baixado."
        echo "         Execute: ollama pull qwen2.5:3b"
    fi
else
    echo "  AVISO: ollama não encontrado."
    echo "         Para usar boiler.sh: yay -S ollama && ollama pull qwen2.5:3b"
fi

# 5. Atualizar MEMORY.md
log "5. Atualizando MEMORY.md ..."

MEMORY_BLOCK='
## Godot Workflow
Antes de ler qualquer arquivo Godot, SEMPRE usar:
- .tscn → python3 ~/.claude/tools/godot/scene-map.py <file>
- .gd/.cs → python3 ~/.claude/tools/godot/script-outline.py <file>
- log de erro → bash ~/.claude/tools/godot/error-filter.sh < log
- boilerplate → bash ~/.claude/tools/godot/boiler.sh --system X --lang gdscript
- projeto → bash ~/.claude/tools/godot/project-context.sh <dir>
'

if [[ -f "$MEMORY_FILE" ]]; then
    if grep -q 'Godot Workflow' "$MEMORY_FILE"; then
        echo "  MEMORY.md já contém bloco Godot, pulando."
    else
        if $DRY_RUN; then
            echo "  [dry-run] Adicionaria bloco Godot ao $MEMORY_FILE"
        else
            echo "$MEMORY_BLOCK" >> "$MEMORY_FILE"
            echo "  Bloco Godot adicionado ao $MEMORY_FILE"
        fi
    fi
else
    echo "  AVISO: $MEMORY_FILE não encontrado."
    echo "         Adicione manualmente ao seu MEMORY.md:"
    echo "$MEMORY_BLOCK"
fi

echo ""
log "Instalação concluída!"
echo ""
echo "Ferramentas disponíveis em: $TARGET_DIR"
echo ""
echo "Exemplos de uso:"
echo "  python3 ~/.claude/tools/godot/scene-map.py player.tscn"
echo "  python3 ~/.claude/tools/godot/script-outline.py PlayerController.gd"
echo "  bash ~/.claude/tools/godot/boiler.sh --system health --lang gdscript"
echo "  bash ~/.claude/tools/godot/project-context.sh ./meu-projeto/"
echo "  godot --headless 2>&1 | bash ~/.claude/tools/godot/error-filter.sh"
