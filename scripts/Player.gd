class_name Player
extends RefCounted

## Represents a player (Human or AI) in the Domino game.

var id: int = 0
var name: String = "Player"
var is_human: bool = true
var hand: Array[DominoTile] = []
var round_score: int = 0
var total_score: int = 0

func _init(p_id: int, p_name: String, p_is_human: bool = false) -> void:
	id = p_id
	name = p_name
	is_human = p_is_human

func add_tile(tile: DominoTile) -> void:
	tile.owner_id = id
	hand.append(tile)

func remove_tile(tile: DominoTile) -> void:
	hand.erase(tile)

func clear_hand() -> void:
	hand.clear()

func hand_size() -> int:
	return hand.size()

func get_pip_sum() -> int:
	var total: int = 0
	for t in hand:
		total += t.pip_sum()
	return total

func get_highest_double() -> DominoTile:
	var highest: DominoTile = null
	for t in hand:
		if t.is_double():
			if highest == null or t.top_val > highest.top_val:
				highest = t
	return highest

func get_highest_tile() -> DominoTile:
	var highest: DominoTile = null
	for t in hand:
		if highest == null or t.pip_sum() > highest.pip_sum():
			highest = t
	return highest

func get_playable_tiles(board: DominoBoard) -> Array[DominoTile]:
	var playable: Array[DominoTile] = []
	for t in hand:
		if board.can_play(t):
			playable.append(t)
	return playable

func has_playable(board: DominoBoard) -> bool:
	for t in hand:
		if board.can_play(t):
			return true
	return false
