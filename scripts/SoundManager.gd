class_name SoundManager
extends Node

## Audio manager for Domino game.
## All generated and procedural sound effects have been removed per user preference.

static var instance: SoundManager = null

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	pass

# Public playback methods (silent no-ops so caller references remain intact without sound)
func play_place() -> void:
	pass

func play_deal() -> void:
	pass

func play_flip() -> void:
	pass

func play_shuffle() -> void:
	pass

func play_draw() -> void:
	pass

func play_hover() -> void:
	pass

func play_click() -> void:
	pass

func play_pass() -> void:
	pass

func play_win() -> void:
	pass
