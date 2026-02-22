#!/usr/bin/env bash
# boiler.sh — Gera boilerplate Godot via qwen2.5:3b (ollama)
# Uso: bash boiler.sh --system health --lang gdscript
#      bash boiler.sh --system inventory --lang csharp

SYSTEM=""
LANG="gdscript"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --system) SYSTEM="$2"; shift 2 ;;
        --lang)   LANG="$2";   shift 2 ;;
        *) echo "Opção desconhecida: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$SYSTEM" ]]; then
    echo "Uso: boiler.sh --system <sistema> [--lang gdscript|csharp]" >&2
    echo ""
    echo "Sistemas disponíveis:"
    echo "  health         - Sistema de vida/dano/morte"
    echo "  inventory      - Inventário com slots e itens"
    echo "  state-machine  - StateMachine genérica"
    echo "  save-load      - Salvar/carregar dados do jogo"
    echo "  dialogue       - Sistema de diálogo com NPC"
    echo "  weapon         - Arma com cooldown e projétil"
    echo "  camera-shake   - CameraShake com trauma"
    echo "  enemy-ai       - IA inimigo simples (patrol/chase/attack)"
    echo "  signal-bus     - EventBus/SignalBus global"
    exit 1
fi

# Verifica se ollama está disponível
if ! command -v ollama &>/dev/null; then
    echo "AVISO: ollama não encontrado." >&2
    echo "Instale com: yay -S ollama" >&2
    echo "Depois: ollama pull qwen2.5:3b" >&2
    exit 1
fi

if ! ollama list 2>/dev/null | grep -q 'qwen2.5:3b'; then
    echo "AVISO: modelo qwen2.5:3b não encontrado." >&2
    echo "Baixe com: ollama pull qwen2.5:3b" >&2
    exit 1
fi

# Mapeia sistema para descrição
declare -A DESCRIPTIONS=(
    [health]="a Health component Node that manages current HP, max HP, damage(), heal(), die() with signals: health_changed(current, max), died"
    [inventory]="an Inventory system with configurable slot count, add_item(), remove_item(), has_item(), get_items() and signals: item_added, item_removed, inventory_full"
    [state-machine]="a generic StateMachine with State base class, transition_to(), current_state, with enter/exit/update/physics_update hooks"
    [save-load]="a SaveLoad autoload that uses FileAccess to save/load a Dictionary to user://save.json with save_game() and load_game()"
    [dialogue]="a Dialogue system with a DialogueBox UI node that reads from a Dictionary of dialogue trees, shows text with speaker, supports choices"
    [weapon]="a Weapon node with damage, fire_rate, ammo_count, shoot() method, cooldown Timer, and optional projectile scene instantiation"
    [camera-shake]="a CameraShake script using trauma (0-1) that drives random offset via noise, with add_trauma(amount) function, attached to Camera3D"
    [enemy-ai]="an Enemy AI with three states: PATROL (random waypoints), CHASE (toward player when in detection range), ATTACK (when in attack range), using NavigationAgent3D"
    [signal-bus]="a SignalBus autoload (EventBus pattern) with common game signals: player_died, score_changed(value), level_completed, item_collected(item)"
)

DESC="${DESCRIPTIONS[$SYSTEM]}"
if [[ -z "$DESC" ]]; then
    echo "Sistema '$SYSTEM' não reconhecido." >&2
    exit 1
fi

if [[ "$LANG" == "csharp" ]]; then
    LANG_LABEL="C# for Godot 4"
    LANG_NOTE="Use [Export], [Signal], partial class, GD.Print"
else
    LANG_LABEL="GDScript for Godot 4"
    LANG_NOTE="Use @export, signal, func, await, print"
fi

PROMPT="Write clean, minimal $LANG_LABEL boilerplate for: $DESC. $LANG_NOTE. No explanations, just the code."

echo "# Gerando: $SYSTEM ($LANG) via qwen2.5:3b..." >&2
echo ""

ollama run qwen2.5:3b "$PROMPT"
