class_name OpponentDialog
extends Control

## Modal dialog to choose opponent count (1, 2, or 3) and domino skin.

signal setup_confirmed(opponent_count: int, theme_name: String)

var selected_opponents: int = 1
var selected_theme: String = "Light"

@onready var panel: PanelContainer = $PanelContainer
@onready var btn_opp_1: Button = $PanelContainer/VBox/OpponentsSection/HBox/Btn1
@onready var btn_opp_2: Button = $PanelContainer/VBox/OpponentsSection/HBox/Btn2
@onready var btn_opp_3: Button = $PanelContainer/VBox/OpponentsSection/HBox/Btn3

@onready var btn_theme_light: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnLight
@onready var btn_theme_dark: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnDark
@onready var btn_theme_ginger: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnGingerbread
@onready var btn_theme_hearts: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnHearts
@onready var btn_theme_stars: Button = $PanelContainer/VBox/ThemeSection/HBox/BtnStars

@onready var btn_start: Button = $PanelContainer/VBox/BtnStart

var _style_normal: StyleBoxFlat
var _style_active: StyleBoxFlat

func _ready() -> void:
	_init_styles()
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

func _init_styles() -> void:
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.12, 0.15, 0.18, 0.65)
	_style_normal.border_width_left = 1
	_style_normal.border_width_top = 1
	_style_normal.border_width_right = 1
	_style_normal.border_width_bottom = 1
	_style_normal.border_color = Color(1.0, 1.0, 1.0, 0.08)
	_style_normal.corner_radius_top_left = 8
	_style_normal.corner_radius_top_right = 8
	_style_normal.corner_radius_bottom_right = 8
	_style_normal.corner_radius_bottom_left = 8
	_style_normal.content_margin_left = 12.0
	_style_normal.content_margin_top = 8.0
	_style_normal.content_margin_right = 12.0
	_style_normal.content_margin_bottom = 8.0

	_style_active = StyleBoxFlat.new()
	_style_active.bg_color = Color(0.18, 0.24, 0.28, 0.95)
	_style_active.border_width_left = 1
	_style_active.border_width_top = 1
	_style_active.border_width_right = 1
	_style_active.border_width_bottom = 1
	_style_active.border_color = Color(0.92, 0.8, 0.38, 0.9)
	_style_active.corner_radius_top_left = 8
	_style_active.corner_radius_top_right = 8
	_style_active.corner_radius_bottom_right = 8
	_style_active.corner_radius_bottom_left = 8
	_style_active.content_margin_left = 12.0
	_style_active.content_margin_top = 8.0
	_style_active.content_margin_right = 12.0
	_style_active.content_margin_bottom = 8.0
	_style_active.shadow_color = Color(0.92, 0.8, 0.38, 0.2)
	_style_active.shadow_size = 4

func open_modal() -> void:
	_select_opponents(GameSettings.classic_opponents)
	_select_theme(ThemeManager.get_theme())
	show()
	modulate.a = 0.0
	panel.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.18)

func _select_opponents(count: int) -> void:
	selected_opponents = count
	_update_opp_buttons()

func _update_opp_buttons() -> void:
	_apply_button_state(btn_opp_1, selected_opponents == 1)
	_apply_button_state(btn_opp_2, selected_opponents == 2)
	_apply_button_state(btn_opp_3, selected_opponents == 3)

func _select_theme(theme_name: String) -> void:
	selected_theme = theme_name
	ThemeManager.set_theme(theme_name)
	_update_theme_buttons()

func _update_theme_buttons() -> void:
	_apply_button_state(btn_theme_light, selected_theme == "Light")
	_apply_button_state(btn_theme_dark, selected_theme == "Dark")
	_apply_button_state(btn_theme_ginger, selected_theme == "Gingerbread")
	_apply_button_state(btn_theme_hearts, selected_theme == "Hearts")
	_apply_button_state(btn_theme_stars, selected_theme == "Stars")

func _apply_button_state(btn: Button, active: bool) -> void:
	if btn == null or _style_normal == null or _style_active == null:
		return
	if active:
		btn.add_theme_stylebox_override("normal", _style_active)
		btn.add_theme_stylebox_override("hover", _style_active)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		btn.add_theme_stylebox_override("normal", _style_normal)
		btn.add_theme_stylebox_override("hover", _style_normal)
		btn.add_theme_color_override("font_color", Color(0.7, 0.76, 0.82, 0.85))

func _on_start_pressed() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	tween.tween_property(panel, "scale", Vector2(0.95, 0.95), 0.14)
	tween.chain().tween_callback(func():
		hide()
		modulate.a = 1.0
		panel.scale = Vector2.ONE
		setup_confirmed.emit(selected_opponents, selected_theme)
	)
