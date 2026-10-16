# AGENTS.md - Developer & Agent Instructions

## ⚠️ ABSOLUTE RULE: NO EMOJIS IN THE GAME

**DO NOT ADD EMOJIS ANYWHERE IN THIS CODEBASE (UI labels, button texts, dialog titles, toasts, GDScript strings).**

### Rationale:
- The game targets **Web export (HTML5 / WebAssembly)** for browser play.
- Godot's web export font engine lacks an emoji fallback font.
- When any emoji (e.g. 🎨, 🎲, 🏆, 🃏, 👤, ⏱, etc.) is rendered on web, Godot renders a missing-glyph fallback containing the raw hex/binary Unicode codepoint in tiny boxes.
- This creates an ugly, broken appearance for players.

### What to do instead:
1. Use clean, professional text labels (e.g., `Themes`, `Rules`, `Dominoes`, `1-3 AI`, `Draw & Match`).
2. If icons are required, use `TextureRect` or `Sprite2D` with SVG/PNG assets from `res://assets/`.
3. Never commit emojis to `.tscn` scene files or `.gd` script strings.
