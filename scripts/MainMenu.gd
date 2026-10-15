class_name MainMenu
extends Control

## Main Menu and Game Mode Selection orchestrator.
## Provides polished navigation between Classic Domino and Domino Solitaire,
## theme customization, and game rules.

# Views
@onready var main_menu_view: Control = $MainMenuView
@onready var mode_select_view: Control = $ModeSelectView

# Main Menu Buttons
@onready var btn_play_game: Button = $MainMenuView/CenterVBox/ButtonsVBox/BtnPlayGame
@onready var btn_quick_classic: Button = $MainMenuView/CenterVBox/ButtonsVBox/BtnQuickClassic
@onready var btn_quick_solitaire: Button = $MainMenuView/CenterVBox/ButtonsVBox/BtnQuickSolitaire
@onready var btn_themes: Button = $MainMenuView/CenterVBox/ButtonsVBox/BtnThemes
@onready var btn_rules: Button = $MainMenuView/CenterVBox/ButtonsVBox/BtnRules
@onready var btn_quit: Button = $MainMenuView/CenterVBox/ButtonsVBox/BtnQuit

# Mode Select Controls
@onready var btn_back_to_menu: Button = $ModeSelectView/TopHBox/BtnBack
@onready var btn_classic_opp1: Button = $ModeSelectView/CardsHBox/ClassicCard/VBox/OpponentsHBox/BtnOpp1
@onready var btn_classic_opp2: Button = $ModeSelectView/CardsHBox/ClassicCard/VBox/OpponentsHBox/BtnOpp2
@onready var btn_classic_opp3: Button = $ModeSelectView/CardsHBox/ClassicCard/VBox/OpponentsHBox/BtnOpp3
@onready var btn_start_classic: Button = $ModeSelectView/CardsHBox/ClassicCard/VBox/BtnStartClassic

@onready var btn_solitaire_draw1: Button = $ModeSelectView/CardsHBox/SolitaireCard/VBox/DrawModeHBox/BtnDraw1
@onready var btn_solitaire_draw3: Button = $ModeSelectView/CardsHBox/SolitaireCard/VBox/DrawModeHBox/BtnDraw3
@onready var btn_card_back_blue: Button = $ModeSelectView/CardsHBox/SolitaireCard/VBox/BackStyleHBox/BtnBackBlue
@onready var btn_card_back_red: Button = $ModeSelectView/CardsHBox/SolitaireCard/VBox/BackStyleHBox/BtnBackRed
@onready var btn_card_back_green: Button = $ModeSelectView/CardsHBox/SolitaireCard/VBox/BackStyleHBox/BtnBackGreen
@onready var btn_start_solitaire: Button = $ModeSelectView/CardsHBox/SolitaireCard/VBox/BtnStartSolitaire

# Themes Modal
@onready var themes_modal: Control = $ThemesModal
@onready var themes_box: PanelContainer = $ThemesModal/Panel
@onready var btn_theme_light: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeLight
@onready var btn_theme_dark: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeDark
@onready var btn_theme_ginger: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeGinger
@onready var btn_theme_hearts: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeHearts
@onready var btn_theme_stars: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeStars
@onready var btn_themes_close: Button = $ThemesModal/Panel/VBox/BtnCloseThemes

# Rules Modal
@onready var rules_modal: Control = $RulesModal
@onready var rules_box: PanelContainer = $RulesModal/Panel
@onready var btn_tab_classic: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabClassic
@onready var btn_tab_solitaire: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabSolitaire
@onready var rules_classic_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentClassic
@onready var rules_solitaire_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentSolitaire
@onready var btn_rules_close: Button = $RulesModal/Panel/VBox/BtnCloseRules

# Ambient floating tiles container
@onready var ambient_tiles_node: Node2D = $AmbientTiles

# Styles
var _style_toggle_normal: StyleBoxFlat
var _style_toggle_active: StyleBoxFlat

func _ready() -> void:
	_init_toggle_styles()
	_setup_signals()
	_update_classic_opponents_ui()
	_update_solitaire_options_ui()
	_update_theme_buttons_ui()
	_setup_ambient_decorations()

	main_menu_view.visible = true
	main_menu_view.modulate.a = 1.0
	mode_select_view.visible = false
	themes_modal.visible = false
	rules_modal.visible = false

	# Hide quit button on web or mobile if running on such platforms
	if OS.has_feature("web") or OS.has_feature("mobile"):
		btn_quit.visible = false

