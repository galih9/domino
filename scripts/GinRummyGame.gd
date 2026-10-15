class_name GinRummyGame
extends Control

## Gin Rummy Card Game Controller.
## Features 2-Player Gin Rummy against an intelligent AI opponent,
## complete meld evaluation (sets and runs), deadwood calculation,
## knocking, gin, layoffs, undercuts, match scoring, card sorting,
## and responsive animations.

signal hand_started(hand_number: int)
signal hand_finished(result: Dictionary)
signal match_won(winner_name: String, final_score: int)

const GinRummyCard = preload("res://scripts/GinRummyCard.gd")
const GinRummyCardScene = preload("res://scenes/gin_rummy_card.tscn")
const GinRummyEvaluator = preload("res://scripts/GinRummyEvaluator.gd")

enum TurnPhase {
	WAITING,
	DRAW,
	DISCARD,
	SHOWDOWN,
	MATCH_OVER
}

# Match Configuration
var match_target: int = 100
var is_instant_mode: bool = false # for unit testing / fast dealing

# Match State
var hand_number: int = 0
var player_match_score: int = 0
var ai_match_score: int = 0
var current_phase: TurnPhase = TurnPhase.WAITING
var is_player_turn: bool = true
var dealer_is_player: bool = false # alternates

# Card Collections
var deck: Array[Dictionary] = [] # 52 card data dictionaries
var stock_pile: Array[Dictionary] = [] # card data
var discard_pile: Array[Dictionary] = [] # card data

# Visual Card Nodes
var player_cards: Array[GinRummyCard] = []
var ai_cards: Array[GinRummyCard] = []
var top_discard_card: GinRummyCard = null
var stock_top_visual: GinRummyCard = null

# Selection State
var selected_card: GinRummyCard = null

# Node references
@onready var table_bg: Panel = $TableBackground
@onready var card_layer: Control = $CardLayer

# HUD
@onready var btn_menu: Button = $UICanvas/TopBar/HBox/BtnMenu
@onready var btn_restart: Button = $UICanvas/TopBar/HBox/BtnRestart
@onready var match_score_label: Label = $UICanvas/TopBar/HBox/ScorePill/MatchScoreLabel
@onready var hand_counter_label: Label = $UICanvas/TopBar/HBox/HandPill/HandCounterLabel

# Table slots
@onready var stock_slot: Panel = $TableBackground/CenterArea/StockSlot
@onready var stock_count_label: Label = $TableBackground/CenterArea/StockSlot/CountLabel
@onready var stock_glow: Panel = $TableBackground/CenterArea/StockSlot/Glow
@onready var discard_slot: Panel = $TableBackground/CenterArea/DiscardSlot
@onready var discard_empty_label: Label = $TableBackground/CenterArea/DiscardSlot/EmptyLabel
@onready var discard_glow: Panel = $TableBackground/CenterArea/DiscardSlot/Glow

# AI Area
@onready var ai_name_label: Label = $TableBackground/AIArea/AINameLabel
@onready var ai_status_label: Label = $TableBackground/AIArea/AIStatusLabel
@onready var ai_cards_container: Control = $TableBackground/AIArea/AICardsContainer

# Player Area
@onready var player_cards_container: Control = $TableBackground/PlayerArea/PlayerCardsContainer
@onready var deadwood_label: Label = $TableBackground/PlayerArea/StatsHBox/DeadwoodPill/DeadwoodLabel
@onready var melds_summary_label: Label = $TableBackground/PlayerArea/StatsHBox/MeldsPill/MeldsLabel
@onready var status_banner_label: Label = $TableBackground/StatusBanner/StatusLabel

