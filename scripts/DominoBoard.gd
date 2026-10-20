class_name DominoBoard
extends Node2D

## Manages the domino board layout, chain ends, placement calculations,
## snake turns, and auto-framing camera/scaling.

signal tile_placed(tile: DominoTile, end_name: String)

const TILE_WIDTH: float = 56.0
const TILE_LENGTH: float = 112.0
const SPACING: float = 4.0

const MAX_EXTENT_X: float = 380.0
const MIN_EXTENT_X: float = -380.0

var open_left_val: int = -1
var open_right_val: int = -1

var left_anchor_pos: Vector2 = Vector2.ZERO
var right_anchor_pos: Vector2 = Vector2.ZERO

var left_dir: Vector2 = Vector2.LEFT
var right_dir: Vector2 = Vector2.RIGHT

var placed_tiles: Array[DominoTile] = []
var _bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var _history: Array[Dictionary] = []

func _ready() -> void:
	reset()

func reset() -> void:
	open_left_val = -1
	open_right_val = -1
	left_anchor_pos = Vector2.ZERO
	right_anchor_pos = Vector2.ZERO
	left_dir = Vector2.LEFT
	right_dir = Vector2.RIGHT
	placed_tiles.clear()
	_history.clear()
	_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)

func is_empty() -> bool:
	return placed_tiles.is_empty()

func get_open_val(end_name: String) -> int:
	if end_name == "left":
		return open_left_val
	elif end_name == "right":
		return open_right_val
	return -1

## Check if a tile can be played anywhere on the board
func can_play(tile: DominoTile) -> bool:
	if is_empty():
		return true
	return tile.has_val(open_left_val) or tile.has_val(open_right_val)

## Returns which ends are valid for this tile: ["left"], ["right"], ["left", "right"], or ["first"]
func get_valid_ends(tile: DominoTile) -> Array[String]:
	if is_empty():
		return ["first"]

	var ends: Array[String] = []
	if tile.has_val(open_left_val):
		ends.append("left")
	if tile.has_val(open_right_val):
		# If left and right ends have the same value, both are valid options
		ends.append("right")
	return ends

## Computes target position, rotation, and updates internal board state
func place_tile(tile: DominoTile, end_choice: String) -> Dictionary:
	_history.append({
		"tile": tile,
		"open_left_val": open_left_val,
		"open_right_val": open_right_val,
		"left_anchor_pos": left_anchor_pos,
		"right_anchor_pos": right_anchor_pos,
		"left_dir": left_dir,
		"right_dir": right_dir,
		"bounds": _bounds
	})

	var result: Dictionary = {
		"position": Vector2.ZERO,
		"rotation": 0.0,
		"end": end_choice
	}

	if is_empty() or end_choice == "first":
		result = _place_first_tile(tile)
	elif end_choice == "left":
		result = _place_left_tile(tile)
	elif end_choice == "right":
		result = _place_right_tile(tile)

	placed_tiles.append(tile)
	_update_bounds(result.position)
	tile_placed.emit(tile, end_choice)
	return result

func can_undo() -> bool:
	return not _history.is_empty()

func undo_last_placement() -> DominoTile:
	if _history.is_empty():
		return null
	var snap: Dictionary = _history.pop_back()
	var tile: DominoTile = snap["tile"]
	open_left_val = snap["open_left_val"]
	open_right_val = snap["open_right_val"]
	left_anchor_pos = snap["left_anchor_pos"]
	right_anchor_pos = snap["right_anchor_pos"]
	left_dir = snap["left_dir"]
	right_dir = snap["right_dir"]
	_bounds = snap["bounds"]
	placed_tiles.erase(tile)
	return tile

func _place_first_tile(tile: DominoTile) -> Dictionary:
	var pos: Vector2 = Vector2.ZERO
	var rot: float = 0.0

	if tile.is_double():
		# Doubles placed vertically
		rot = 0.0
		open_left_val = tile.top_val
		open_right_val = tile.bottom_val
		left_anchor_pos = pos + Vector2(-TILE_WIDTH * 0.5 - SPACING, 0)
		right_anchor_pos = pos + Vector2(TILE_WIDTH * 0.5 + SPACING, 0)
	else:
		# Placed horizontally: top_val on left, bottom_val on right
		rot = -PI * 0.5
		open_left_val = tile.top_val
		open_right_val = tile.bottom_val
		left_anchor_pos = pos + Vector2(-TILE_LENGTH * 0.5 - SPACING, 0)
		right_anchor_pos = pos + Vector2(TILE_LENGTH * 0.5 + SPACING, 0)

	left_dir = Vector2.LEFT
	right_dir = Vector2.RIGHT

	return {"position": pos, "rotation": rot}

