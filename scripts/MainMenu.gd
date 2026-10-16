class_name MainMenu
extends Control

const HanafudaCardData = preload("res://scripts/HanafudaCardData.gd")

## Main Menu and Game Mode Selection orchestrator.
## Provides polished navigation between Classic Domino, Domino Solitaire,
## Texas Hold'em Poker, and Gin Rummy, plus theme customization and game rules.
## NOTE FOR DEVELOPERS: NEVER ADD EMOJIS TO UI STRINGS/LABELS!
## Web export does not bundle emoji fonts and shows ugly binary hex boxes instead.

# Views
@onready var main_menu_view: Control = $MainMenuView
@onready var mode_select_view: Control = $ModeSelectView

# Main Menu Buttons
@onready var btn_play_game: Button = $MainMenuView/CenterVBox/ButtonsVBox/BtnPlayGame
@onready var btn_themes: Button = $MainMenuView/CenterVBox/ButtonsVBox/SecondaryHBox/BtnThemes
@onready var btn_rules: Button = $MainMenuView/CenterVBox/ButtonsVBox/SecondaryHBox/BtnRules
@onready var btn_quit: Button = $MainMenuView/CenterVBox/ButtonsVBox/BtnQuit

# Backward compatibility / fallback getters
var btn_quick_classic: Button:
	get: return null
var btn_quick_solitaire: Button:
	get: return null
var btn_quick_holdem: Button:
	get: return null

# Mode Select Controls
@onready var btn_back_to_menu: Button = $ModeSelectView/TopHBox/BtnBack
@onready var cards_scroll: ScrollContainer = $ModeSelectView/CardsScroll
@onready var cards_hbox: HBoxContainer = $ModeSelectView/CardsScroll/CardsHBox
@onready var btn_scroll_left: Button = $ModeSelectView/BtnScrollLeft
@onready var btn_scroll_right: Button = $ModeSelectView/BtnScrollRight

@onready var btn_cat_all: Button = $ModeSelectView/CategoryHBox/BtnCatAll
@onready var btn_cat_domino: Button = $ModeSelectView/CategoryHBox/BtnCatDomino
@onready var btn_cat_solitaire: Button = $ModeSelectView/CategoryHBox/BtnCatSolitaire
@onready var btn_cat_cards: Button = $ModeSelectView/CategoryHBox/BtnCatCards

@onready var btn_quick_themes: Button = $ModeSelectView/TopHBox/RightHBox/BtnThemesQuick
@onready var btn_quick_rules: Button = $ModeSelectView/TopHBox/RightHBox/BtnRulesQuick
var btn_themes_quick: Button:
	get: return btn_quick_themes
var btn_rules_quick: Button:
	get: return btn_quick_rules

@onready var card_classic: PanelContainer = $ModeSelectView/CardsScroll/CardsHBox/ClassicCard
@onready var card_sebastopol: PanelContainer = $ModeSelectView/CardsScroll/CardsHBox/SebastopolCard
@onready var card_solitaire: PanelContainer = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard
@onready var card_pyramid: PanelContainer = $ModeSelectView/CardsScroll/CardsHBox/PyramidCard
@onready var card_tripeaks: PanelContainer = $ModeSelectView/CardsScroll/CardsHBox/TriPeaksCard
@onready var card_holdem: PanelContainer = $ModeSelectView/CardsScroll/CardsHBox/HoldemCard
@onready var card_gin_rummy: PanelContainer = $ModeSelectView/CardsScroll/CardsHBox/GinRummyCard
@onready var card_koikoi: PanelContainer = $ModeSelectView/CardsScroll/CardsHBox/KoiKoiCard

var current_category: String = "all"

# Classic Domino controls
@onready var btn_classic_opp1: Button = $ModeSelectView/CardsScroll/CardsHBox/ClassicCard/VBox/OpponentsHBox/BtnOpp1
@onready var btn_classic_opp2: Button = $ModeSelectView/CardsScroll/CardsHBox/ClassicCard/VBox/OpponentsHBox/BtnOpp2
@onready var btn_classic_opp3: Button = $ModeSelectView/CardsScroll/CardsHBox/ClassicCard/VBox/OpponentsHBox/BtnOpp3
@onready var btn_start_classic: Button = $ModeSelectView/CardsScroll/CardsHBox/ClassicCard/VBox/BtnStartClassic

# Sebastopol Domino controls
@onready var btn_sebastopol_opp1: Button = $ModeSelectView/CardsScroll/CardsHBox/SebastopolCard/VBox/OpponentsHBox/BtnOpp1
@onready var btn_sebastopol_opp2: Button = $ModeSelectView/CardsScroll/CardsHBox/SebastopolCard/VBox/OpponentsHBox/BtnOpp2
@onready var btn_sebastopol_opp3: Button = $ModeSelectView/CardsScroll/CardsHBox/SebastopolCard/VBox/OpponentsHBox/BtnOpp3
@onready var btn_sebastopol_target_50: Button = $ModeSelectView/CardsScroll/CardsHBox/SebastopolCard/VBox/TargetHBox/BtnTarget50
@onready var btn_sebastopol_target_100: Button = $ModeSelectView/CardsScroll/CardsHBox/SebastopolCard/VBox/TargetHBox/BtnTarget100
@onready var btn_sebastopol_target_150: Button = $ModeSelectView/CardsScroll/CardsHBox/SebastopolCard/VBox/TargetHBox/BtnTarget150
@onready var btn_start_sebastopol: Button = $ModeSelectView/CardsScroll/CardsHBox/SebastopolCard/VBox/BtnStartSebastopol

# Solitaire controls
@onready var btn_solitaire_winnable: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/DealTypeHBox/BtnWinnable
@onready var btn_solitaire_random: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/DealTypeHBox/BtnRandom
@onready var btn_solitaire_diff_easy: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/DifficultyHBox/BtnEasy
@onready var btn_solitaire_diff_standard: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/DifficultyHBox/BtnStandard
@onready var btn_solitaire_draw1: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/DrawModeHBox/BtnDraw1
@onready var btn_solitaire_draw3: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/DrawModeHBox/BtnDraw3
@onready var btn_card_back_blue: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/BackStyleHBox/BtnBackBlue
@onready var btn_card_back_red: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/BackStyleHBox/BtnBackRed
@onready var btn_card_back_green: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/BackStyleHBox/BtnBackGreen
@onready var btn_start_solitaire: Button = $ModeSelectView/CardsScroll/CardsHBox/SolitaireCard/VBox/BtnStartSolitaire