# Controls
@onready var btn_draw_stock: Button = $UICanvas/ActionControls/HBox/BtnDrawStock
@onready var btn_draw_discard: Button = $UICanvas/ActionControls/HBox/BtnDrawDiscard
@onready var btn_discard_card: Button = $UICanvas/ActionControls/HBox/BtnDiscard
@onready var btn_knock: Button = $UICanvas/ActionControls/HBox/BtnKnock
@onready var btn_declare_gin: Button = $UICanvas/ActionControls/HBox/BtnGin
@onready var btn_sort_rank: Button = $TableBackground/PlayerArea/SortHBox/BtnSortRank
@onready var btn_sort_suit: Button = $TableBackground/PlayerArea/SortHBox/BtnSortSuit

# Showdown Modal
@onready var showdown_modal: Control = $UICanvas/ShowdownModal
@onready var showdown_title: Label = $UICanvas/ShowdownModal/Panel/VBox/Title
@onready var showdown_summary: Label = $UICanvas/ShowdownModal/Panel/VBox/SummaryLabel
@onready var showdown_player_melds: Label = $UICanvas/ShowdownModal/Panel/VBox/DetailsGrid/PlayerMelds
@onready var showdown_player_dw: Label = $UICanvas/ShowdownModal/Panel/VBox/DetailsGrid/PlayerDW
@onready var showdown_ai_melds: Label = $UICanvas/ShowdownModal/Panel/VBox/DetailsGrid/AIMelds
@onready var showdown_ai_dw: Label = $UICanvas/ShowdownModal/Panel/VBox/DetailsGrid/AIDW
@onready var showdown_pts_label: Label = $UICanvas/ShowdownModal/Panel/VBox/ScoreBreakdown
@onready var btn_next_hand: Button = $UICanvas/ShowdownModal/Panel/VBox/BtnNextHand

# Game Over / Match Victory Modal
@onready var game_over_modal: Control = $UICanvas/GameOverModal
@onready var game_over_title: Label = $UICanvas/GameOverModal/Panel/VBox/Title
@onready var game_over_desc: Label = $UICanvas/GameOverModal/Panel/VBox/Desc
@onready var btn_play_again: Button = $UICanvas/GameOverModal/Panel/VBox/HBox/BtnPlayAgain
@onready var btn_game_over_menu: Button = $UICanvas/GameOverModal/Panel/VBox/HBox/BtnMenu

func _ready() -> void:
	match_target = GameSettings.gin_match_target
	_setup_signals()
	_update_hud()
	start_new_match()

func _setup_signals() -> void:
	btn_menu.pressed.connect(_on_menu_clicked)
	btn_restart.pressed.connect(start_new_match)

	btn_draw_stock.pressed.connect(_on_player_draw_stock)
	btn_draw_discard.pressed.connect(_on_player_draw_discard)
	btn_discard_card.pressed.connect(_on_player_discard_selected)
	btn_knock.pressed.connect(_on_player_knock)
	btn_declare_gin.pressed.connect(_on_player_declare_gin)

	btn_sort_rank.pressed.connect(_sort_player_hand_by_rank)
	btn_sort_suit.pressed.connect(_sort_player_hand_by_suit)

	stock_slot.gui_input.connect(_on_stock_slot_gui_input)
	discard_slot.gui_input.connect(_on_discard_slot_gui_input)

	btn_next_hand.pressed.connect(_on_next_hand_clicked)
	btn_play_again.pressed.connect(start_new_match)
	btn_game_over_menu.pressed.connect(_on_menu_clicked)

func _on_menu_clicked() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func start_new_match() -> void:
	player_match_score = 0
	ai_match_score = 0
	hand_number = 0
	dealer_is_player = true
	if showdown_modal != null:
		showdown_modal.visible = false
	if game_over_modal != null:
		game_over_modal.visible = false
	start_new_hand()