## Computes preview target position and rotation without modifying board state.
func get_placement_preview(tile: DominoTile, end_choice: String) -> Dictionary:
	if is_empty() or end_choice == "first":
		var pos: Vector2 = Vector2.ZERO
		var rot: float = 0.0
		if tile.is_double():
			rot = 0.0
		else:
			rot = -PI * 0.5
		return {"position": pos, "rotation": rot, "end": "first"}
	elif end_choice == "left":
		var is_dbl: bool = tile.is_double()
		var matching_val: int = open_left_val
		var new_open_val: int = tile.get_other_val(matching_val)

		var dir: Vector2 = left_dir
		var anchor: Vector2 = left_anchor_pos

		# Check for snake turn if reaching left boundary
		if anchor.x <= MIN_EXTENT_X and dir == Vector2.LEFT:
			dir = Vector2.UP
		elif anchor.y <= -200.0 and dir == Vector2.UP:
			dir = Vector2.RIGHT
		elif anchor.x >= MAX_EXTENT_X and dir == Vector2.RIGHT:
			dir = Vector2.UP

		var pos: Vector2 = Vector2.ZERO
		var rot: float = 0.0
		var next_anchor: Vector2 = Vector2.ZERO

		if is_dbl:
			var center_offset: float = TILE_WIDTH * 0.5
			pos = anchor + dir * center_offset
			if dir.x != 0:
				rot = 0.0 # Vertical crosswise
			else:
				rot = PI * 0.5 # Horizontal crosswise
			next_anchor = pos + dir * (TILE_WIDTH * 0.5 + SPACING)
		else:
			var center_offset: float = TILE_LENGTH * 0.5
			pos = anchor + dir * center_offset

			if dir == Vector2.LEFT:
				if tile.top_val == new_open_val:
					rot = -PI * 0.5
				else:
					rot = PI * 0.5
			elif dir == Vector2.RIGHT:
				if tile.top_val == new_open_val:
					rot = PI * 0.5
				else:
					rot = -PI * 0.5
			elif dir == Vector2.UP:
				if tile.top_val == new_open_val:
					rot = 0.0
				else:
					rot = PI
			elif dir == Vector2.DOWN:
				if tile.top_val == new_open_val:
					rot = PI
				else:
					rot = 0.0

			next_anchor = pos + dir * (TILE_LENGTH * 0.5 + SPACING)

		return {
			"position": pos,
			"rotation": rot,
			"end": "left",
			"dir": dir,
			"new_open_val": new_open_val,
			"next_anchor": next_anchor
		}
	elif end_choice == "right":
		var is_dbl: bool = tile.is_double()
		var matching_val: int = open_right_val
		var new_open_val: int = tile.get_other_val(matching_val)

		var dir: Vector2 = right_dir
		var anchor: Vector2 = right_anchor_pos

		# Check for snake turn if reaching right boundary
		if anchor.x >= MAX_EXTENT_X and dir == Vector2.RIGHT:
			dir = Vector2.DOWN
		elif anchor.y >= 200.0 and dir == Vector2.DOWN:
			dir = Vector2.LEFT
		elif anchor.x <= MIN_EXTENT_X and dir == Vector2.LEFT:
			dir = Vector2.DOWN

		var pos: Vector2 = Vector2.ZERO
		var rot: float = 0.0
		var next_anchor: Vector2 = Vector2.ZERO

		if is_dbl:
			var center_offset: float = TILE_WIDTH * 0.5
			pos = anchor + dir * center_offset
			if dir.x != 0:
				rot = 0.0 # Vertical crosswise
			else:
				rot = PI * 0.5 # Horizontal crosswise
			next_anchor = pos + dir * (TILE_WIDTH * 0.5 + SPACING)
		else:
			var center_offset: float = TILE_LENGTH * 0.5
			pos = anchor + dir * center_offset

			if dir == Vector2.RIGHT:
				if tile.top_val == matching_val:
					rot = -PI * 0.5
				else:
					rot = PI * 0.5
			elif dir == Vector2.LEFT:
				if tile.top_val == matching_val:
					rot = PI * 0.5
				else:
					rot = -PI * 0.5
			elif dir == Vector2.DOWN:
				if tile.top_val == matching_val:
					rot = 0.0
				else:
					rot = PI
			elif dir == Vector2.UP:
				if tile.top_val == matching_val:
					rot = PI
				else:
					rot = 0.0

			next_anchor = pos + dir * (TILE_LENGTH * 0.5 + SPACING)

		return {
			"position": pos,
			"rotation": rot,
			"end": "right",
			"dir": dir,
			"new_open_val": new_open_val,
			"next_anchor": next_anchor
		}

	return {"position": Vector2.ZERO, "rotation": 0.0, "end": end_choice}

func _place_left_tile(tile: DominoTile) -> Dictionary:
	var preview: Dictionary = get_placement_preview(tile, "left")
	open_left_val = preview["new_open_val"]
	left_anchor_pos = preview["next_anchor"]
	left_dir = preview["dir"]
	return {"position": preview["position"], "rotation": preview["rotation"], "end": "left"}

func _place_right_tile(tile: DominoTile) -> Dictionary:
	var preview: Dictionary = get_placement_preview(tile, "right")
	open_right_val = preview["new_open_val"]
	right_anchor_pos = preview["next_anchor"]
	right_dir = preview["dir"]
	return {"position": preview["position"], "rotation": preview["rotation"], "end": "right"}

func _update_bounds(new_tile_pos: Vector2) -> void:
	var tile_rect := Rect2(new_tile_pos - Vector2(60, 60), Vector2(120, 120))
	if placed_tiles.size() == 1:
		_bounds = tile_rect
	else:
		_bounds = _bounds.merge(tile_rect)

func get_board_bounds() -> Rect2:
	return _bounds
