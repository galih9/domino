class_name OpponentDialog
extends Control

## Modal dialog to choose opponent count (1, 2, or 3) and domino skin (Light by default).

signal setup_confirmed(opponent_count: int, theme_name: String)

var selected_opponents: int = 1
var selected_theme: String = "Light"

@onready var btn_opp_1: Button = $PanelContainer/VBox/OpponentsSection/HBox/Btn1
@onready var btn_opp_2: Button = $PanelContainer/VBox/OpponentsSection/HBox/Btn2
@onready var btn_opp_3: Button = $PanelContainer/VBox/OpponentsSection/HBox/Btn3

@onready var btn_theme_light: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnLight
@onready var btn_theme_dark: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnDark
@onready var btn_theme_ginger: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnGingerbread
@onready var btn_theme_hearts: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnHearts
@onready var btn_theme_stars: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnStars

@onready var btn_start: Button = $PanelContainer/VBox/BtnStart

func _ready() -> void:
	# Default selection: 1 opponent, Light theme
	_select_opponents(1)
	_select_theme("Light")

	btn_opp_1.pressed.connect(func(): _select_opponents(1))
	btn_opp_2.pressed.connect(func(): _select_opponents(2))
	btn_opp_3.pressed.connect(func(): _select_opponents(3))

	btn_theme_light.pressed.connect(func(): _select_theme("Light"))
	btn_theme_dark.pressed.connect(func(): _select_theme("Dark"))
	btn_theme_ginger.pressed.connect(func(): _select_theme("Gingerbread"))
	btn_theme_hearts.pressed.connect(func(): _select_theme("Hearts"))
	btn_theme_stars.pressed.connect(func(): _select_theme("Stars"))

	btn_start.pressed.connect(_on_start_pressed)

func _select_opponents(count: int) -> void:
	selected_opponents = count
	if SoundManager.instance:
		SoundManager.instance.play_click()
	_update_opp_buttons()

func _update_opp_buttons() -> void:
	_highlight_button(btn_opp_1, selected_opponents == 1)
	_highlight_button(btn_opp_2, selected_opponents == 2)
	_highlight_button(btn_opp_3, selected_opponents == 3)

func _select_theme(theme_name: String) -> void:
	selected_theme = theme_name
	ThemeManager.set_theme(theme_name)
	if SoundManager.instance:
		SoundManager.instance.play_click()
	_update_theme_buttons()

func _update_theme_buttons() -> void:
	_highlight_button(btn_theme_light, selected_theme == "Light")
	_highlight_button(btn_theme_dark, selected_theme == "Dark")
	_highlight_button(btn_theme_ginger, selected_theme == "Gingerbread")
	_highlight_button(btn_theme_hearts, selected_theme == "Hearts")
	_highlight_button(btn_theme_stars, selected_theme == "Stars")

func _highlight_button(btn: Button, active: bool) -> void:
	if btn == null:
		return
	if active:
		btn.modulate = Color(1.0, 0.9, 0.3, 1.0)
	else:
		btn.modulate = Color(0.85, 0.85, 0.85, 0.75)

func _on_start_pressed() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_click()
	setup_confirmed.emit(selected_opponents, selected_theme)
	hide()