func start_new_hand() -> void:
	hand_number += 1
	dealer_is_player = not dealer_is_player
	is_player_turn = not dealer_is_player # non-dealer plays first
	current_phase = TurnPhase.WAITING
	selected_card = null

	if showdown_modal != null:
		showdown_modal.visible = false

	# Clear previous cards
	for c in player_cards:
		if is_instance_valid(c):
			c.queue_free()
	for c in ai_cards:
		if is_instance_valid(c):
			c.queue_free()
	if is_instance_valid(top_discard_card):
		top_discard_card.queue_free()
		top_discard_card = null
	if is_instance_valid(stock_top_visual):
		stock_top_visual.queue_free()
		stock_top_visual = null

	player_cards.clear()
	ai_cards.clear()
	discard_pile.clear()

	_update_hud()
	_create_shuffled_deck()
	_deal_cards()

func _create_shuffled_deck() -> void:
	deck.clear()
	var suits: Array[String] = ["Clubs", "Diamonds", "Hearts", "Spades"]
	for s in suits:
		for r in range(1, 14): # 1 to 13 (Ace to King)
			deck.append({ "suit": s, "rank": r })
	deck.shuffle()

func _deal_cards() -> void:
	# Deal 10 cards to each player
	var player_data: Array[Dictionary] = []
	var ai_data: Array[Dictionary] = []

	for i in range(10):
		player_data.append(deck.pop_back())
		ai_data.append(deck.pop_back())

	# Initial discard upcard
	discard_pile.append(deck.pop_back())
	# Remaining cards form stock
	stock_pile = deck.duplicate()

	# Spawn visual cards
	for cd in player_data:
		var card_inst: GinRummyCard = GinRummyCardScene.instantiate()
		card_layer.add_child(card_inst)
		card_inst.setup(cd["suit"], cd["rank"], true)
		card_inst.card_clicked.connect(_on_player_card_clicked)
		card_inst.card_double_clicked.connect(_on_player_card_double_clicked)
		player_cards.append(card_inst)

	for cd in ai_data:
		var card_inst: GinRummyCard = GinRummyCardScene.instantiate()
		card_layer.add_child(card_inst)
		card_inst.setup(cd["suit"], cd["rank"], false)
		ai_cards.append(card_inst)

	_update_stock_and_discard_visuals()
	_sort_player_hand_by_rank()
	_reposition_ai_cards()

	current_phase = TurnPhase.DRAW
	_update_turn_state()
	hand_started.emit(hand_number)

func _update_stock_and_discard_visuals() -> void:
	if stock_count_label != null:
		stock_count_label.text = "%d" % stock_pile.size()

	# Discard pile visual
	if discard_pile.is_empty():
		if is_instance_valid(top_discard_card):
			top_discard_card.queue_free()
			top_discard_card = null
		if discard_empty_label != null:
			discard_empty_label.visible = true
	else:
		if discard_empty_label != null:
			discard_empty_label.visible = false
		var top_data: Dictionary = discard_pile.back()
		if not is_instance_valid(top_discard_card):
			top_discard_card = GinRummyCardScene.instantiate()
			card_layer.add_child(top_discard_card)
		top_discard_card.setup(top_data["suit"], top_data["rank"], true)
		top_discard_card.global_position = discard_slot.global_position
		top_discard_card.mouse_filter = Control.MOUSE_FILTER_PASS

func _reposition_player_cards(animated: bool = true) -> void:
	var total: int = player_cards.size()
	if total == 0:
		return

	var area_width: float = player_cards_container.size.x
	var card_w: float = GinRummyCard.CARD_WIDTH
	var spacing: float = minf(card_w * 0.72, (area_width - card_w) / maxf(1.0, float(total - 1)))
	var total_w: float = (total - 1) * spacing + card_w
	var start_x: float = player_cards_container.global_position.x + (area_width - total_w) * 0.5
	var base_y: float = player_cards_container.global_position.y + 10.0

	for i in range(total):
		var card: GinRummyCard = player_cards[i]
		var target_pos = Vector2(start_x + i * spacing, base_y)
		card.base_local_pos = target_pos
		card.z_index = 10 + i
		if animated and not is_instant_mode:
			card.move_to(target_pos, 0.18)
		else:
			card.position = target_pos - Vector2(0, (GinRummyCard.LIFT_OFFSET if card.is_selected else 0.0))

