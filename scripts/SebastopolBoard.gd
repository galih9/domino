class_name SebastopolBoard
extends Node2D

## Sebastopol Domino Board (The Star).
## Manages the central [6-6] spinner, 4-way star opening, 4 directional arms
## (North, South, East, West), snake turns, and layout bounds.

signal tile_placed(tile: DominoTile, arm_name: String)
signal star_completed()

const TILE_WIDTH: float = 56.0
const TILE_LENGTH: float = 112.0
const SPACING: float = 4.0

const ARMS: Array[String] = ["north", "south", "east", "west"]

# Central spinner
var spinner_tile: DominoTile = null
var is_star_complete: bool = false

# Per-arm tracking: "north", "south", "east", "west"
var arm_tiles: Dictionary = {
	"north": [] as Array[DominoTile],
	"south": [] as Array[DominoTile],
	"east": [] as Array[DominoTile],
	"west": [] as Array[DominoTile]
}

var open_vals: Dictionary = {
	"north": -1,
	"south": -1,
	"east": -1,
	"west": -1
}

var anchor_positions: Dictionary = {
	"north": Vector2.ZERO,
	"south": Vector2.ZERO,
	"east": Vector2.ZERO,
	"west": Vector2.ZERO
}

var directions: Dictionary = {
	"north": Vector2.UP,
	"south": Vector2.DOWN,
	"east": Vector2.RIGHT,
	"west": Vector2.LEFT
}

var placed_tiles: Array[DominoTile] = []
var _bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var _history: Array[Dictionary] = []

func _ready() -> void:
	reset()

func reset() -> void:
	spinner_tile = null
	is_star_complete = false
	placed_tiles.clear()
	_history.clear()
	_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)

	arm_tiles = {
		"north": [] as Array[DominoTile],
		"south": [] as Array[DominoTile],
		"east": [] as Array[DominoTile],
		"west": [] as Array[DominoTile]
	}

	open_vals = {
		"north": -1,
		"south": -1,
		"east": -1,
		"west": -1
	}

	anchor_positions = {
		"north": Vector2.ZERO,
		"south": Vector2.ZERO,
		"east": Vector2.ZERO,
		"west": Vector2.ZERO
	}

	directions = {
		"north": Vector2.UP,
		"south": Vector2.DOWN,
		"east": Vector2.RIGHT,
		"west": Vector2.LEFT
	}

func is_empty() -> bool:
	return placed_tiles.is_empty()

func get_open_val(arm_name: String) -> int:
	return open_vals.get(arm_name, -1)

func get_filled_arms_count() -> int:
	var count: int = 0
	for a in ARMS:
		var arr: Array = arm_tiles[a]
		if not arr.is_empty():
			count += 1
	return count

func get_empty_arms() -> Array[String]:
	var empty_list: Array[String] = []
	for a in ARMS:
		var arr: Array = arm_tiles[a]
		if arr.is_empty():
			empty_list.append(a)
	return empty_list

## Check whether a tile can be played anywhere on the Sebastopol board.
func can_play(tile: DominoTile) -> bool:
	if is_empty():
		# In standard Sebastopol, double-six must open the board
		return tile.top_val == 6 and tile.bottom_val == 6

	if not is_star_complete:
		# During opening phase: must have a 6 and at least one arm must be empty
		if not tile.has_val(6):
			return false
		return get_filled_arms_count() < 4

	# Star is complete: tile can play on any open arm
	for a in ARMS:
		var val: int = open_vals[a]
		if val != -1 and tile.has_val(val):
			return true
	return false