func _init_toggle_styles() -> void:
	_style_toggle_normal = StyleBoxFlat.new()
	_style_toggle_normal.bg_color = Color(0.12, 0.16, 0.2, 0.65)
	_style_toggle_normal.border_width_left = 1
	_style_toggle_normal.border_width_top = 1
	_style_toggle_normal.border_width_right = 1
	_style_toggle_normal.border_width_bottom = 1
	_style_toggle_normal.border_color = Color(1.0, 1.0, 1.0, 0.1)
	_style_toggle_normal.corner_radius_top_left = 7
	_style_toggle_normal.corner_radius_top_right = 7
	_style_toggle_normal.corner_radius_bottom_right = 7
	_style_toggle_normal.corner_radius_bottom_left = 7
	_style_toggle_normal.content_margin_left = 8.0
	_style_toggle_normal.content_margin_top = 6.0
	_style_toggle_normal.content_margin_right = 8.0
	_style_toggle_normal.content_margin_bottom = 6.0

	_style_toggle_active = StyleBoxFlat.new()
	_style_toggle_active.bg_color = Color(0.2, 0.26, 0.32, 0.95)
	_style_toggle_active.border_width_left = 1
	_style_toggle_active.border_width_top = 1
	_style_toggle_active.border_width_right = 1
	_style_toggle_active.border_width_bottom = 1
	_style_toggle_active.border_color = Color(0.92, 0.8, 0.38, 0.95)
	_style_toggle_active.corner_radius_top_left = 7
	_style_toggle_active.corner_radius_top_right = 7
	_style_toggle_active.corner_radius_bottom_right = 7
	_style_toggle_active.corner_radius_bottom_left = 7
	_style_toggle_active.content_margin_left = 8.0
	_style_toggle_active.content_margin_top = 6.0
	_style_toggle_active.content_margin_right = 8.0
	_style_toggle_active.content_margin_bottom = 6.0
	_style_toggle_active.shadow_color = Color(0.92, 0.8, 0.38, 0.25)
	_style_toggle_active.shadow_size = 4

func _setup_signals() -> void:
	# Main Menu Buttons
	btn_play_game.pressed.connect(func(): _switch_view(mode_select_view))
	btn_quick_classic.pressed.connect(_launch_classic)
	btn_quick_solitaire.pressed.connect(_launch_solitaire)
	btn_themes.pressed.connect(_open_themes_modal)
	btn_rules.pressed.connect(_open_rules_modal)
	btn_quit.pressed.connect(func(): get_tree().quit())

	# Mode Select
	btn_back_to_menu.pressed.connect(func(): _switch_view(main_menu_view))

	btn_classic_opp1.pressed.connect(func(): _set_opponents(1))
	btn_classic_opp2.pressed.connect(func(): _set_opponents(2))
	btn_classic_opp3.pressed.connect(func(): _set_opponents(3))
	btn_start_classic.pressed.connect(_launch_classic)

	btn_solitaire_draw1.pressed.connect(func(): _set_solitaire_draw_count(1))
	btn_solitaire_draw3.pressed.connect(func(): _set_solitaire_draw_count(3))
	btn_card_back_blue.pressed.connect(func(): _set_solitaire_card_back("cardBack_blue1.png"))
	btn_card_back_red.pressed.connect(func(): _set_solitaire_card_back("cardBack_red1.png"))
	btn_card_back_green.pressed.connect(func(): _set_solitaire_card_back("cardBack_green1.png"))
	btn_start_solitaire.pressed.connect(_launch_solitaire)

	# Themes Modal
	btn_theme_light.pressed.connect(func(): _select_theme("Light"))
	btn_theme_dark.pressed.connect(func(): _select_theme("Dark"))
	btn_theme_ginger.pressed.connect(func(): _select_theme("Gingerbread"))
	btn_theme_hearts.pressed.connect(func(): _select_theme("Hearts"))
	btn_theme_stars.pressed.connect(func(): _select_theme("Stars"))
	btn_themes_close.pressed.connect(_close_themes_modal)

	# Rules Modal
	btn_tab_classic.pressed.connect(func(): _switch_rules_tab("classic"))
	btn_tab_solitaire.pressed.connect(func(): _switch_rules_tab("solitaire"))
	btn_rules_close.pressed.connect(_close_rules_modal)

