# Domino & Card Classics (Godot 4)

A multi-game collection built in Godot 4, featuring Dominoes (Classic Draw, Sebastopol Star), Solitaire (Klondike, Pyramid, Tri-Peaks), and Card Classics (Texas Hold'em, Gin Rummy, Koi-Koi Hanafuda).

---

## ⚠️ CRITICAL DEVELOPER GUIDELINE: NEVER ADD EMOJIS

> **IMPORTANT RULE FOR ALL DEVELOPERS & AI ASSISTANTS**:
> **Never ever add Unicode emojis in any game UI, labels, buttons, dialogs, toasts, or GDScript strings.**
>
> ### Why:
> The **Web export (HTML5 / WebAssembly)** does **NOT** bundle an emoji fallback font. When an emoji glyph is rendered in Godot's Web export, Godot's `TextServer` cannot resolve the glyph and falls back to rendering the hexadecimal / binary codepoint inside a small box (e.g., `[1F3B2]`). This causes icons to look like broken binary numbers and corrupted characters to players in web browsers.
>
> ### Guidelines:
> - **Use clean text** for all titles, badges, and button labels (e.g., `Themes`, `Rules`, `All Games (7)`, `Classic Domino`, `1-3 AI`).
> - If visual iconography is needed, use **TextureRect / SVG / PNG image assets** or well-supported standard ASCII characters.
> - Do not introduce emojis in `.tscn`, `.gd`, `.tres`, or export templates.

---

## Game Modes

1. **Classic Domino** (2-4 Players)
2. **Sebastopol Domino** (The 4-Arm Star Hub)
3. **Klondike Solitaire** (1-Card and 3-Card Draw modes)
4. **Pyramid Solitaire** (Pairing sum to 13)
5. **Tri-Peaks Solitaire** (Streak matching ±1)
6. **Texas Hold'em Poker** (No-Limit Hold'em vs AI)
7. **Gin Rummy** (2-Player meld builder vs AI)
8. **Koi-Koi** (Traditional Japanese Hanafuda flower card duel)

---

## Running and Testing

Run test suites headlessly:
```bash
godot --headless --script test/test_runner.gd
godot --headless --script test/test_solitaire_drag.gd
godot --headless --script test/test_solitaire_visuals.gd
```