## Returns which ends / arms are valid for this tile.
## Returns ["center"] for the opening 6-6, or a subset of ["north", "south", "east", "west"].
func get_valid_ends(tile: DominoTile) -> Array[String]:
	if is_empty():
		if tile.top_val == 6 and tile.bottom_val == 6:
			return ["center"]
		return []

	var valid: Array[String] = []

	if not is_star_complete:
		# Opening phase: Can only play on EMPTY arms of the [6-6] spinner
		if tile.has_val(6):
			for a in ARMS:
				var arr: Array = arm_tiles[a]
				if arr.is_empty():
					valid.append(a)
		return valid

	# Open phase: Can play on any arm matching that arm's open value
	for a in ARMS:
		var val: int = open_vals[a]
		if val != -1 and tile.has_val(val):
			valid.append(a)
	return valid

## Computes target position, rotation, and updates internal board state
func place_tile(tile: DominoTile, arm_choice: String) -> Dictionary:
	# Snapshot state for undo
	_history.append({
		"tile": tile,
		"spinner_tile": spinner_tile,
		"is_star_complete": is_star_complete,
		"arm_tiles": {
			"north": arm_tiles["north"].duplicate(),
			"south": arm_tiles["south"].duplicate(),
			"east": arm_tiles["east"].duplicate(),
			"west": arm_tiles["west"].duplicate()
		},
		"open_vals": open_vals.duplicate(),
		"anchor_positions": anchor_positions.duplicate(),
		"directions": directions.duplicate(),
		"bounds": _bounds
	})

	var result: Dictionary = {
		"position": Vector2.ZERO,
		"rotation": 0.0,
		"arm": arm_choice
	}

	if is_empty() or arm_choice == "center" or arm_choice == "first":
		result = _place_spinner(tile)
	else:
		result = _place_arm_tile(tile, arm_choice)

	placed_tiles.append(tile)
	_update_bounds(result.position)

	# Check if star was completed by this move
	if not is_star_complete and get_filled_arms_count() == 4:
		is_star_complete = true
		star_completed.emit()

	tile_placed.emit(tile, arm_choice)
	return result

func can_undo() -> bool:
	return not _history.is_empty()

func undo_last_placement() -> DominoTile:
	if _history.is_empty():
		return null
	var snap: Dictionary = _history.pop_back()
	var tile: DominoTile = snap["tile"]

	spinner_tile = snap["spinner_tile"]
	is_star_complete = snap["is_star_complete"]
	arm_tiles = snap["arm_tiles"]
	open_vals = snap["open_vals"]
	anchor_positions = snap["anchor_positions"]
	directions = snap["directions"]
	_bounds = snap["bounds"]
	placed_tiles.erase(tile)
	return tile

## Places the opening double-six in the center of the board
func _place_spinner(tile: DominoTile) -> Dictionary:
	var pos: Vector2 = Vector2.ZERO
	var rot: float = 0.0 # Vertical spinner: 6 on top, 6 on bottom
	spinner_tile = tile

	# All 4 arms connect to a 6
	open_vals["north"] = 6
	open_vals["south"] = 6
	open_vals["east"] = 6
	open_vals["west"] = 6

	# Set initial anchor points just off the edges of the central tile
	# Central tile height = TILE_LENGTH (112), width = TILE_WIDTH (56)
	anchor_positions["north"] = pos + Vector2(0, -TILE_LENGTH * 0.5 - SPACING)
	anchor_positions["south"] = pos + Vector2(0, TILE_LENGTH * 0.5 + SPACING)
	anchor_positions["east"] = pos + Vector2(TILE_WIDTH * 0.5 + SPACING, 0)
	anchor_positions["west"] = pos + Vector2(-TILE_WIDTH * 0.5 - SPACING, 0)

	directions["north"] = Vector2.UP
	directions["south"] = Vector2.DOWN
	directions["east"] = Vector2.RIGHT
	directions["west"] = Vector2.LEFT

	return {"position": pos, "rotation": rot, "arm": "center"}

