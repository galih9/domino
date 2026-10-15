class_name GameSettings
extends RefCounted

## Global settings and game configuration shared across all scenes and modes.

# Classic Domino mode configuration
static var classic_opponents: int = 1 # 1, 2, or 3 AI opponents

# Sebastopol Domino mode configuration (The Star)
static var sebastopol_opponents: int = 3 # 1, 2, or 3 AI opponents (3 AI = 4 players total, classic standard)
static var sebastopol_match_target: int = 100 # 50, 100, 150, 200 match target points

# Klondike Solitaire card game configuration
static var solitaire_draw_count: int = 1 # 1 (Draw 1) or 3 (Draw 3)
static var solitaire_card_back: String = "cardBack_blue1.png"

# Texas Hold'em Poker configuration
static var holdem_opponents: int = 3 # 1, 2, or 3 AI opponents
static var holdem_starting_chips: int = 1000 # 500, 1000, 2000
static var holdem_small_blind: int = 10
static var holdem_big_blind: int = 20

# Gin Rummy configuration
static var gin_match_target: int = 100 # 50, 100, 150
static var gin_ai_difficulty: String = "Normal" # "Normal", "Sharp"

# Pyramid Solitaire configuration
static var pyramid_passes: int = 3 # 1, 3, or 999 (unlimited)

# Tri Peaks Solitaire configuration
static var tripeaks_passes: int = 1 # 1, 3, or 999 (unlimited)
static var tripeaks_wrap_cards: bool = true # Ace <-> King wrap-around

# Koi-Koi Hanafuda configuration
static var koikoi_rounds: int = 3 # 3, 6, 12 rounds
static var koikoi_viewing_yaku: bool = true # Hanami / Tsukimi viewing Yaku enabled
static var koikoi_ai_difficulty: String = "Normal" # "Normal", "Sharp"

# Statistics & High Scores
static var solitaire_best_score: int = 0
static var solitaire_wins: int = 0
static var solitaire_games_played: int = 0
static var solitaire_fastest_time: float = 999999.0
static var solitaire_fewest_moves: int = 999999

static var pyramid_best_score: int = 0
static var pyramid_wins: int = 0
static var pyramid_games_played: int = 0
static var pyramid_fastest_time: float = 999999.0
static var pyramid_fewest_moves: int = 999999
static var pyramid_clears: int = 0

static var tripeaks_best_score: int = 0
static var tripeaks_wins: int = 0
static var tripeaks_games_played: int = 0
static var tripeaks_fastest_time: float = 999999.0
static var tripeaks_fewest_moves: int = 999999
static var tripeaks_highest_streak: int = 0
static var tripeaks_clears: int = 0

static var holdem_hands_played: int = 0
static var holdem_hands_won: int = 0
static var holdem_biggest_pot_won: int = 0

static var gin_games_played: int = 0
static var gin_matches_won: int = 0
static var gin_gins_scored: int = 0

static var sebastopol_games_played: int = 0
static var sebastopol_matches_won: int = 0
static var sebastopol_rounds_won: int = 0
static var sebastopol_highest_score: int = 0

static var koikoi_games_played: int = 0
static var koikoi_matches_won: int = 0
static var koikoi_rounds_won: int = 0
static var koikoi_highest_round_score: int = 0
static var koikoi_times_called: int = 0

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

static func set_holdem_opponents(count: int) -> void:
	holdem_opponents = clampi(count, 1, 3)

static func set_holdem_starting_chips(chips: int) -> void:
	holdem_starting_chips = maxi(100, chips)

static func record_holdem_hand(won: bool, pot_size: int) -> void:
	holdem_hands_played += 1
	if won:
		holdem_hands_won += 1
		if pot_size > holdem_biggest_pot_won:
			holdem_biggest_pot_won = pot_size

static func set_gin_match_target(target: int) -> void:
	gin_match_target = target

static func set_gin_ai_difficulty(diff: String) -> void:
	gin_ai_difficulty = diff

static func record_gin_match(player_won: bool, gins: int) -> void:
	gin_games_played += 1
	if player_won:
		gin_matches_won += 1
	gin_gins_scored += gins

static func set_pyramid_passes(passes: int) -> void:
	pyramid_passes = passes

static func record_pyramid_game(final_score: int, won: bool, moves: int, time_sec: float) -> void:
	pyramid_games_played += 1
	if won:
		pyramid_wins += 1
		pyramid_clears += 1
		if time_sec < pyramid_fastest_time:
			pyramid_fastest_time = time_sec
		if moves < pyramid_fewest_moves:
			pyramid_fewest_moves = moves
	if final_score > pyramid_best_score:
		pyramid_best_score = final_score

static func set_tripeaks_passes(passes: int) -> void:
	tripeaks_passes = passes

static func set_tripeaks_wrap(wrap: bool) -> void:
	tripeaks_wrap_cards = wrap

static func record_tripeaks_game(final_score: int, won: bool, moves: int, time_sec: float, max_streak: int = 0) -> void:
	tripeaks_games_played += 1
	if max_streak > tripeaks_highest_streak:
		tripeaks_highest_streak = max_streak
	if won:
		tripeaks_wins += 1
		tripeaks_clears += 1
		if time_sec < tripeaks_fastest_time:
			tripeaks_fastest_time = time_sec
		if moves < tripeaks_fewest_moves:
			tripeaks_fewest_moves = moves
	if final_score > tripeaks_best_score:
		tripeaks_best_score = final_score

static func set_sebastopol_opponents(count: int) -> void:
	sebastopol_opponents = clampi(count, 1, 3)

static func set_sebastopol_match_target(target: int) -> void:
	sebastopol_match_target = target

static func record_sebastopol_round(won: bool, score: int) -> void:
	if won:
		sebastopol_rounds_won += 1
		if score > sebastopol_highest_score:
			sebastopol_highest_score = score

static func record_sebastopol_match(won: bool) -> void:
	sebastopol_games_played += 1
	if won:
		sebastopol_matches_won += 1

static func set_koikoi_rounds(rounds: int) -> void:
	koikoi_rounds = rounds

static func set_koikoi_viewing_yaku(enabled: bool) -> void:
	koikoi_viewing_yaku = enabled

static func set_koikoi_ai_difficulty(diff: String) -> void:
	koikoi_ai_difficulty = diff

static func record_koikoi_round(won: bool, score: int, called_koikoi: bool) -> void:
	if won:
		koikoi_rounds_won += 1
		if score > koikoi_highest_round_score:
			koikoi_highest_round_score = score
	if called_koikoi:
		koikoi_times_called += 1

static func record_koikoi_match(won: bool) -> void:
	koikoi_games_played += 1
	if won:
		koikoi_matches_won += 1