# Pyramid Solitaire controls
@onready var btn_pyramid_pass1: Button = $ModeSelectView/CardsScroll/CardsHBox/PyramidCard/VBox/PassesHBox/BtnPass1
@onready var btn_pyramid_pass3: Button = $ModeSelectView/CardsScroll/CardsHBox/PyramidCard/VBox/PassesHBox/BtnPass3
@onready var btn_pyramid_pass_inf: Button = $ModeSelectView/CardsScroll/CardsHBox/PyramidCard/VBox/PassesHBox/BtnPassInf
@onready var btn_start_pyramid: Button = $ModeSelectView/CardsScroll/CardsHBox/PyramidCard/VBox/BtnStartPyramid

# Tri Peaks Solitaire controls
@onready var btn_tripeaks_pass1: Button = $ModeSelectView/CardsScroll/CardsHBox/TriPeaksCard/VBox/PassesHBox/BtnPass1
@onready var btn_tripeaks_pass3: Button = $ModeSelectView/CardsScroll/CardsHBox/TriPeaksCard/VBox/PassesHBox/BtnPass3
@onready var btn_tripeaks_pass_inf: Button = $ModeSelectView/CardsScroll/CardsHBox/TriPeaksCard/VBox/PassesHBox/BtnPassInf
@onready var btn_start_tripeaks: Button = $ModeSelectView/CardsScroll/CardsHBox/TriPeaksCard/VBox/BtnStartTriPeaks

# Texas Hold'em controls
@onready var btn_holdem_opp1: Button = $ModeSelectView/CardsScroll/CardsHBox/HoldemCard/VBox/HoldemOppHBox/BtnHoldemOpp1
@onready var btn_holdem_opp2: Button = $ModeSelectView/CardsScroll/CardsHBox/HoldemCard/VBox/HoldemOppHBox/BtnHoldemOpp2
@onready var btn_holdem_opp3: Button = $ModeSelectView/CardsScroll/CardsHBox/HoldemCard/VBox/HoldemOppHBox/BtnHoldemOpp3
@onready var btn_chips_500: Button = $ModeSelectView/CardsScroll/CardsHBox/HoldemCard/VBox/ChipsHBox/BtnChips500
@onready var btn_chips_1000: Button = $ModeSelectView/CardsScroll/CardsHBox/HoldemCard/VBox/ChipsHBox/BtnChips1000
@onready var btn_chips_2000: Button = $ModeSelectView/CardsScroll/CardsHBox/HoldemCard/VBox/ChipsHBox/BtnChips2000
@onready var btn_start_holdem: Button = $ModeSelectView/CardsScroll/CardsHBox/HoldemCard/VBox/BtnStartHoldem

# Gin Rummy controls
@onready var btn_gin_target_50: Button = $ModeSelectView/CardsScroll/CardsHBox/GinRummyCard/VBox/TargetHBox/BtnTarget50
@onready var btn_gin_target_100: Button = $ModeSelectView/CardsScroll/CardsHBox/GinRummyCard/VBox/TargetHBox/BtnTarget100
@onready var btn_gin_target_150: Button = $ModeSelectView/CardsScroll/CardsHBox/GinRummyCard/VBox/TargetHBox/BtnTarget150
@onready var btn_gin_ai_normal: Button = $ModeSelectView/CardsScroll/CardsHBox/GinRummyCard/VBox/AIStyleHBox/BtnAINormal
@onready var btn_gin_ai_sharp: Button = $ModeSelectView/CardsScroll/CardsHBox/GinRummyCard/VBox/AIStyleHBox/BtnAISharp
@onready var btn_start_gin_rummy: Button = $ModeSelectView/CardsScroll/CardsHBox/GinRummyCard/VBox/BtnStartGinRummy

# Koi-Koi controls
@onready var btn_koikoi_rounds3: Button = $ModeSelectView/CardsScroll/CardsHBox/KoiKoiCard/VBox/RoundsHBox/BtnRounds3
@onready var btn_koikoi_rounds6: Button = $ModeSelectView/CardsScroll/CardsHBox/KoiKoiCard/VBox/RoundsHBox/BtnRounds6
@onready var btn_koikoi_rounds12: Button = $ModeSelectView/CardsScroll/CardsHBox/KoiKoiCard/VBox/RoundsHBox/BtnRounds12
@onready var btn_koikoi_ai_normal: Button = $ModeSelectView/CardsScroll/CardsHBox/KoiKoiCard/VBox/AIStyleHBox/BtnKoiKoiAINormal
@onready var btn_koikoi_ai_sharp: Button = $ModeSelectView/CardsScroll/CardsHBox/KoiKoiCard/VBox/AIStyleHBox/BtnKoiKoiAISharp
@onready var btn_start_koikoi: Button = $ModeSelectView/CardsScroll/CardsHBox/KoiKoiCard/VBox/BtnStartKoiKoi

# Themes Modal
@onready var themes_modal: Control = $ThemesModal
@onready var themes_box: PanelContainer = $ThemesModal/Panel
@onready var btn_theme_light: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeLight
@onready var btn_theme_dark: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeDark
@onready var btn_theme_ginger: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeGinger
@onready var btn_theme_hearts: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeHearts
@onready var btn_theme_stars: Button = $ThemesModal/Panel/VBox/Grid/BtnThemeStars
@onready var btn_themes_close: Button = $ThemesModal/Panel/VBox/BtnCloseThemes
var btn_close_themes: Button:
	get: return btn_themes_close

# Rules Modal
@onready var rules_modal: Control = $RulesModal
@onready var rules_box: PanelContainer = $RulesModal/Panel
@onready var btn_tab_classic: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabClassic
@onready var btn_tab_sebastopol: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabSebastopol
@onready var btn_tab_solitaire: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabSolitaire
@onready var btn_tab_pyramid: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabPyramid
@onready var btn_tab_tripeaks: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabTriPeaks
@onready var btn_tab_holdem: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabHoldem
@onready var btn_tab_gin_rummy: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabGinRummy
@onready var btn_tab_koikoi: Button = $RulesModal/Panel/VBox/TabsHBox/BtnTabKoiKoi
@onready var rules_classic_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentClassic
@onready var rules_sebastopol_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentSebastopol
@onready var rules_solitaire_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentSolitaire
@onready var rules_pyramid_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentPyramid
@onready var rules_tripeaks_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentTriPeaks
@onready var rules_holdem_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentHoldem
@onready var rules_gin_rummy_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentGinRummy
@onready var rules_koikoi_content: VBoxContainer = $RulesModal/Panel/VBox/ScrollContainer/ContentKoiKoi
@onready var btn_rules_close: Button = $RulesModal/Panel/VBox/BtnCloseRules
var btn_close_rules: Button:
	get: return btn_rules_close

# Ambient floating tiles container
@onready var ambient_tiles_node: Node2D = $AmbientTiles

# Styles
var _style_toggle_normal: StyleBoxFlat
var _style_toggle_active: StyleBoxFlat
var _style_toggle_hover: StyleBoxFlat
var _style_cat_normal: StyleBoxFlat
var _style_cat_active: StyleBoxFlat
var _style_cat_hover: StyleBoxFlat