func _switch_view(target_view: Control) -> void:
	var from_view: Control = main_menu_view if target_view == mode_select_view else mode_select_view

	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(from_view, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(func():
		from_view.visible = false
		target_view.visible = true
		target_view.modulate.a = 0.0
		var in_tween: Tween = create_tween()
		in_tween.tween_property(target_view, "modulate:a", 1.0, 0.18)
	)

func _set_opponents(count: int) -> void:
	GameSettings.classic_opponents = count
	_update_classic_opponents_ui()

func _update_classic_opponents_ui() -> void:
	_apply_toggle(btn_classic_opp1, GameSettings.classic_opponents == 1)
	_apply_toggle(btn_classic_opp2, GameSettings.classic_opponents == 2)
	_apply_toggle(btn_classic_opp3, GameSettings.classic_opponents == 3)

func _set_solitaire_draw_count(draw_count: int) -> void:
	GameSettings.set_solitaire_draw_count(draw_count)
	_update_solitaire_options_ui()

func _set_solitaire_card_back(back_filename: String) -> void:
	GameSettings.set_card_back(back_filename)
	_update_solitaire_options_ui()

func _update_solitaire_options_ui() -> void:
	_apply_toggle(btn_solitaire_draw1, GameSettings.solitaire_draw_count == 1)
	_apply_toggle(btn_solitaire_draw3, GameSettings.solitaire_draw_count == 3)
	_apply_toggle(btn_card_back_blue, GameSettings.solitaire_card_back.begins_with("cardBack_blue"))
	_apply_toggle(btn_card_back_red, GameSettings.solitaire_card_back.begins_with("cardBack_red"))
	_apply_toggle(btn_card_back_green, GameSettings.solitaire_card_back.begins_with("cardBack_green"))

func _apply_toggle(btn: Button, is_active: bool) -> void:
	if btn == null or _style_toggle_normal == null or _style_toggle_active == null:
		return
	if is_active:
		btn.add_theme_stylebox_override("normal", _style_toggle_active)
		btn.add_theme_stylebox_override("hover", _style_toggle_active)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		btn.add_theme_stylebox_override("normal", _style_toggle_normal)
		btn.add_theme_stylebox_override("hover", _style_toggle_normal)
		btn.add_theme_color_override("font_color", Color(0.7, 0.76, 0.84, 0.85))

func _launch_classic() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _launch_solitaire() -> void:
	get_tree().change_scene_to_file("res://scenes/solitaire.tscn")

# Themes
func _open_themes_modal() -> void:
	_update_theme_buttons_ui()
	themes_modal.visible = true
	themes_modal.modulate.a = 0.0
	themes_box.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(themes_modal, "modulate:a", 1.0, 0.18)
	tween.tween_property(themes_box, "scale", Vector2.ONE, 0.18)

func _close_themes_modal() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(themes_modal, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(func(): themes_modal.visible = false)

func _select_theme(theme_name: String) -> void:
	ThemeManager.set_theme(theme_name)
	_update_theme_buttons_ui()

func _update_theme_buttons_ui() -> void:
	var current: String = ThemeManager.get_theme()
	_apply_toggle(btn_theme_light, current == "Light")
	_apply_toggle(btn_theme_dark, current == "Dark")
	_apply_toggle(btn_theme_ginger, current == "Gingerbread")
	_apply_toggle(btn_theme_hearts, current == "Hearts")
	_apply_toggle(btn_theme_stars, current == "Stars")

# Rules Modal
func _open_rules_modal() -> void:
	_switch_rules_tab("classic")
	rules_modal.visible = true
	rules_modal.modulate.a = 0.0
	rules_box.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(rules_modal, "modulate:a", 1.0, 0.18)
	tween.tween_property(rules_box, "scale", Vector2.ONE, 0.18)

func _close_rules_modal() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(rules_modal, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(func(): rules_modal.visible = false)

func _switch_rules_tab(tab_name: String) -> void:
	if tab_name == "classic":
		_apply_toggle(btn_tab_classic, true)
		_apply_toggle(btn_tab_solitaire, false)
		rules_classic_content.visible = true
		rules_solitaire_content.visible = false
	else:
		_apply_toggle(btn_tab_classic, false)
		_apply_toggle(btn_tab_solitaire, true)
		rules_classic_content.visible = false
		rules_solitaire_content.visible = true

## Setup subtle floating decorative domino tiles in the background
func _setup_ambient_decorations() -> void:
	var tile_coords: Array[Vector2i] = [
		Vector2i(6, 6),
		Vector2i(5, 5),
		Vector2i(6, 4),
		Vector2i(4, 2),
		Vector2i(3, 1),
		Vector2i(0, 0)
	]
	var positions: Array[Vector2] = [
		Vector2(120, 160),
		Vector2(1160, 180),
		Vector2(80, 560),
		Vector2(1180, 540),
		Vector2(240, 360),
		Vector2(1040, 370)
	]
	var rotations: Array[float] = [-0.35, 0.28, 0.42, -0.3, 0.15, -0.2]

	for i in range(mini(tile_coords.size(), positions.size())):
		var spr := Sprite2D.new()
		var tc: Vector2i = tile_coords[i]
		var tex: Texture2D = ThemeManager.get_tile_texture(tc.x, tc.y, "Light")
		if tex != null:
			spr.texture = tex
			spr.position = positions[i]
			spr.rotation = rotations[i]
			spr.scale = Vector2(0.85, 0.85)
			spr.modulate = Color(1.0, 1.0, 1.0, 0.2)
			ambient_tiles_node.add_child(spr)

			# Gentle bobbing tween
			var bob_tween: Tween = create_tween().set_loops()
			var y_offset: float = randf_range(8.0, 16.0)
			var dur: float = randf_range(2.8, 4.2)
			bob_tween.tween_property(spr, "position:y", spr.position.y + y_offset, dur * 0.5).set_trans(Tween.TRANS_SINE)
			bob_tween.tween_property(spr, "position:y", spr.position.y - y_offset, dur * 0.5).set_trans(Tween.TRANS_SINE)