func _reposition_ai_cards(animated: bool = true) -> void:
	var total: int = ai_cards.size()
	if total == 0:
		return

	var area_width: float = ai_cards_container.size.x
	var card_w: float = GinRummyCard.CARD_WIDTH
	var spacing: float = minf(card_w * 0.55, (area_width - card_w) / maxf(1.0, float(total - 1)))
	var total_w: float = (total - 1) * spacing + card_w
	var start_x: float = ai_cards_container.global_position.x + (area_width - total_w) * 0.5
	var base_y: float = ai_cards_container.global_position.y

	for i in range(total):
		var card: GinRummyCard = ai_cards[i]
		var target_pos = Vector2(start_x + i * spacing, base_y)
		card.base_local_pos = target_pos
		card.z_index = 5 + i
		if animated and not is_instant_mode:
			card.move_to(target_pos, 0.18)
		else:
			card.position = target_pos

func _sort_player_hand_by_rank() -> void:
	player_cards.sort_custom(func(a, b):
		if a.rank != b.rank:
			return a.rank < b.rank
		return a.suit < b.suit
	)
	_evaluate_and_mark_player_melds()
	_reposition_player_cards(true)

func _sort_player_hand_by_suit() -> void:
	player_cards.sort_custom(func(a, b):
		if a.suit != b.suit:
			return a.suit < b.suit
		return a.rank < b.rank
	)
	_evaluate_and_mark_player_melds()
	_reposition_player_cards(true)

func _evaluate_and_mark_player_melds() -> void:
	var hand_data: Array = []
	for c in player_cards:
		hand_data.append(c)

	var part: Dictionary = GinRummyEvaluator.find_optimal_partition(hand_data)
	var melded_cards: Array = []
	for m in part["melds"]:
		for mc in m:
			melded_cards.append(mc)

	for c in player_cards:
		var in_meld: bool = false
		for mc in melded_cards:
			if c == mc or (c.suit == mc.suit and c.rank == mc.rank):
				in_meld = true
				break
		c.set_melded(in_meld)

	var dw_pts: int = part["deadwood_points"]
	var meld_count: int = part["melds"].size()
	if deadwood_label != null:
		deadwood_label.text = "Deadwood: %d pts" % dw_pts
	if melds_summary_label != null:
		melds_summary_label.text = "Melds: %d (%d cards)" % [meld_count, melded_cards.size()]

func _update_turn_state() -> void:
	_update_hud()
	_evaluate_and_mark_player_melds()

	if is_player_turn:
		if current_phase == TurnPhase.DRAW:
			status_banner_label.text = "YOUR TURN: Draw a card from the Stock or Discard pile."
			stock_glow.visible = true
			discard_glow.visible = not discard_pile.is_empty()
			btn_draw_stock.visible = true
			btn_draw_discard.visible = not discard_pile.is_empty()
			btn_discard_card.visible = false
			btn_knock.visible = false
			btn_declare_gin.visible = false
		elif current_phase == TurnPhase.DISCARD:
			status_banner_label.text = "YOUR TURN: Choose a card to discard."
			stock_glow.visible = false
			discard_glow.visible = false
			btn_draw_stock.visible = false
			btn_draw_discard.visible = false
			btn_discard_card.visible = true
			_update_player_action_buttons()
	else:
		stock_glow.visible = false
		discard_glow.visible = false
		btn_draw_stock.visible = false
		btn_draw_discard.visible = false
		btn_discard_card.visible = false
		btn_knock.visible = false
		btn_declare_gin.visible = false
		status_banner_label.text = "AI OPPONENT IS THINKING..."
		if not is_instant_mode:
			var timer: SceneTreeTimer = get_tree().create_timer(0.7)
			timer.timeout.connect(_execute_ai_turn)
		else:
			_execute_ai_turn()