func _ready() -> void:
	_init_toggle_styles()
	_setup_signals()
	_setup_card_banners()
	_setup_card_hover_effects()
	_filter_game_category("all")
	_update_classic_opponents_ui()
	_update_sebastopol_options_ui()
	_update_solitaire_options_ui()
	_update_pyramid_options_ui()
	_update_tripeaks_options_ui()
	_update_holdem_options_ui()
	_update_gin_options_ui()
	_update_koikoi_options_ui()
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
	_style_toggle_normal.bg_color = Color(0.1, 0.14, 0.19, 0.75)
	_style_toggle_normal.border_width_left = 1
	_style_toggle_normal.border_width_top = 1
	_style_toggle_normal.border_width_right = 1
	_style_toggle_normal.border_width_bottom = 1
	_style_toggle_normal.border_color = Color(1.0, 1.0, 1.0, 0.12)
	_style_toggle_normal.corner_radius_top_left = 7
	_style_toggle_normal.corner_radius_top_right = 7
	_style_toggle_normal.corner_radius_bottom_right = 7
	_style_toggle_normal.corner_radius_bottom_left = 7
	_style_toggle_normal.content_margin_left = 8.0
	_style_toggle_normal.content_margin_top = 6.0
	_style_toggle_normal.content_margin_right = 8.0
	_style_toggle_normal.content_margin_bottom = 6.0

	_style_toggle_hover = StyleBoxFlat.new()
	_style_toggle_hover.bg_color = Color(0.16, 0.22, 0.3, 0.9)
	_style_toggle_hover.border_width_left = 1
	_style_toggle_hover.border_width_top = 1
	_style_toggle_hover.border_width_right = 1
	_style_toggle_hover.border_width_bottom = 1
	_style_toggle_hover.border_color = Color(1.0, 1.0, 1.0, 0.25)
	_style_toggle_hover.corner_radius_top_left = 7
	_style_toggle_hover.corner_radius_top_right = 7
	_style_toggle_hover.corner_radius_bottom_right = 7
	_style_toggle_hover.corner_radius_bottom_left = 7
	_style_toggle_hover.content_margin_left = 8.0
	_style_toggle_hover.content_margin_top = 6.0
	_style_toggle_hover.content_margin_right = 8.0
	_style_toggle_hover.content_margin_bottom = 6.0

	_style_toggle_active = StyleBoxFlat.new()
	_style_toggle_active.bg_color = Color(0.92, 0.8, 0.38, 0.22)
	_style_toggle_active.border_width_left = 1
	_style_toggle_active.border_width_top = 1
	_style_toggle_active.border_width_right = 1
	_style_toggle_active.border_width_bottom = 1
	_style_toggle_active.border_color = Color(0.96, 0.84, 0.42, 1.0)
	_style_toggle_active.corner_radius_top_left = 7
	_style_toggle_active.corner_radius_top_right = 7
	_style_toggle_active.corner_radius_bottom_right = 7
	_style_toggle_active.corner_radius_bottom_left = 7
	_style_toggle_active.content_margin_left = 8.0
	_style_toggle_active.content_margin_top = 6.0
	_style_toggle_active.content_margin_right = 8.0
	_style_toggle_active.content_margin_bottom = 6.0
	_style_toggle_active.shadow_color = Color(0.92, 0.8, 0.38, 0.3)
	_style_toggle_active.shadow_size = 5

	_style_cat_normal = StyleBoxFlat.new()
	_style_cat_normal.bg_color = Color(0.1, 0.14, 0.2, 0.75)
	_style_cat_normal.border_width_left = 1
	_style_cat_normal.border_width_top = 1
	_style_cat_normal.border_width_right = 1
	_style_cat_normal.border_width_bottom = 1
	_style_cat_normal.border_color = Color(1.0, 1.0, 1.0, 0.12)
	_style_cat_normal.corner_radius_top_left = 16
	_style_cat_normal.corner_radius_top_right = 16
	_style_cat_normal.corner_radius_bottom_right = 16
	_style_cat_normal.corner_radius_bottom_left = 16
	_style_cat_normal.content_margin_left = 14.0
	_style_cat_normal.content_margin_top = 7.0
	_style_cat_normal.content_margin_right = 14.0
	_style_cat_normal.content_margin_bottom = 7.0

	_style_cat_hover = StyleBoxFlat.new()
	_style_cat_hover.bg_color = Color(0.18, 0.24, 0.32, 0.92)
	_style_cat_hover.border_width_left = 1
	_style_cat_hover.border_width_top = 1
	_style_cat_hover.border_width_right = 1
	_style_cat_hover.border_width_bottom = 1
	_style_cat_hover.border_color = Color(1.0, 1.0, 1.0, 0.25)
	_style_cat_hover.corner_radius_top_left = 16
	_style_cat_hover.corner_radius_top_right = 16
	_style_cat_hover.corner_radius_bottom_right = 16
	_style_cat_hover.corner_radius_bottom_left = 16
	_style_cat_hover.content_margin_left = 14.0
	_style_cat_hover.content_margin_top = 7.0
	_style_cat_hover.content_margin_right = 14.0
	_style_cat_hover.content_margin_bottom = 7.0

	_style_cat_active = StyleBoxFlat.new()
	_style_cat_active.bg_color = Color(0.92, 0.8, 0.38, 1.0)
	_style_cat_active.border_width_left = 1
	_style_cat_active.border_width_top = 1
	_style_cat_active.border_width_right = 1
	_style_cat_active.border_width_bottom = 1
	_style_cat_active.border_color = Color(1.0, 0.94, 0.65, 0.95)
	_style_cat_active.corner_radius_top_left = 16
	_style_cat_active.corner_radius_top_right = 16
	_style_cat_active.corner_radius_bottom_right = 16
	_style_cat_active.corner_radius_bottom_left = 16
	_style_cat_active.content_margin_left = 14.0
	_style_cat_active.content_margin_top = 7.0
	_style_cat_active.content_margin_right = 14.0
	_style_cat_active.content_margin_bottom = 7.0
	_style_cat_active.shadow_color = Color(0.92, 0.8, 0.38, 0.35)
	_style_cat_active.shadow_size = 6

