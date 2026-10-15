class_name GameSettings
extends RefCounted

## Global settings and game configuration shared across all scenes and modes.

# Classic Domino mode configuration
static var classic_opponents: int = 1 # 1, 2, or 3 AI opponents

# Klondike Solitaire card game configuration
static var solitaire_draw_count: int = 1 # 1 (Draw 1) or 3 (Draw 3)
static var solitaire_card_back: String = "cardBack_blue1.png"

# Statistics & High Scores
static var solitaire_best_score: int = 0
static var solitaire_wins: int = 0
static var solitaire_games_played: int = 0
static var solitaire_fastest_time: float = 999999.0
static var solitaire_fewest_moves: int = 999999

static func set_solitaire_draw_count(draw_count: int) -> void:
	solitaire_draw_count = 3 if draw_count == 3 else 1

static func set_card_back(back_filename: String) -> void:
	solitaire_card_back = back_filename
	CardTheme.set_card_back(back_filename)

static func record_solitaire_game(final_score: int, won: bool, moves: int, time_sec: float) -> void:
	solitaire_games_played += 1
	if won:
		solitaire_wins += 1
		if time_sec < solitaire_fastest_time:
			solitaire_fastest_time = time_sec
		if moves < solitaire_fewest_moves:
			solitaire_fewest_moves = moves
	if final_score > solitaire_best_score:
		solitaire_best_score = final_score