func _update_player_action_buttons() -> void:
	if current_phase != TurnPhase.DISCARD or not is_player_turn:
		btn_discard_card.disabled = true
		btn_knock.visible = false
		btn_declare_gin.visible = false
		return

	if selected_card == null:
		btn_discard_card.disabled = true
		btn_discard_card.text = "Select a Card"
		btn_knock.visible = false
		btn_declare_gin.visible = false
		return

	btn_discard_card.disabled = false
	btn_discard_card.text = "Discard %s" % selected_card.get_display_name()

	# Check hand if selected_card is discarded
	var temp_10: Array = []
	for c in player_cards:
		if c != selected_card:
			temp_10.append(c)

	var part: Dictionary = GinRummyEvaluator.find_optimal_partition(temp_10)
	var dw: int = part["deadwood_points"]

	if dw == 0:
		btn_declare_gin.visible = true
		btn_declare_gin.text = "Declare GIN!"
		btn_knock.visible = false
	elif dw <= 10:
		btn_knock.visible = true
		btn_knock.text = "Knock (%d dw)" % dw
		btn_declare_gin.visible = false
	else:
		btn_knock.visible = false
		btn_declare_gin.visible = false

# Player Interactions
func _on_player_card_clicked(card: GinRummyCard) -> void:
	if not is_player_turn or current_phase != TurnPhase.DISCARD:
		return

	if selected_card == card:
		# Unselect
		card.set_selected(false)
		selected_card = null
	else:
		if selected_card != null:
			selected_card.set_selected(false)
		selected_card = card
		card.set_selected(true)

	_update_player_action_buttons()

func _on_player_card_double_clicked(card: GinRummyCard) -> void:
	if not is_player_turn or current_phase != TurnPhase.DISCARD:
		return
	selected_card = card
	_on_player_discard_selected()

func _on_stock_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_player_turn and current_phase == TurnPhase.DRAW:
			_on_player_draw_stock()

func _on_discard_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_player_turn and current_phase == TurnPhase.DRAW:
			_on_player_draw_discard()

func _on_player_draw_stock() -> void:
	if not is_player_turn or current_phase != TurnPhase.DRAW or stock_pile.is_empty():
		return

	var drawn_data: Dictionary = stock_pile.pop_back()
	var card_inst: GinRummyCard = GinRummyCardScene.instantiate()
	card_layer.add_child(card_inst)
	card_inst.setup(drawn_data["suit"], drawn_data["rank"], true)
	card_inst.global_position = stock_slot.global_position
	card_inst.card_clicked.connect(_on_player_card_clicked)
	card_inst.card_double_clicked.connect(_on_player_card_double_clicked)
	player_cards.append(card_inst)

	_update_stock_and_discard_visuals()
	_reposition_player_cards(true)

	current_phase = TurnPhase.DISCARD
	_update_turn_state()

func _on_player_draw_discard() -> void:
	if not is_player_turn or current_phase != TurnPhase.DRAW or discard_pile.is_empty():
		return

	var drawn_data: Dictionary = discard_pile.pop_back()
	var card_inst: GinRummyCard = GinRummyCardScene.instantiate()
	card_layer.add_child(card_inst)
	card_inst.setup(drawn_data["suit"], drawn_data["rank"], true)
	card_inst.global_position = discard_slot.global_position
	card_inst.card_clicked.connect(_on_player_card_clicked)
	card_inst.card_double_clicked.connect(_on_player_card_double_clicked)
	player_cards.append(card_inst)

	_update_stock_and_discard_visuals()
	_reposition_player_cards(true)

	current_phase = TurnPhase.DISCARD
	_update_turn_state()

func _on_player_discard_selected() -> void:
	if selected_card == null or not is_player_turn or current_phase != TurnPhase.DISCARD:
		return

	var card_to_discard = selected_card
	selected_card = null
	player_cards.erase(card_to_discard)

	discard_pile.append({ "suit": card_to_discard.suit, "rank": card_to_discard.rank })
	card_to_discard.queue_free()

	_update_stock_and_discard_visuals()
	_reposition_player_cards(true)

	# Check stock exhaustion (stalemate check)
	if stock_pile.size() <= 2:
		_handle_stock_exhausted()
		return

	# End player turn, switch to AI
	is_player_turn = false
	current_phase = TurnPhase.DRAW
	_update_turn_state()