func _setup_signals() -> void:
	# Main Menu Buttons - Click PLAY to show game modes!
	btn_play_game.pressed.connect(func(): _switch_view(mode_select_view))
	btn_themes.pressed.connect(_open_themes_modal)
	btn_rules.pressed.connect(_open_rules_modal)
	btn_quit.pressed.connect(func(): get_tree().quit())

	# Mode Select Navigation
	btn_back_to_menu.pressed.connect(func(): _switch_view(main_menu_view))

	# Category Filter Buttons
	btn_cat_all.pressed.connect(func(): _filter_game_category("all"))
	btn_cat_domino.pressed.connect(func(): _filter_game_category("domino"))
	btn_cat_solitaire.pressed.connect(func(): _filter_game_category("solitaire"))
	btn_cat_cards.pressed.connect(func(): _filter_game_category("cards"))

	# Carousel navigation buttons
	btn_scroll_left.pressed.connect(_scroll_cards_left)
	btn_scroll_right.pressed.connect(_scroll_cards_right)

	# Quick Header Buttons
	btn_quick_themes.pressed.connect(_open_themes_modal)
	btn_quick_rules.pressed.connect(_open_rules_modal)

	# Classic Domino controls
	btn_classic_opp1.pressed.connect(func(): _set_opponents(1))
	btn_classic_opp2.pressed.connect(func(): _set_opponents(2))
	btn_classic_opp3.pressed.connect(func(): _set_opponents(3))
	btn_start_classic.pressed.connect(_launch_classic)

	# Sebastopol Domino controls
	btn_sebastopol_opp1.pressed.connect(func(): _set_sebastopol_opponents(1))
	btn_sebastopol_opp2.pressed.connect(func(): _set_sebastopol_opponents(2))
	btn_sebastopol_opp3.pressed.connect(func(): _set_sebastopol_opponents(3))
	btn_sebastopol_target_50.pressed.connect(func(): _set_sebastopol_target(50))
	btn_sebastopol_target_100.pressed.connect(func(): _set_sebastopol_target(100))
	btn_sebastopol_target_150.pressed.connect(func(): _set_sebastopol_target(150))
	btn_start_sebastopol.pressed.connect(_launch_sebastopol)

	# Solitaire controls
	btn_solitaire_winnable.pressed.connect(func(): _set_solitaire_deal_type("Winnable"))
	btn_solitaire_random.pressed.connect(func(): _set_solitaire_deal_type("Random"))
	btn_solitaire_diff_easy.pressed.connect(func(): _set_solitaire_difficulty("Easy"))
	btn_solitaire_diff_standard.pressed.connect(func(): _set_solitaire_difficulty("Standard"))
	btn_solitaire_draw1.pressed.connect(func(): _set_solitaire_draw_count(1))
	btn_solitaire_draw3.pressed.connect(func(): _set_solitaire_draw_count(3))
	btn_card_back_blue.pressed.connect(func(): _set_solitaire_card_back("cardBack_blue1.png"))
	btn_card_back_red.pressed.connect(func(): _set_solitaire_card_back("cardBack_red1.png"))
	btn_card_back_green.pressed.connect(func(): _set_solitaire_card_back("cardBack_green1.png"))
	btn_start_solitaire.pressed.connect(_launch_solitaire)

	# Pyramid Solitaire controls
	btn_pyramid_pass1.pressed.connect(func(): _set_pyramid_passes(1))
	btn_pyramid_pass3.pressed.connect(func(): _set_pyramid_passes(3))
	btn_pyramid_pass_inf.pressed.connect(func(): _set_pyramid_passes(999))
	btn_start_pyramid.pressed.connect(_launch_pyramid)

	# Tri Peaks Solitaire controls
	btn_tripeaks_pass1.pressed.connect(func(): _set_tripeaks_passes(1))
	btn_tripeaks_pass3.pressed.connect(func(): _set_tripeaks_passes(3))
	btn_tripeaks_pass_inf.pressed.connect(func(): _set_tripeaks_passes(999))
	btn_start_tripeaks.pressed.connect(_launch_tripeaks)

	# Texas Hold'em controls
	btn_holdem_opp1.pressed.connect(func(): _set_holdem_opponents(1))
	btn_holdem_opp2.pressed.connect(func(): _set_holdem_opponents(2))
	btn_holdem_opp3.pressed.connect(func(): _set_holdem_opponents(3))
	btn_chips_500.pressed.connect(func(): _set_holdem_chips(500))
	btn_chips_1000.pressed.connect(func(): _set_holdem_chips(1000))
	btn_chips_2000.pressed.connect(func(): _set_holdem_chips(2000))
	btn_start_holdem.pressed.connect(_launch_holdem)

	# Gin Rummy controls
	btn_gin_target_50.pressed.connect(func(): _set_gin_target(50))
	btn_gin_target_100.pressed.connect(func(): _set_gin_target(100))
	btn_gin_target_150.pressed.connect(func(): _set_gin_target(150))
	btn_gin_ai_normal.pressed.connect(func(): _set_gin_ai_difficulty("Normal"))
	btn_gin_ai_sharp.pressed.connect(func(): _set_gin_ai_difficulty("Sharp"))
	btn_start_gin_rummy.pressed.connect(_launch_gin_rummy)

	# Koi-Koi controls
	btn_koikoi_rounds3.pressed.connect(func(): _set_koikoi_rounds(3))
	btn_koikoi_rounds6.pressed.connect(func(): _set_koikoi_rounds(6))
	btn_koikoi_rounds12.pressed.connect(func(): _set_koikoi_rounds(12))
	btn_koikoi_ai_normal.pressed.connect(func(): _set_koikoi_ai_difficulty("Normal"))
	btn_koikoi_ai_sharp.pressed.connect(func(): _set_koikoi_ai_difficulty("Sharp"))
	btn_start_koikoi.pressed.connect(_launch_koikoi)

	# Themes Modal
	btn_theme_light.pressed.connect(func(): _select_theme("Light"))
	btn_theme_dark.pressed.connect(func(): _select_theme("Dark"))
	btn_theme_ginger.pressed.connect(func(): _select_theme("Gingerbread"))
	btn_theme_hearts.pressed.connect(func(): _select_theme("Hearts"))
	btn_theme_stars.pressed.connect(func(): _select_theme("Stars"))
	btn_themes_close.pressed.connect(_close_themes_modal)

	# Rules Modal
	btn_tab_classic.pressed.connect(func(): _switch_rules_tab("classic"))
	btn_tab_sebastopol.pressed.connect(func(): _switch_rules_tab("sebastopol"))
	btn_tab_solitaire.pressed.connect(func(): _switch_rules_tab("solitaire"))
	btn_tab_pyramid.pressed.connect(func(): _switch_rules_tab("pyramid"))
	btn_tab_tripeaks.pressed.connect(func(): _switch_rules_tab("tripeaks"))
	btn_tab_holdem.pressed.connect(func(): _switch_rules_tab("holdem"))
	btn_tab_gin_rummy.pressed.connect(func(): _switch_rules_tab("gin_rummy"))
	btn_tab_koikoi.pressed.connect(func(): _switch_rules_tab("koikoi"))
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

func _set_solitaire_deal_type(deal_type: String) -> void:
	GameSettings.set_solitaire_deal_type(deal_type)
	_update_solitaire_options_ui()

func _set_solitaire_difficulty(diff: String) -> void:
	GameSettings.set_solitaire_difficulty(diff)
	_update_solitaire_options_ui()