## Places a tile extending from the specified arm
func _place_arm_tile(tile: DominoTile, arm: String) -> Dictionary:
	var is_dbl: bool = tile.is_double()
	var matching_val: int = open_vals[arm]
	var new_open_val: int = tile.get_other_val(matching_val)

	var dir: Vector2 = directions[arm]
	var anchor: Vector2 = anchor_positions[arm]

	# Handle snaking turns for each arm when reaching bounds
	dir = _calculate_snake_turn(arm, anchor, dir)

	var pos: Vector2 = Vector2.ZERO
	var rot: float = 0.0

	if is_dbl:
		# Double tile placed crosswise (perpendicular to travel direction)
		var center_offset: float = TILE_WIDTH * 0.5
		pos = anchor + dir * center_offset
		if dir.x != 0:
			rot = 0.0 # Vertical crosswise when traveling horizontally
		else:
			rot = PI * 0.5 # Horizontal crosswise when traveling vertically
		anchor = pos + dir * (TILE_WIDTH * 0.5 + SPACING)
	else:
		# Lengthwise along travel direction
		var center_offset: float = TILE_LENGTH * 0.5
		pos = anchor + dir * center_offset

		if dir == Vector2.UP:
			# Traveling UP: matching connects DOWN, new_open faces UP
			if tile.top_val == new_open_val:
				rot = 0.0 # top is UP, bottom is DOWN
			else:
				rot = PI # bottom is UP, top is DOWN
		elif dir == Vector2.DOWN:
			# Traveling DOWN: matching connects UP, new_open faces DOWN
			if tile.top_val == matching_val:
				rot = 0.0 # top connects UP, bottom is DOWN
			else:
				rot = PI
		elif dir == Vector2.RIGHT:
			# Traveling RIGHT: matching connects LEFT, new_open faces RIGHT
			# rot = -PI*0.5 -> top is LEFT, bottom is RIGHT
			# rot = PI*0.5  -> top is RIGHT, bottom is LEFT
			if tile.top_val == matching_val:
				rot = -PI * 0.5
			else:
				rot = PI * 0.5
		elif dir == Vector2.LEFT:
			# Traveling LEFT: matching connects RIGHT, new_open faces LEFT
			if tile.top_val == new_open_val:
				rot = -PI * 0.5
			else:
				rot = PI * 0.5

		anchor = pos + dir * (TILE_LENGTH * 0.5 + SPACING)

	# Update board state for this arm
	open_vals[arm] = new_open_val
	anchor_positions[arm] = anchor
	directions[arm] = dir
	arm_tiles[arm].append(tile)

	return {"position": pos, "rotation": rot, "arm": arm}

## Snake turn calculations keeping the 4 branches well organized
func _calculate_snake_turn(arm: String, anchor: Vector2, current_dir: Vector2) -> Vector2:
	var dir: Vector2 = current_dir

	match arm:
		"north":
			if anchor.y <= -240.0 and dir == Vector2.UP:
				dir = Vector2.RIGHT
			elif anchor.x >= 380.0 and dir == Vector2.RIGHT:
				dir = Vector2.DOWN
		"south":
			if anchor.y >= 240.0 and dir == Vector2.DOWN:
				dir = Vector2.LEFT
			elif anchor.x <= -380.0 and dir == Vector2.LEFT:
				dir = Vector2.UP
		"east":
			if anchor.x >= 380.0 and dir == Vector2.RIGHT:
				dir = Vector2.DOWN
			elif anchor.y >= 240.0 and dir == Vector2.DOWN:
				dir = Vector2.LEFT
		"west":
			if anchor.x <= -380.0 and dir == Vector2.LEFT:
				dir = Vector2.UP
			elif anchor.y <= -240.0 and dir == Vector2.UP:
				dir = Vector2.RIGHT

	return dir

func _update_bounds(new_tile_pos: Vector2) -> void:
	var tile_rect := Rect2(new_tile_pos - Vector2(70, 70), Vector2(140, 140))
	if placed_tiles.size() == 1:
		_bounds = tile_rect
	else:
		_bounds = _bounds.merge(tile_rect)

func get_board_bounds() -> Rect2:
	return _bounds