func _on_player_knock() -> void:
	if selected_card == null:
		return
	_finalize_hand_with_knock(true, false)

func _on_player_declare_gin() -> void:
	if selected_card == null:
		return
	_finalize_hand_with_knock(true, true)

func _finalize_hand_with_knock(player_is_knocker: bool, is_gin: bool) -> void:
	current_phase = TurnPhase.SHOWDOWN

	if player_is_knocker and selected_card != null:
		player_cards.erase(selected_card)
		discard_pile.append({ "suit": selected_card.suit, "rank": selected_card.rank })
		selected_card.queue_free()
		selected_card = null

	_update_stock_and_discard_visuals()
	_reposition_player_cards(false)

	# Reveal AI cards
	for c in ai_cards:
		c.set_face_up(true)
	_reposition_ai_cards(false)

	# Calculate showdown result
	var knocker_cards = player_cards if player_is_knocker else ai_cards
	var defender_cards = ai_cards if player_is_knocker else player_cards

	var result: Dictionary = GinRummyEvaluator.evaluate_showdown(knocker_cards, defender_cards)
	_display_showdown_result(player_is_knocker, result)

# AI Player Logic
func _execute_ai_turn() -> void:
	if is_player_turn or current_phase != TurnPhase.DRAW:
		return

	# 1. AI Draw Decision
	var should_take_discard: bool = false
	if not discard_pile.is_empty():
		var upcard = discard_pile.back()
		var test_11: Array = []
		for c in ai_cards:
			test_11.append(c)
		test_11.append(upcard)
		var disc_eval: Dictionary = GinRummyEvaluator.evaluate_best_discard(test_11)
		var current_part: Dictionary = GinRummyEvaluator.find_optimal_partition(ai_cards)

		if disc_eval["lowest_deadwood"] < current_part["deadwood_points"]:
			should_take_discard = true

	var drawn_data: Dictionary = {}
	if should_take_discard:
		drawn_data = discard_pile.pop_back()
		ai_status_label.text = "AI took the %s of %s from discard" % [str(drawn_data["rank"]), drawn_data["suit"]]
	else:
		drawn_data = stock_pile.pop_back()
		ai_status_label.text = "AI drew from the Stock pile"

	var ai_card_inst: GinRummyCard = GinRummyCardScene.instantiate()
	card_layer.add_child(ai_card_inst)
	ai_card_inst.setup(drawn_data["suit"], drawn_data["rank"], false)
	ai_cards.append(ai_card_inst)

	_update_stock_and_discard_visuals()
	_reposition_ai_cards(true)

	current_phase = TurnPhase.DISCARD

	# Short pause before AI discard
	if not is_instant_mode:
		var timer: SceneTreeTimer = get_tree().create_timer(0.8)
		timer.timeout.connect(_execute_ai_discard)
	else:
		_execute_ai_discard()

func _execute_ai_discard() -> void:
	# 2. AI Discard & Knock Decision
	var disc_res: Dictionary = GinRummyEvaluator.evaluate_best_discard(ai_cards)
	var card_to_discard: GinRummyCard = disc_res["best_card"]
	var resulting_dw: int = disc_res["lowest_deadwood"]

	ai_cards.erase(card_to_discard)
	discard_pile.append({ "suit": card_to_discard.suit, "rank": card_to_discard.rank })
	card_to_discard.queue_free()

	_update_stock_and_discard_visuals()
	_reposition_ai_cards(true)

	# Check stock exhaustion
	if stock_pile.size() <= 2:
		_handle_stock_exhausted()
		return

	# Check if AI decides to Knock or call Gin
	if resulting_dw == 0:
		ai_status_label.text = "AI declares GIN!"
		_finalize_hand_with_knock(false, true)
		return
	elif resulting_dw <= 7:
		ai_status_label.text = "AI knocks with %d deadwood!" % resulting_dw
		_finalize_hand_with_knock(false, false)
		return

	# Continue game: pass turn to Player
	is_player_turn = true
	current_phase = TurnPhase.DRAW
	_update_turn_state()