func _set_solitaire_draw_count(draw_count: int) -> void:
	GameSettings.set_solitaire_draw_count(draw_count)
	_update_solitaire_options_ui()

func _set_solitaire_card_back(back_filename: String) -> void:
	GameSettings.set_card_back(back_filename)
	_update_solitaire_options_ui()
	_build_solitaire_banner()

func _update_solitaire_options_ui() -> void:
	_apply_toggle(btn_solitaire_winnable, GameSettings.solitaire_deal_type == "Winnable")
	_apply_toggle(btn_solitaire_random, GameSettings.solitaire_deal_type == "Random")
	_apply_toggle(btn_solitaire_diff_easy, GameSettings.solitaire_difficulty == "Easy")
	_apply_toggle(btn_solitaire_diff_standard, GameSettings.solitaire_difficulty == "Standard")
	_apply_toggle(btn_solitaire_draw1, GameSettings.solitaire_draw_count == 1)
	_apply_toggle(btn_solitaire_draw3, GameSettings.solitaire_draw_count == 3)
	_apply_toggle(btn_card_back_blue, GameSettings.solitaire_card_back.begins_with("cardBack_blue"))
	_apply_toggle(btn_card_back_red, GameSettings.solitaire_card_back.begins_with("cardBack_red"))
	_apply_toggle(btn_card_back_green, GameSettings.solitaire_card_back.begins_with("cardBack_green"))

func _set_pyramid_passes(passes: int) -> void:
	GameSettings.set_pyramid_passes(passes)
	_update_pyramid_options_ui()

func _update_pyramid_options_ui() -> void:
	_apply_toggle(btn_pyramid_pass1, GameSettings.pyramid_passes == 1)
	_apply_toggle(btn_pyramid_pass3, GameSettings.pyramid_passes == 3)
	_apply_toggle(btn_pyramid_pass_inf, GameSettings.pyramid_passes >= 900)

func _set_tripeaks_passes(passes: int) -> void:
	GameSettings.set_tripeaks_passes(passes)
	_update_tripeaks_options_ui()

func _update_tripeaks_options_ui() -> void:
	_apply_toggle(btn_tripeaks_pass1, GameSettings.tripeaks_passes == 1)
	_apply_toggle(btn_tripeaks_pass3, GameSettings.tripeaks_passes == 3)
	_apply_toggle(btn_tripeaks_pass_inf, GameSettings.tripeaks_passes >= 900)

func _set_holdem_opponents(count: int) -> void:
	GameSettings.set_holdem_opponents(count)
	_update_holdem_options_ui()

func _set_holdem_chips(chips: int) -> void:
	GameSettings.set_holdem_starting_chips(chips)
	_update_holdem_options_ui()

func _update_holdem_options_ui() -> void:
	_apply_toggle(btn_holdem_opp1, GameSettings.holdem_opponents == 1)
	_apply_toggle(btn_holdem_opp2, GameSettings.holdem_opponents == 2)
	_apply_toggle(btn_holdem_opp3, GameSettings.holdem_opponents == 3)
	_apply_toggle(btn_chips_500, GameSettings.holdem_starting_chips == 500)
	_apply_toggle(btn_chips_1000, GameSettings.holdem_starting_chips == 1000)
	_apply_toggle(btn_chips_2000, GameSettings.holdem_starting_chips == 2000)

func _set_gin_target(target: int) -> void:
	GameSettings.set_gin_match_target(target)
	_update_gin_options_ui()

func _set_gin_ai_difficulty(diff: String) -> void:
	GameSettings.set_gin_ai_difficulty(diff)
	_update_gin_options_ui()

func _update_gin_options_ui() -> void:
	_apply_toggle(btn_gin_target_50, GameSettings.gin_match_target == 50)
	_apply_toggle(btn_gin_target_100, GameSettings.gin_match_target == 100)
	_apply_toggle(btn_gin_target_150, GameSettings.gin_match_target == 150)
	_apply_toggle(btn_gin_ai_normal, GameSettings.gin_ai_difficulty == "Normal")
	_apply_toggle(btn_gin_ai_sharp, GameSettings.gin_ai_difficulty == "Sharp")

func _set_koikoi_rounds(rounds: int) -> void:
	GameSettings.set_koikoi_rounds(rounds)
	_update_koikoi_options_ui()

func _set_koikoi_ai_difficulty(diff: String) -> void:
	GameSettings.set_koikoi_ai_difficulty(diff)
	_update_koikoi_options_ui()

func _update_koikoi_options_ui() -> void:
	_apply_toggle(btn_koikoi_rounds3, GameSettings.koikoi_rounds == 3)
	_apply_toggle(btn_koikoi_rounds6, GameSettings.koikoi_rounds == 6)
	_apply_toggle(btn_koikoi_rounds12, GameSettings.koikoi_rounds == 12)
	_apply_toggle(btn_koikoi_ai_normal, GameSettings.koikoi_ai_difficulty == "Normal")
	_apply_toggle(btn_koikoi_ai_sharp, GameSettings.koikoi_ai_difficulty == "Sharp")

func _apply_toggle(btn: Button, is_active: bool) -> void:
	if btn == null or _style_toggle_normal == null or _style_toggle_active == null:
		return
	if is_active:
		btn.add_theme_stylebox_override("normal", _style_toggle_active)
		btn.add_theme_stylebox_override("hover", _style_toggle_active)
		btn.add_theme_stylebox_override("pressed", _style_toggle_active)
		btn.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72, 1.0))
	else:
		btn.add_theme_stylebox_override("normal", _style_toggle_normal)
		btn.add_theme_stylebox_override("hover", _style_toggle_hover if _style_toggle_hover != null else _style_toggle_normal)
		btn.add_theme_stylebox_override("pressed", _style_toggle_normal)
		btn.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86, 0.85))

func _set_sebastopol_opponents(count: int) -> void:
	GameSettings.set_sebastopol_opponents(count)
	_update_sebastopol_options_ui()

func _set_sebastopol_target(target: int) -> void:
	GameSettings.set_sebastopol_match_target(target)
	_update_sebastopol_options_ui()

func _update_sebastopol_options_ui() -> void:
	_apply_toggle(btn_sebastopol_opp1, GameSettings.sebastopol_opponents == 1)
	_apply_toggle(btn_sebastopol_opp2, GameSettings.sebastopol_opponents == 2)
	_apply_toggle(btn_sebastopol_opp3, GameSettings.sebastopol_opponents == 3)
	_apply_toggle(btn_sebastopol_target_50, GameSettings.sebastopol_match_target == 50)
	_apply_toggle(btn_sebastopol_target_100, GameSettings.sebastopol_match_target == 100)
	_apply_toggle(btn_sebastopol_target_150, GameSettings.sebastopol_match_target == 150)

func _launch_classic() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _launch_sebastopol() -> void:
	get_tree().change_scene_to_file("res://scenes/sebastopol.tscn")

