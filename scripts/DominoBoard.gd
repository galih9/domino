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
	_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)

func is_empty() -> bool:
	return placed_tiles.is_empty()

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

func _place_left_tile(tile: DominoTile) -> Dictionary:
	var is_dbl: bool = tile.is_double()
	var matching_val: int = open_left_val
	var new_open_val: int = tile.get_other_val(matching_val)

	# Check for snake turn if reaching left boundary
	if left_anchor_pos.x <= MIN_EXTENT_X and left_dir == Vector2.LEFT:
		left_dir = Vector2.UP
	elif left_anchor_pos.y <= -200.0 and left_dir == Vector2.UP:
		left_dir = Vector2.RIGHT
	elif left_anchor_pos.x >= MAX_EXTENT_X and left_dir == Vector2.RIGHT:
		left_dir = Vector2.UP

	var pos: Vector2 = Vector2.ZERO
	var rot: float = 0.0

	if is_dbl:
		# Double is placed crosswise (perpendicular to movement direction)
		var center_offset: float = TILE_WIDTH * 0.5
		pos = left_anchor_pos + left_dir * center_offset
		if left_dir.x != 0:
			rot = 0.0 # Vertical crosswise
		else:
			rot = PI * 0.5 # Horizontal crosswise
		left_anchor_pos = pos + left_dir * (TILE_WIDTH * 0.5 + SPACING)
	else:
		# Normal tile placed lengthwise
		var center_offset: float = TILE_LENGTH * 0.5
		pos = left_anchor_pos + left_dir * center_offset

		if left_dir == Vector2.LEFT:
			# Traveling left: matching value connects on right, new_open_val on left
			# Texture: top_val is index 0 (top), bottom_val is index 1 (bottom).
			# If rot = -PI/2: top is left, bottom is right.
			# If rot = PI/2: top is right, bottom is left.
			if tile.top_val == new_open_val:
				rot = -PI * 0.5 # top (new_open) on left, bottom (matching) on right
			else:
				rot = PI * 0.5 # top (matching) on right, bottom (new_open) on left
		elif left_dir == Vector2.RIGHT:
			# Traveling right
			if tile.top_val == new_open_val:
				rot = PI * 0.5 # top (new_open) on right, bottom on left
			else:
				rot = -PI * 0.5
		elif left_dir == Vector2.UP:
			# Traveling up: matching connects down, new_open up
			if tile.top_val == new_open_val:
				rot = 0.0 # top is up
			else:
				rot = PI # bottom is up
		elif left_dir == Vector2.DOWN:
			# Traveling down: matching connects up, new_open down
			if tile.top_val == new_open_val:
				rot = PI
			else:
				rot = 0.0

		left_anchor_pos = pos + left_dir * (TILE_LENGTH * 0.5 + SPACING)

	open_left_val = new_open_val
	return {"position": pos, "rotation": rot}

func _place_right_tile(tile: DominoTile) -> Dictionary:
	var is_dbl: bool = tile.is_double()
	var matching_val: int = open_right_val
	var new_open_val: int = tile.get_other_val(matching_val)

	# Check for snake turn if reaching right boundary
	if right_anchor_pos.x >= MAX_EXTENT_X and right_dir == Vector2.RIGHT:
		right_dir = Vector2.DOWN
	elif right_anchor_pos.y >= 200.0 and right_dir == Vector2.DOWN:
		right_dir = Vector2.LEFT
	elif right_anchor_pos.x <= MIN_EXTENT_X and right_dir == Vector2.LEFT:
		right_dir = Vector2.DOWN

	var pos: Vector2 = Vector2.ZERO
	var rot: float = 0.0

	if is_dbl:
		# Double crosswise
		var center_offset: float = TILE_WIDTH * 0.5
		pos = right_anchor_pos + right_dir * center_offset
		if right_dir.x != 0:
			rot = 0.0 # Vertical crosswise
		else:
			rot = PI * 0.5 # Horizontal crosswise
		right_anchor_pos = pos + right_dir * (TILE_WIDTH * 0.5 + SPACING)
	else:
		# Lengthwise
		var center_offset: float = TILE_LENGTH * 0.5
		pos = right_anchor_pos + right_dir * center_offset

		if right_dir == Vector2.RIGHT:
			# Traveling right: matching value connects on left, new_open_val on right
			if tile.top_val == matching_val:
				rot = -PI * 0.5 # top (matching) on left, bottom (new_open) on right
			else:
				rot = PI * 0.5 # top (new_open) on right, bottom (matching) on left
		elif right_dir == Vector2.LEFT:
			# Traveling left
			if tile.top_val == matching_val:
				rot = PI * 0.5
			else:
				rot = -PI * 0.5
		elif right_dir == Vector2.DOWN:
			# Traveling down: matching connects up, new_open down
			if tile.top_val == matching_val:
				rot = 0.0 # top connects up, bottom is down
			else:
				rot = PI
		elif right_dir == Vector2.UP:
			if tile.top_val == matching_val:
				rot = PI
			else:
				rot = 0.0

		right_anchor_pos = pos + right_dir * (TILE_LENGTH * 0.5 + SPACING)

	open_right_val = new_open_val
	return {"position": pos, "rotation": rot}

func _update_bounds(new_tile_pos: Vector2) -> void:
	var tile_rect := Rect2(new_tile_pos - Vector2(60, 60), Vector2(120, 120))
	if placed_tiles.size() == 1:
		_bounds = tile_rect
	else:
		_bounds = _bounds.merge(tile_rect)

func get_board_bounds() -> Rect2:
	return _bounds