func _handle_stock_exhausted() -> void:
	current_phase = TurnPhase.SHOWDOWN
	status_banner_label.text = "STOCK EXHAUSTED (<= 2 cards remaining). Hand is a Draw!"

	showdown_modal.visible = true
	showdown_title.text = "HAND DRAW"
	showdown_summary.text = "Stock ran out with no knocker. 0 points awarded to both players."
	showdown_player_melds.text = "N/A"
	showdown_player_dw.text = "N/A"
	showdown_ai_melds.text = "N/A"
	showdown_ai_dw.text = "N/A"
	showdown_pts_label.text = "0 pts scored."

func _display_showdown_result(player_is_knocker: bool, result: Dictionary) -> void:
	var knocker_name: String = "You" if player_is_knocker else "AI Opponent"
	var defender_name: String = "AI Opponent" if player_is_knocker else "You"

	var winner_is_player: bool = false
	if result["winner"] == "knocker":
		winner_is_player = player_is_knocker
	else:
		winner_is_player = not player_is_knocker

	var pts: int = result["points_awarded"]
	if winner_is_player:
		player_match_score += pts
	else:
		ai_match_score += pts

	_update_hud()

	# Display Showdown Modal
	showdown_modal.visible = true
	if winner_is_player:
		showdown_title.text = "YOU WON THE HAND! (+%d pts)" % pts
	else:
		showdown_title.text = "AI OPPONENT WON THE HAND (+%d pts)" % pts

	showdown_summary.text = result["summary"]

	var player_part = GinRummyEvaluator.find_optimal_partition(player_cards)
	var ai_part = GinRummyEvaluator.find_optimal_partition(ai_cards)

	showdown_player_melds.text = "%d melds" % player_part["melds"].size()
	showdown_player_dw.text = "%d pts" % player_part["deadwood_points"]
	showdown_ai_melds.text = "%d melds" % ai_part["melds"].size()
	showdown_ai_dw.text = "%d pts" % ai_part["deadwood_points"]

	showdown_pts_label.text = "Points: +%d to %s\nMatch Score: You %d - %d AI (Target: %d)" % [
		pts, "You" if winner_is_player else "AI", player_match_score, ai_match_score, match_target
	]

	hand_finished.emit(result)

func _on_next_hand_clicked() -> void:
	showdown_modal.visible = false

	# Check match victory
	if player_match_score >= match_target or ai_match_score >= match_target:
		_handle_match_over()
	else:
		start_new_hand()

func _handle_match_over() -> void:
	current_phase = TurnPhase.MATCH_OVER
	game_over_modal.visible = true

	var player_won: bool = (player_match_score >= ai_match_score)
	if player_won:
		game_over_title.text = "MATCH VICTORY!"
		game_over_desc.text = "Congratulations! You reached %d points and won the Gin Rummy match!\nFinal: You %d  |  AI %d" % [
			player_match_score, player_match_score, ai_match_score
		]
	else:
		game_over_title.text = "MATCH DEFEAT"
		game_over_desc.text = "The AI opponent reached %d points and won the match.\nFinal: AI %d  |  You %d" % [
			ai_match_score, ai_match_score, player_match_score
		]

	GameSettings.record_gin_match(player_won, 1 if player_won else 0)
	match_won.emit("Player" if player_won else "AI", maxi(player_match_score, ai_match_score))

func _update_hud() -> void:
	if match_score_label != null:
		match_score_label.text = "You: %d  |  AI: %d  (First to %d)" % [player_match_score, ai_match_score, match_target]
	if hand_counter_label != null:
		hand_counter_label.text = "Hand #%d" % hand_number