func _launch_solitaire() -> void:
	get_tree().change_scene_to_file("res://scenes/solitaire.tscn")

func _launch_pyramid() -> void:
	get_tree().change_scene_to_file("res://scenes/pyramid_solitaire.tscn")

func _launch_tripeaks() -> void:
	get_tree().change_scene_to_file("res://scenes/tri_peaks_solitaire.tscn")

func _launch_holdem() -> void:
	get_tree().change_scene_to_file("res://scenes/holdem.tscn")

func _launch_gin_rummy() -> void:
	get_tree().change_scene_to_file("res://scenes/gin_rummy.tscn")

func _launch_koikoi() -> void:
	get_tree().change_scene_to_file("res://scenes/koi_koi.tscn")

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
	_build_classic_banner()
	_build_sebastopol_banner()

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
	_apply_toggle(btn_tab_classic, tab_name == "classic")
	_apply_toggle(btn_tab_sebastopol, tab_name == "sebastopol")
	_apply_toggle(btn_tab_solitaire, tab_name == "solitaire")
	_apply_toggle(btn_tab_pyramid, tab_name == "pyramid")
	_apply_toggle(btn_tab_tripeaks, tab_name == "tripeaks")
	_apply_toggle(btn_tab_holdem, tab_name == "holdem")
	_apply_toggle(btn_tab_gin_rummy, tab_name == "gin_rummy")
	_apply_toggle(btn_tab_koikoi, tab_name == "koikoi")
	rules_classic_content.visible = (tab_name == "classic")
	rules_sebastopol_content.visible = (tab_name == "sebastopol")
	rules_solitaire_content.visible = (tab_name == "solitaire")
	rules_pyramid_content.visible = (tab_name == "pyramid")
	rules_tripeaks_content.visible = (tab_name == "tripeaks")
	rules_holdem_content.visible = (tab_name == "holdem")
	rules_gin_rummy_content.visible = (tab_name == "gin_rummy")
	rules_koikoi_content.visible = (tab_name == "koikoi")

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

# Category Filtering & Navigation
func _filter_game_category(cat: String) -> void:
	current_category = cat
	_apply_category_button_styles()

	if cards_scroll != null:
		cards_scroll.scroll_horizontal = 0

	match cat:
		"all":
			card_classic.visible = true
			card_sebastopol.visible = true
			card_solitaire.visible = true
			card_pyramid.visible = true
			card_tripeaks.visible = true
			card_holdem.visible = true
			card_gin_rummy.visible = true
			card_koikoi.visible = true
			btn_scroll_left.visible = true
			btn_scroll_right.visible = true
		"domino":
			card_classic.visible = true
			card_sebastopol.visible = true
			card_solitaire.visible = false
			card_pyramid.visible = false
			card_tripeaks.visible = false
			card_holdem.visible = false
			card_gin_rummy.visible = false
			card_koikoi.visible = false
			btn_scroll_left.visible = false
			btn_scroll_right.visible = false
		"solitaire":
			card_classic.visible = false
			card_sebastopol.visible = false
			card_solitaire.visible = true
			card_pyramid.visible = true
			card_tripeaks.visible = true
			card_holdem.visible = false
			card_gin_rummy.visible = false
			card_koikoi.visible = false
			btn_scroll_left.visible = false
			btn_scroll_right.visible = false
		"cards":
			card_classic.visible = false
			card_sebastopol.visible = false
			card_solitaire.visible = false
			card_pyramid.visible = false
			card_tripeaks.visible = false
			card_holdem.visible = true
			card_gin_rummy.visible = true
			card_koikoi.visible = true
			btn_scroll_left.visible = false
			btn_scroll_right.visible = false

func _apply_category_button_styles() -> void:
	_apply_cat_button(btn_cat_all, current_category == "all")
	_apply_cat_button(btn_cat_domino, current_category == "domino")
	_apply_cat_button(btn_cat_solitaire, current_category == "solitaire")
	_apply_cat_button(btn_cat_cards, current_category == "cards")

func _apply_cat_button(btn: Button, is_active: bool) -> void:
	if btn == null or _style_cat_normal == null or _style_cat_active == null:
		return
	if is_active:
		btn.add_theme_stylebox_override("normal", _style_cat_active)
		btn.add_theme_stylebox_override("hover", _style_cat_active)
		btn.add_theme_stylebox_override("pressed", _style_cat_active)
		btn.add_theme_color_override("font_color", Color(0.08, 0.1, 0.12, 1.0))
	else:
		btn.add_theme_stylebox_override("normal", _style_cat_normal)
		btn.add_theme_stylebox_override("hover", _style_cat_hover)
		btn.add_theme_stylebox_override("pressed", _style_cat_normal)
		btn.add_theme_color_override("font_color", Color(0.8, 0.86, 0.94, 0.9))

func _scroll_cards_left() -> void:
	_animate_scroll(cards_scroll.scroll_horizontal - 316)

func _scroll_cards_right() -> void:
	_animate_scroll(cards_scroll.scroll_horizontal + 316)

func _animate_scroll(target_x: int) -> void:
	if cards_scroll == null or cards_hbox == null:
		return
	var max_x: int = max(0, int(cards_hbox.size.x - cards_scroll.size.x))
	var clamped_x: int = clampi(target_x, 0, max_x)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(cards_scroll, "scroll_horizontal", clamped_x, 0.22)

# Card Hover & Micro-interactions
func _setup_card_hover_effects() -> void:
	var cards_and_colors: Array = [
		[card_classic, Color(0.2, 0.8, 0.45, 0.85)],
		[card_sebastopol, Color(0.3, 0.65, 1.0, 0.85)],
		[card_solitaire, Color(0.95, 0.35, 0.4, 0.85)],
		[card_pyramid, Color(0.98, 0.72, 0.25, 0.85)],
		[card_tripeaks, Color(0.2, 0.85, 0.85, 0.85)],
		[card_holdem, Color(0.75, 0.5, 1.0, 0.85)],
		[card_gin_rummy, Color(0.95, 0.45, 0.8, 0.85)],
		[card_koikoi, Color(0.92, 0.35, 0.38, 0.85)]
	]

	for item in cards_and_colors:
		var card: PanelContainer = item[0]
		var glow_col: Color = item[1]
		if card == null:
			continue
		card.pivot_offset = Vector2(150, 270)
		card.mouse_entered.connect(func():
			var tw: Tween = create_tween().set_parallel(true)
			tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "scale", Vector2(1.02, 1.02), 0.15)
			tw.tween_property(card, "position:y", -6.0, 0.15)
			var sb: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
			sb.border_color = glow_col
			sb.shadow_color = Color(glow_col.r, glow_col.g, glow_col.b, 0.35)
			sb.shadow_size = 20
			card.add_theme_stylebox_override("panel", sb)
		)
		card.mouse_exited.connect(func():
			var tw: Tween = create_tween().set_parallel(true)
			tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "scale", Vector2.ONE, 0.15)
			tw.tween_property(card, "position:y", 0.0, 0.15)
			var sb: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
			sb.border_color = Color(1.0, 1.0, 1.0, 0.12)
			sb.shadow_color = Color(0, 0, 0, 0.55)
			sb.shadow_size = 16
			card.add_theme_stylebox_override("panel", sb)
		)

