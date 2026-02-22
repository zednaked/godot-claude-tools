# godot-claude-tools

Scripts que Claude Code usa antes de ler arquivos Godot, reduzindo tokens drasticamente.

## Instalação

```bash
git clone https://github.com/zednaked/godot-claude-tools
bash godot-claude-tools/install.sh
```

Atualizar numa máquina existente:

```bash
git pull && bash install.sh
```

## Ferramentas

| Ferramenta | Uso | Redução |
|---|---|---|
| `scene-map.py` | Resume `.tscn` | 676 linhas → ~20 |
| `script-outline.py` | Resume `.gd` / `.cs` | 200 linhas → ~25 |
| `error-filter.sh` | Filtra log do Godot | só erros relevantes |
| `boiler.sh` | Boilerplate via qwen2.5:3b | — |
| `project-context.sh` | Resume projeto inteiro | — |

## Exemplos

```bash
# Resumir uma cena
python3 ~/.claude/tools/godot/scene-map.py enemy.tscn

# Resumir um script
python3 ~/.claude/tools/godot/script-outline.py Player.gd
python3 ~/.claude/tools/godot/script-outline.py GameManager.cs

# Filtrar log de erro
godot --headless 2>&1 | bash ~/.claude/tools/godot/error-filter.sh

# Gerar boilerplate (requer ollama + qwen2.5:3b)
bash ~/.claude/tools/godot/boiler.sh --system health --lang gdscript
bash ~/.claude/tools/godot/boiler.sh --system inventory --lang csharp

# Resumir projeto inteiro
bash ~/.claude/tools/godot/project-context.sh ./meu-projeto/
```

## Sistemas disponíveis no boiler.sh

`health` · `inventory` · `state-machine` · `save-load` · `dialogue` · `weapon` · `camera-shake` · `enemy-ai` · `signal-bus`

## Dependências

- Python 3 (para scene-map e script-outline)
- `ollama` + `qwen2.5:3b` (só para boiler.sh)
  ```bash
  # Arch Linux
  yay -S ollama
  ollama pull qwen2.5:3b
  ```
