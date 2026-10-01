class_name AIPlayer
extends Player

## AI player with strategic decision making for Dominoes.

func _init(p_id: int, p_name: String) -> void:
	super._init(p_id, p_name, false)

## Selects the best move (tile + end) based on domino strategy heuristics
func choose_move(board: DominoBoard) -> Dictionary:
	var playable: Array[DominoTile] = get_playable_tiles(board)
	if playable.is_empty():
		return {}

	# If board is empty, lead with highest double or heaviest tile
	if board.is_empty():
		var dbl: DominoTile = get_highest_double()
		if dbl != null:
			return {"tile": dbl, "end": "first"}
		var best_tile: DominoTile = get_highest_tile()
		return {"tile": best_tile, "end": "first"}

	var best_score: float = -999999.0
	var chosen_move: Dictionary = {}

	for tile in playable:
		var valid_ends: Array[String] = board.get_valid_ends(tile)
		for end_name in valid_ends:
			var score: float = _evaluate_move(tile, end_name, board)
			if score > best_score:
				best_score = score
				chosen_move = {"tile": tile, "end": end_name}

	return chosen_move

func _evaluate_move(tile: DominoTile, end_name: String, board: DominoBoard) -> float:
	var score: float = 0.0

	# 1. Prioritize playing doubles to avoid getting stuck with them
	if tile.is_double():
		score += 35.0

	# 2. Prefer playing heavier tiles (pip sum) to lower remaining points
	score += tile.pip_sum() * 1.5

	# 3. Synergy with remaining hand
	var matching_end_val: int = board.open_left_val if end_name == "left" else board.open_right_val
	var resulting_open_val: int = tile.get_other_val(matching_end_val)

	var matching_count: int = 0
	for other in hand:
		if other != tile and other.has_val(resulting_open_val):
			matching_count += 1

	# Reward moves that keep values AI can still play on next turn
	score += matching_count * 18.0

	# Small randomness to keep AI natural and varied
	score += randf_range(-1.0, 1.0)

	return score