# Dynamic Artwork & Banner Builders
func _setup_card_banners() -> void:
	_build_classic_banner()
	_build_sebastopol_banner()
	_build_solitaire_banner()
	_build_pyramid_banner()
	_build_tripeaks_banner()
	_build_holdem_banner()
	_build_gin_rummy_banner()
	_build_koikoi_banner()

func _create_card_texture_rect(tex: Texture2D, pos: Vector2, sz: Vector2, rot: float = 0.0, is_shadow: bool = false) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = sz
	tr.position = pos
	tr.rotation = rot
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_shadow:
		tr.modulate = Color(0.0, 0.0, 0.0, 0.5)
	return tr

func _build_classic_banner() -> void:
	if card_classic == null:
		return
	var banner: Control = card_classic.get_node_or_null("VBox/Banner")
	if banner == null:
		return
	for c in banner.get_children():
		c.queue_free()

	# Ambient emerald glow
	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.12, 0.45, 0.22, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(glow)

	var th: String = ThemeManager.get_theme()
	var t_6_6: Texture2D = ThemeManager.get_tile_texture(6, 6, th)
	var t_6_4: Texture2D = ThemeManager.get_tile_texture(6, 4, th)

	if t_6_6 != null:
		banner.add_child(_create_card_texture_rect(t_6_6, Vector2(86, 7), Vector2(48, 96), -0.14, true))
		banner.add_child(_create_card_texture_rect(t_6_6, Vector2(84, 5), Vector2(48, 96), -0.14, false))

	if t_6_4 != null:
		banner.add_child(_create_card_texture_rect(t_6_4, Vector2(138, 9), Vector2(48, 96), 0.12, true))
		banner.add_child(_create_card_texture_rect(t_6_4, Vector2(136, 7), Vector2(48, 96), 0.12, false))

func _build_sebastopol_banner() -> void:
	if card_sebastopol == null:
		return
	var banner: Control = card_sebastopol.get_node_or_null("VBox/Banner")
	if banner == null:
		return
	for c in banner.get_children():
		c.queue_free()

	# Ambient sapphire glow
	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.15, 0.35, 0.7, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(glow)

	var th: String = ThemeManager.get_theme()
	var t_6_6: Texture2D = ThemeManager.get_tile_texture(6, 6, th)
	var t_6_3: Texture2D = ThemeManager.get_tile_texture(6, 3, th)
	var t_6_5: Texture2D = ThemeManager.get_tile_texture(6, 5, th)

	if t_6_3 != null:
		banner.add_child(_create_card_texture_rect(t_6_3, Vector2(62, 34), Vector2(36, 72), -PI * 0.5))

	if t_6_6 != null:
		banner.add_child(_create_card_texture_rect(t_6_6, Vector2(115, 14), Vector2(42, 84), 0.0, true))
		banner.add_child(_create_card_texture_rect(t_6_6, Vector2(113, 12), Vector2(42, 84), 0.0, false))

	if t_6_5 != null:
		banner.add_child(_create_card_texture_rect(t_6_5, Vector2(210, 34), Vector2(36, 72), PI * 0.5))

	var star_lbl := Label.new()
	star_lbl.text = "✦   ✦"
	star_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	star_lbl.offset_top = 4
	star_lbl.offset_left = -30
	star_lbl.offset_right = 30
	star_lbl.offset_bottom = 24
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.add_theme_color_override("font_color", Color(0.92, 0.8, 0.38, 0.85))
	star_lbl.add_theme_font_size_override("font_size", 12)
	star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(star_lbl)

func _build_solitaire_banner() -> void:
	if card_solitaire == null:
		return
	var banner: Control = card_solitaire.get_node_or_null("VBox/Banner")
	if banner == null:
		return
	for c in banner.get_children():
		c.queue_free()

	# Ruby felt glow
	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.6, 0.15, 0.2, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(glow)

	# Fanned cards: Card Back, J♣, Q♦, K♥, A♠
	var back_tex: Texture2D = CardTheme.get_back_texture()
	if back_tex != null:
		banner.add_child(_create_card_texture_rect(back_tex, Vector2(48, 22), Vector2(48, 68), -0.28, true))
		banner.add_child(_create_card_texture_rect(back_tex, Vector2(46, 20), Vector2(48, 68), -0.28, false))

	var suits: Array[String] = ["Diamonds", "Hearts", "Spades"]
	var ranks: Array[int] = [12, 13, 1]
	var positions: Array[Vector2] = [Vector2(88, 16), Vector2(128, 14), Vector2(168, 18)]
	var rotations: Array[float] = [-0.1, 0.06, 0.22]

	for i in range(3):
		var tex: Texture2D = CardTheme.get_card_texture(suits[i], ranks[i])
		if tex != null:
			banner.add_child(_create_card_texture_rect(tex, positions[i] + Vector2(2, 3), Vector2(50, 72), rotations[i], true))
			banner.add_child(_create_card_texture_rect(tex, positions[i], Vector2(50, 72), rotations[i], false))

func _build_pyramid_banner() -> void:
	if card_pyramid == null:
		return
	var banner: Control = card_pyramid.get_node_or_null("VBox/Banner")
	if banner == null:
		return
	for c in banner.get_children():
		c.queue_free()

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.7, 0.45, 0.15, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(glow)

	var t_apex: Texture2D = CardTheme.get_card_texture("Diamonds", 1)
	var t_7: Texture2D = CardTheme.get_card_texture("Hearts", 7)
	var t_6: Texture2D = CardTheme.get_card_texture("Clubs", 6)
	var t_k: Texture2D = CardTheme.get_card_texture("Spades", 13)

	if t_apex != null:
		banner.add_child(_create_card_texture_rect(t_apex, Vector2(88, 12), Vector2(40, 56), 0.0))
	if t_7 != null:
		banner.add_child(_create_card_texture_rect(t_7, Vector2(62, 46), Vector2(40, 56), 0.0))
	if t_6 != null:
		banner.add_child(_create_card_texture_rect(t_6, Vector2(114, 46), Vector2(40, 56), 0.0))
	if t_k != null:
		banner.add_child(_create_card_texture_rect(t_k, Vector2(174, 22), Vector2(48, 68), 0.15, true))
		banner.add_child(_create_card_texture_rect(t_k, Vector2(172, 20), Vector2(48, 68), 0.15, false))

func _build_tripeaks_banner() -> void:
	if card_tripeaks == null:
		return
	var banner: Control = card_tripeaks.get_node_or_null("VBox/Banner")
	if banner == null:
		return
	for c in banner.get_children():
		c.queue_free()

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.1, 0.5, 0.5, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(glow)

	var t_k: Texture2D = CardTheme.get_card_texture("Spades", 13)
	var t_q: Texture2D = CardTheme.get_card_texture("Hearts", 12)
	var t_j: Texture2D = CardTheme.get_card_texture("Diamonds", 11)
	var t_10: Texture2D = CardTheme.get_card_texture("Clubs", 10)

	if t_k != null:
		banner.add_child(_create_card_texture_rect(t_k, Vector2(56, 14), Vector2(42, 60), -0.06))
	if t_q != null:
		banner.add_child(_create_card_texture_rect(t_q, Vector2(112, 10), Vector2(42, 60), 0.0))
	if t_j != null:
		banner.add_child(_create_card_texture_rect(t_j, Vector2(168, 14), Vector2(42, 60), 0.06))
	if t_10 != null:
		banner.add_child(_create_card_texture_rect(t_10, Vector2(110, 42), Vector2(46, 64), 0.0, true))
		banner.add_child(_create_card_texture_rect(t_10, Vector2(108, 40), Vector2(46, 64), 0.0, false))

func _build_holdem_banner() -> void:
	if card_holdem == null:
		return
	var banner: Control = card_holdem.get_node_or_null("VBox/Banner")
	if banner == null:
		return
	for c in banner.get_children():
		c.queue_free()

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.45, 0.2, 0.7, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(glow)

	var t_as: Texture2D = CardTheme.get_card_texture("Spades", 1)
	var t_ah: Texture2D = CardTheme.get_card_texture("Hearts", 1)

	if t_as != null:
		banner.add_child(_create_card_texture_rect(t_as, Vector2(68, 20), Vector2(50, 70), -0.15, true))
		banner.add_child(_create_card_texture_rect(t_as, Vector2(66, 18), Vector2(50, 70), -0.15, false))
	if t_ah != null:
		banner.add_child(_create_card_texture_rect(t_ah, Vector2(108, 18), Vector2(50, 70), 0.12, true))
		banner.add_child(_create_card_texture_rect(t_ah, Vector2(106, 16), Vector2(50, 70), 0.12, false))

	var chip_red: Texture2D = preload("res://assets/Chips/chipRedWhite_sideBorder.png")
	var chip_blue: Texture2D = preload("res://assets/Chips/chipBlueWhite_sideBorder.png")
	var chip_black: Texture2D = preload("res://assets/Chips/chipBlackWhite_sideBorder.png")

	if chip_black != null:
		banner.add_child(_create_card_texture_rect(chip_black, Vector2(182, 58), Vector2(48, 28)))
	if chip_blue != null:
		banner.add_child(_create_card_texture_rect(chip_blue, Vector2(182, 44), Vector2(48, 28)))
	if chip_red != null:
		banner.add_child(_create_card_texture_rect(chip_red, Vector2(182, 30), Vector2(48, 28)))

func _build_gin_rummy_banner() -> void:
	if card_gin_rummy == null:
		return
	var banner: Control = card_gin_rummy.get_node_or_null("VBox/Banner")
	if banner == null:
		return
	for c in banner.get_children():
		c.queue_free()

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.65, 0.2, 0.5, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(glow)

	var t_8: Texture2D = CardTheme.get_card_texture("Hearts", 8)
	var t_9: Texture2D = CardTheme.get_card_texture("Hearts", 9)
	var t_10: Texture2D = CardTheme.get_card_texture("Hearts", 10)

	if t_8 != null:
		banner.add_child(_create_card_texture_rect(t_8, Vector2(66, 22), Vector2(48, 68), -0.16, true))
		banner.add_child(_create_card_texture_rect(t_8, Vector2(64, 20), Vector2(48, 68), -0.16, false))
	if t_9 != null:
		banner.add_child(_create_card_texture_rect(t_9, Vector2(108, 16), Vector2(50, 70), -0.02, true))
		banner.add_child(_create_card_texture_rect(t_9, Vector2(106, 14), Vector2(50, 70), -0.02, false))
	if t_10 != null:
		banner.add_child(_create_card_texture_rect(t_10, Vector2(150, 20), Vector2(48, 68), 0.14, true))
		banner.add_child(_create_card_texture_rect(t_10, Vector2(148, 18), Vector2(48, 68), 0.14, false))

func _build_koikoi_banner() -> void:
	if card_koikoi == null:
		return
	var banner: Control = card_koikoi.get_node_or_null("VBox/Banner")
	if banner == null:
		return
	for c in banner.get_children():
		c.queue_free()

	# Crimson / Japanese gold ambient glow
	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.65, 0.15, 0.2, 0.22)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(glow)

	# Fanned cards: #1f2326 plain card back, Cherry Curtain, Full Moon, Sake Cup!
	var back_tex: Texture2D = load(HanafudaCardData.CARD_BACK_PATH) if ResourceLoader.exists(HanafudaCardData.CARD_BACK_PATH) else null
	var t_curtain: Texture2D = load("res://assets/Hanafuda/Hanafuda_March_Hikari_Alt.svg") if ResourceLoader.exists("res://assets/Hanafuda/Hanafuda_March_Hikari_Alt.svg") else null
	var t_moon: Texture2D = load("res://assets/Hanafuda/Hanafuda_August_Hikari_Alt.svg") if ResourceLoader.exists("res://assets/Hanafuda/Hanafuda_August_Hikari_Alt.svg") else null
	var t_cup: Texture2D = load("res://assets/Hanafuda/Hanafuda_September_Tane_Alt.svg") if ResourceLoader.exists("res://assets/Hanafuda/Hanafuda_September_Tane_Alt.svg") else null

	var card_sz := Vector2(44, 72)
	if back_tex != null:
		banner.add_child(_create_card_texture_rect(back_tex, Vector2(46, 24), card_sz, -0.24, true))
		banner.add_child(_create_card_texture_rect(back_tex, Vector2(44, 22), card_sz, -0.24, false))

	if t_curtain != null:
		banner.add_child(_create_card_texture_rect(t_curtain, Vector2(88, 16), card_sz, -0.08, true))
		banner.add_child(_create_card_texture_rect(t_curtain, Vector2(86, 14), card_sz, -0.08, false))

	if t_moon != null:
		banner.add_child(_create_card_texture_rect(t_moon, Vector2(130, 14), card_sz, 0.08, true))
		banner.add_child(_create_card_texture_rect(t_moon, Vector2(128, 12), card_sz, 0.08, false))

	if t_cup != null:
		banner.add_child(_create_card_texture_rect(t_cup, Vector2(172, 22), card_sz, 0.22, true))
		banner.add_child(_create_card_texture_rect(t_cup, Vector2(170, 20), card_sz, 0.22, false))
