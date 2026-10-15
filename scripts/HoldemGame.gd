class_name HoldemGame
extends Control

## Texas Hold'em Poker Game Controller.
## Features No-Limit Texas Hold'em against intelligent AI opponents,
## standard hand evaluation, blinds, dealer rotation, betting rounds,
## chip management, animated card dealing, and responsive web-safe UI.

signal hand_started(hand_number: int)
signal hand_finished(winner_names: Array, pot_amount: int)

const PokerHandEvaluator = preload("res://scripts/PokerHandEvaluator.gd")
const PokerCard = preload("res://scripts/PokerCard.gd")
const PokerCardScene = preload("res://scenes/poker_card.tscn")

enum GameStage {
	WAITING,
	PRE_FLOP,
	FLOP,
	TURN,
	RIVER,
	SHOWDOWN,
	HAND_OVER,
}

# Configuration
var small_blind: int = 10
var big_blind: int = 20
var starting_chips: int = 1000
var total_players_count: int = 4 # 1 human + 1 to 3 AI

# Game state
var current_stage: GameStage = GameStage.WAITING
var hand_number: int = 0
var pot: int = 0
var current_highest_bet: int = 0
var last_raise_amount: int = 0
var dealer_seat_idx: int = 0
var current_actor_idx: int = -1
var deck: Array[Dictionary] = [] # Array of { "suit": String, "rank": int }

# Player data
# Array of Dictionaries:
# {
#   "id": int,
#   "name": String,
#   "is_human": bool,
#   "chips": int,
#   "current_bet": int,
#   "total_hand_bet": int,
#   "is_folded": bool,
#   "is_all_in": bool,
#   "cards": Array[PokerCard],
#   "seat_node": Control,
#   "card_slot_left": Control,
#   "card_slot_right": Control,
#   "name_label": Label,
#   "chips_label": Label,
#   "bet_badge": PanelContainer,
#   "bet_label": Label,
#   "action_label": Label,
#   "dealer_badge": Control,
#   "hand_desc_label": Label,
# }
var players: Array[Dictionary] = []

# Community cards
var community_cards: Array[PokerCard] = []
var community_card_data: Array[Dictionary] = []

# Automated / Fast testing flag
var is_instant_mode: bool = false
var ai_action_timer: Timer = null

# Node references
@onready var table_felt: Panel = $TableBackground
@onready var community_container: HBoxContainer = $TableBackground/CommunityArea/CardsHBox
@onready var pot_label: Label = $TableBackground/PotContainer/PotLabel
@onready var round_info_label: Label = $TableBackground/RoundInfoLabel
@onready var card_layer: Control = $CardLayer
@onready var deck_position_node: Control = $TableBackground/DeckPosition

# Player Seats
@onready var seat_human: Control = $Seats/SeatHuman
@onready var seat_ai_left: Control = $Seats/SeatAILeft
@onready var seat_ai_top: Control = $Seats/SeatAITop
@onready var seat_ai_right: Control = $Seats/SeatAIRight

# User Controls
@onready var controls_panel: Control = $UICanvas/PlayerControls
@onready var btn_fold: Button = $UICanvas/PlayerControls/HBox/BtnFold
@onready var btn_check_call: Button = $UICanvas/PlayerControls/HBox/BtnCheckCall
@onready var btn_bet_raise: Button = $UICanvas/PlayerControls/HBox/BtnBetRaise
@onready var raise_popup: Control = $UICanvas/RaisePopup
@onready var raise_slider: HSlider = $UICanvas/RaisePopup/Panel/VBox/RaiseSlider
@onready var raise_amount_label: Label = $UICanvas/RaisePopup/Panel/VBox/AmountLabel
@onready var btn_raise_min: Button = $UICanvas/RaisePopup/Panel/VBox/QuickHBox/BtnMin
@onready var btn_raise_half_pot: Button = $UICanvas/RaisePopup/Panel/VBox/QuickHBox/BtnHalfPot
@onready var btn_raise_pot: Button = $UICanvas/RaisePopup/Panel/VBox/QuickHBox/BtnPot
@onready var btn_raise_all_in: Button = $UICanvas/RaisePopup/Panel/VBox/QuickHBox/BtnAllIn
@onready var btn_raise_confirm: Button = $UICanvas/RaisePopup/Panel/VBox/BtnConfirmRaise
@onready var btn_raise_cancel: Button = $UICanvas/RaisePopup/Panel/VBox/BtnCancelRaise

# HUD / Nav
@onready var btn_menu: Button = $UICanvas/TopBar/BtnMenu
@onready var btn_restart_game: Button = $UICanvas/TopBar/BtnRestartGame
@onready var blinds_label: Label = $UICanvas/TopBar/BlindsLabel
@onready var hand_counter_label: Label = $UICanvas/TopBar/HandCounterLabel

# Winner / Showdown Dialog
@onready var showdown_banner: PanelContainer = $UICanvas/ShowdownBanner
@onready var winner_title_label: Label = $UICanvas/ShowdownBanner/VBox/WinnerTitle
@onready var winner_details_label: Label = $UICanvas/ShowdownBanner/VBox/WinnerDetails
@onready var btn_next_hand: Button = $UICanvas/ShowdownBanner/VBox/BtnNextHand

# Game Over / Bust Modal
@onready var game_over_modal: Control = $UICanvas/GameOverModal
@onready var game_over_title: Label = $UICanvas/GameOverModal/Panel/VBox/Title
@onready var game_over_desc: Label = $UICanvas/GameOverModal/Panel/VBox/Desc
@onready var btn_rebuy: Button = $UICanvas/GameOverModal/Panel/VBox/BtnRebuy
@onready var btn_game_over_menu: Button = $UICanvas/GameOverModal/Panel/VBox/BtnMenu

func _ready() -> void:
	small_blind = GameSettings.holdem_small_blind
	big_blind = GameSettings.holdem_big_blind
	starting_chips = GameSettings.holdem_starting_chips
	total_players_count = GameSettings.holdem_opponents + 1 # 1 human + opponents

	_init_players()
	_setup_signals()
	_update_blinds_label()

	controls_panel.visible = false
	raise_popup.visible = false
	showdown_banner.visible = false
	game_over_modal.visible = false

	# Start the initial hand
	start_new_hand()

func _setup_signals() -> void:
	btn_fold.pressed.connect(_on_user_fold)
	btn_check_call.pressed.connect(_on_user_check_call)
	btn_bet_raise.pressed.connect(_on_open_raise_popup)

	btn_raise_cancel.pressed.connect(func(): raise_popup.visible = false)
	btn_raise_confirm.pressed.connect(_on_user_confirm_raise)
	raise_slider.value_changed.connect(_on_raise_slider_changed)

	btn_raise_min.pressed.connect(_on_quick_raise_min)
	btn_raise_half_pot.pressed.connect(_on_quick_raise_half_pot)
	btn_raise_pot.pressed.connect(_on_quick_raise_pot)
	btn_raise_all_in.pressed.connect(_on_quick_raise_all_in)

	btn_next_hand.pressed.connect(_on_next_hand_clicked)
	btn_menu.pressed.connect(_on_menu_clicked)
	btn_restart_game.pressed.connect(reset_entire_match)

	btn_rebuy.pressed.connect(_on_rebuy_clicked)
	btn_game_over_menu.pressed.connect(_on_menu_clicked)

func _init_players() -> void:
	players.clear()

	var seat_configs = [
		{ "node": seat_human, "name": "You", "is_human": true },
		{ "node": seat_ai_left, "name": "Alice", "is_human": false },
		{ "node": seat_ai_top, "name": "Bob", "is_human": false },
		{ "node": seat_ai_right, "name": "Charlie", "is_human": false },
	]

	# Always enable human seat (index 0)
	seat_human.visible = true

	# Enable opponents according to total_players_count
	for i in range(1, 4):
		seat_configs[i]["node"].visible = (i < total_players_count)

	for i in range(total_players_count):
		var cfg = seat_configs[i]
		var seat: Control = cfg["node"]
		var p_data = {
			"id": i,
			"name": cfg["name"],
			"is_human": cfg["is_human"],
			"chips": starting_chips,
			"current_bet": 0,
			"total_hand_bet": 0,
			"is_folded": false,
			"is_all_in": false,
			"cards": [],
			"seat_node": seat,
			"card_slot_left": seat.get_node("CardsContainer/SlotLeft"),
			"card_slot_right": seat.get_node("CardsContainer/SlotRight"),
			"name_label": seat.get_node("InfoPanel/VBox/NameLabel"),
			"chips_label": seat.get_node("InfoPanel/VBox/ChipsLabel"),
			"bet_badge": seat.get_node_or_null("BetBadge"),
			"bet_label": seat.get_node_or_null("BetBadge/Label") if seat.has_node("BetBadge/Label") else null,
			"action_label": seat.get_node_or_null("ActionBadge/Label") if seat.has_node("ActionBadge/Label") else null,
			"action_badge": seat.get_node_or_null("ActionBadge"),
			"dealer_badge": seat.get_node_or_null("DealerBadge"),
			"hand_desc_label": seat.get_node_or_null("HandDescLabel"),
		}
		players.append(p_data)
		_update_player_display(p_data)

func _update_blinds_label() -> void:
	blinds_label.text = "Blinds: $%d / $%d" % [small_blind, big_blind]

func _update_player_display(p: Dictionary) -> void:
	if p["name_label"] != null:
		p["name_label"].text = p["name"]
	if p["chips_label"] != null:
		p["chips_label"].text = "$%d" % p["chips"]

	if p["bet_badge"] != null:
		p["bet_badge"].visible = (p["current_bet"] > 0)
		if p["bet_label"] != null:
			p["bet_label"].text = "$%d" % p["current_bet"]

	if p["dealer_badge"] != null:
		p["dealer_badge"].visible = (players.find(p) == dealer_seat_idx)

	if p["action_badge"] != null and p["action_label"] != null:
		# Keep action badge visible if it has text
		p["action_badge"].visible = not p["action_label"].text.is_empty()

func _set_player_action(p: Dictionary, action_text: String) -> void:
	if p["action_label"] != null and p["action_badge"] != null:
		p["action_label"].text = action_text
		p["action_badge"].visible = not action_text.is_empty()

func _clear_all_player_actions() -> void:
	for p in players:
		_set_player_action(p, "")

## Start a brand new hand
func start_new_hand() -> void:
	# Check if human player is busted
	if players[0]["chips"] <= 0:
		_show_game_over(false, "You ran out of chips! Would you like to rebuy?")
		return

	# Count active players with chips > 0
	var players_with_chips: Array[Dictionary] = []
	for p in players:
		if p["chips"] > 0:
			players_with_chips.append(p)

	if players_with_chips.size() <= 1:
		if players_with_chips.size() == 1 and players_with_chips[0]["is_human"]:
			_show_game_over(true, "Congratulations! You knocked out all opponents and won the tournament!")
		else:
			_show_game_over(false, "Match over! Rebuy to start a new tournament.")
		return

	hand_number += 1
	hand_counter_label.text = "Hand #%d" % hand_number
	hand_started.emit(hand_number)

	# Clean up previous cards
	_clean_up_cards()

	# Hide popups
	showdown_banner.visible = false
	controls_panel.visible = false
	raise_popup.visible = false
	_clear_all_player_actions()

	# Advance dealer button to next player with chips
	dealer_seat_idx = _find_next_active_player(dealer_seat_idx)

	# Reset player states
	for p in players:
		p["current_bet"] = 0
		p["total_hand_bet"] = 0
		p["is_folded"] = (p["chips"] <= 0)
		p["is_all_in"] = false
		p["cards"].clear()
		if p["hand_desc_label"] != null:
			p["hand_desc_label"].text = ""
			p["hand_desc_label"].visible = false
		_update_player_display(p)

	pot = 0
	_update_pot_display()

	# Initialize Deck
	_init_deck()

	# Post Blinds
	_post_blinds()

	# Deal Hole Cards
	current_stage = GameStage.PRE_FLOP
	_deal_hole_cards()

func _clean_up_cards() -> void:
	for c in community_cards:
		if is_instance_valid(c):
			c.queue_free()
	community_cards.clear()
	community_card_data.clear()

	for p in players:
		for c in p["cards"]:
			if is_instance_valid(c):
				c.queue_free()
		p["cards"].clear()

func _init_deck() -> void:
	deck.clear()
	var suits = ["Clubs", "Diamonds", "Hearts", "Spades"]
	for s in suits:
		for r in range(2, 15): # 2 to 14 (14 = Ace)
			deck.append({ "suit": s, "rank": r })
	deck.shuffle()

func _post_blinds() -> void:
	var active_with_chips: Array[int] = _get_active_player_indices()

	var sb_idx: int
	var bb_idx: int

	if active_with_chips.size() == 2:
		# Heads up: Dealer is Small Blind
		sb_idx = dealer_seat_idx
		bb_idx = _find_next_active_player(dealer_seat_idx)
	else:
		sb_idx = _find_next_active_player(dealer_seat_idx)
		bb_idx = _find_next_active_player(sb_idx)

	# Deduct Small Blind
	var sb_player = players[sb_idx]
	var sb_amount: int = mini(small_blind, sb_player["chips"])
	_deduct_chips(sb_player, sb_amount)
	_set_player_action(sb_player, "SB $%d" % sb_amount)

	# Deduct Big Blind
	var bb_player = players[bb_idx]
	var bb_amount: int = mini(big_blind, bb_player["chips"])
	_deduct_chips(bb_player, bb_amount)
	_set_player_action(bb_player, "BB $%d" % bb_amount)

	current_highest_bet = bb_amount
	last_raise_amount = big_blind

	_update_pot_display()
	for p in players:
		_update_player_display(p)

func _deduct_chips(p: Dictionary, amount: int) -> void:
	p["chips"] -= amount
	p["current_bet"] += amount
	p["total_hand_bet"] += amount
	pot += amount
	if p["chips"] == 0:
		p["is_all_in"] = true

func _update_pot_display() -> void:
	pot_label.text = "POT: $%d" % pot

func _deal_hole_cards() -> void:
	round_info_label.text = "Dealing Hole Cards..."

	for i in range(2):
		for p_idx in _get_active_player_indices():
			var p = players[p_idx]
			var card_data = deck.pop_back()
			var card_node: PokerCard = PokerCardScene.instantiate()
			card_layer.add_child(card_node)

			var slot: Control = p["card_slot_left"] if i == 0 else p["card_slot_right"]
			var target_pos: Vector2 = slot.global_position

			# Human gets cards face-up, AI face-down
			var face_up: bool = p["is_human"]
			card_node.setup(card_data["suit"], card_data["rank"], face_up)

			if is_instant_mode:
				card_node.global_position = target_pos
			else:
				var start_pos = deck_position_node.global_position if deck_position_node != null else Vector2(640, 260)
				card_node.global_position = start_pos
				card_node.move_to(target_pos, 0.22)

			p["cards"].append(card_node)

	_update_human_hand_desc()

	# Pre-flop action begins with the player to the left of Big Blind (UTG)
	var active = _get_active_player_indices()
	var bb_idx: int
	if active.size() == 2:
		bb_idx = _find_next_active_player(dealer_seat_idx)
	else:
		var sb_idx = _find_next_active_player(dealer_seat_idx)
		bb_idx = _find_next_active_player(sb_idx)

	current_actor_idx = _find_next_active_player(bb_idx)
	_start_betting_round()

func _update_human_hand_desc() -> void:
	var human = players[0]
	if human["is_folded"] or human["cards"].size() < 2:
		return

	var available_cards: Array = []
	for c in human["cards"]:
		available_cards.append({ "suit": c.suit, "rank": c.rank })
	for cd in community_card_data:
		available_cards.append(cd)

	var eval_res = PokerHandEvaluator.evaluate_best_hand(available_cards)
	if human["hand_desc_label"] != null:
		human["hand_desc_label"].text = eval_res["description"]
		human["hand_desc_label"].visible = true

func _start_betting_round() -> void:
	# Update stage banner
	match current_stage:
		GameStage.PRE_FLOP: round_info_label.text = "Pre-Flop"
		GameStage.FLOP: round_info_label.text = "The Flop"
		GameStage.TURN: round_info_label.text = "The Turn"
		GameStage.RIVER: round_info_label.text = "The River"

	_process_next_betting_action()

func _process_next_betting_action() -> void:
	# 1. Check if only 1 active (non-folded) player remains
	var non_folded: Array[Dictionary] = []
	for p in players:
		if not p["is_folded"]:
			non_folded.append(p)

	if non_folded.size() <= 1:
		_end_hand_single_winner(non_folded[0] if non_folded.size() == 1 else players[0])
		return

	# 2. Check if betting round is settled
	if _is_betting_round_complete():
		_advance_to_next_stage()
		return

	# 3. Action on current_actor_idx
	var actor = players[current_actor_idx]
	if actor["is_folded"] or actor["is_all_in"]:
		current_actor_idx = _find_next_active_player(current_actor_idx)
		_process_next_betting_action()
		return

	if actor["is_human"]:
		_prompt_user_action()
	else:
		_perform_ai_action(actor)

func _is_betting_round_complete() -> bool:
	var active: Array[Dictionary] = []
	var non_all_in_count: int = 0
	for p in players:
		if not p["is_folded"]:
			active.append(p)
			if not p["is_all_in"]:
				non_all_in_count += 1

	if non_all_in_count <= 1:
		# If 0 or 1 player can bet, check if all bets are equal
		for p in active:
			if not p["is_all_in"] and p["current_bet"] < current_highest_bet:
				return false
		return true

	for p in active:
		if not p["is_all_in"]:
			if p["current_bet"] != current_highest_bet or p["current_bet"] == 0 and current_highest_bet > 0:
				return false
			# Also ensure player had at least one turn to act
			if p["action_label"] == null or p["action_label"].text.is_empty():
				return false

	return true

func _prompt_user_action() -> void:
	controls_panel.visible = true
	var human = players[0]
	var call_amount: int = current_highest_bet - human["current_bet"]

	if call_amount <= 0:
		btn_check_call.text = "Check"
	else:
		var actual_call: int = mini(call_amount, human["chips"])
		btn_check_call.text = "Call $%d" % actual_call

	var is_raise: bool = current_highest_bet > 0
	btn_bet_raise.text = "Raise" if is_raise else "Bet"
	btn_bet_raise.disabled = (human["chips"] <= call_amount)

func _on_user_fold() -> void:
	controls_panel.visible = false
	var human = players[0]
	human["is_folded"] = true
	for c in human["cards"]:
		c.set_dim(true)
	_set_player_action(human, "Fold")
	_update_player_display(human)

	current_actor_idx = _find_next_active_player(0)
	_process_next_betting_action()

func _on_user_check_call() -> void:
	controls_panel.visible = false
	var human = players[0]
	var call_amount: int = current_highest_bet - human["current_bet"]

	if call_amount <= 0:
		_set_player_action(human, "Check")
	else:
		var pay: int = mini(call_amount, human["chips"])
		_deduct_chips(human, pay)
		_set_player_action(human, "Call $%d" % pay if not human["is_all_in"] else "All-In $%d" % pay)

	_update_player_display(human)
	_update_pot_display()

	current_actor_idx = _find_next_active_player(0)
	_process_next_betting_action()

func _on_open_raise_popup() -> void:
	var human = players[0]
	var call_amount: int = current_highest_bet - human["current_bet"]
	var min_raise_total: int = current_highest_bet + last_raise_amount
	var max_raise_total: int = human["current_bet"] + human["chips"]

	min_raise_total = mini(min_raise_total, max_raise_total)

	raise_slider.min_value = min_raise_total
	raise_slider.max_value = max_raise_total
	raise_slider.value = min_raise_total
	_on_raise_slider_changed(min_raise_total)

	raise_popup.visible = true

func _on_raise_slider_changed(value: float) -> void:
	var raise_val: int = int(value)
	var human = players[0]
	var additional_cost: int = raise_val - human["current_bet"]
	raise_amount_label.text = "Total Bet: $%d (+$%d)" % [raise_val, additional_cost]
	btn_raise_confirm.text = "Confirm Bet $%d" % raise_val

func _on_quick_raise_min() -> void:
	raise_slider.value = raise_slider.min_value

func _on_quick_raise_half_pot() -> void:
	var target = current_highest_bet + pot / 2
	raise_slider.value = clampi(target, int(raise_slider.min_value), int(raise_slider.max_value))

func _on_quick_raise_pot() -> void:
	var target = current_highest_bet + pot
	raise_slider.value = clampi(target, int(raise_slider.min_value), int(raise_slider.max_value))

func _on_quick_raise_all_in() -> void:
	raise_slider.value = raise_slider.max_value

func _on_user_confirm_raise() -> void:
	raise_popup.visible = false
	controls_panel.visible = false

	var human = players[0]
	var target_total_bet: int = int(raise_slider.value)
	var additional: int = target_total_bet - human["current_bet"]

	last_raise_amount = target_total_bet - current_highest_bet
	current_highest_bet = target_total_bet

	_deduct_chips(human, additional)
	_set_player_action(human, "Raise $%d" % target_total_bet if not human["is_all_in"] else "All-In $%d" % target_total_bet)

	_update_player_display(human)
	_update_pot_display()

	current_actor_idx = _find_next_active_player(0)
	_process_next_betting_action()

func _perform_ai_action(ai_player: Dictionary) -> void:
	controls_panel.visible = false

	if is_instant_mode:
		_execute_ai_decision(ai_player)
	else:
		var tween: Tween = create_tween()
		tween.tween_interval(0.45)
		tween.tween_callback(func(): _execute_ai_decision(ai_player))

func _execute_ai_decision(ai_player: Dictionary) -> void:
	var call_amount: int = current_highest_bet - ai_player["current_bet"]
	var chips: int = ai_player["chips"]

	# AI Decision Evaluation
	var all_cards: Array = []
	for c in ai_player["cards"]:
		all_cards.append({ "suit": c.suit, "rank": c.rank })
	for cd in community_card_data:
		all_cards.append(cd)

	var eval_res = PokerHandEvaluator.evaluate_best_hand(all_cards)
	var rank_type = eval_res["rank_type"]

	# Calculate hand strength (0.0 to 1.0)
	var strength: float = 0.35 # default
	if current_stage == GameStage.PRE_FLOP:
		var c1 = all_cards[0]["rank"]
		var c2 = all_cards[1]["rank"]
		if c1 == c2:
			strength = 0.55 + (c1 / 14.0) * 0.4 # Pocket pair
		elif maxi(c1, c2) >= 12: # Face cards
			strength = 0.5 + (c1 + c2) / 28.0 * 0.3
		elif all_cards[0]["suit"] == all_cards[1]["suit"]: # Suited
			strength = 0.45 + (c1 + c2) / 28.0 * 0.25
		else:
			strength = (c1 + c2) / 28.0 * 0.45
	else:
		# Post-flop
		match rank_type:
			PokerHandEvaluator.HandRank.ROYAL_FLUSH, PokerHandEvaluator.HandRank.STRAIGHT_FLUSH, PokerHandEvaluator.HandRank.FOUR_OF_A_KIND:
				strength = 0.98
			PokerHandEvaluator.HandRank.FULL_HOUSE:
				strength = 0.92
			PokerHandEvaluator.HandRank.FLUSH:
				strength = 0.85
			PokerHandEvaluator.HandRank.STRAIGHT:
				strength = 0.80
			PokerHandEvaluator.HandRank.THREE_OF_A_KIND:
				strength = 0.72
			PokerHandEvaluator.HandRank.TWO_PAIR:
				strength = 0.62
			PokerHandEvaluator.HandRank.ONE_PAIR:
				strength = 0.48
			_:
				strength = 0.25

	# Add minor random variance
	var roll: float = randf()

	if call_amount == 0:
		# Free to check, or bet/raise if strong
		if strength > 0.75 and roll < 0.65:
			# Bet 1/2 pot or min bet
			var bet_amt = clampi(maxi(big_blind, pot / 2), big_blind, chips)
			current_highest_bet = bet_amt
			last_raise_amount = bet_amt
			_deduct_chips(ai_player, bet_amt)
			_set_player_action(ai_player, "Bet $%d" % bet_amt if not ai_player["is_all_in"] else "All-In $%d" % bet_amt)
		else:
			_set_player_action(ai_player, "Check")
	else:
		# Facing a bet
		var call_cost: int = mini(call_amount, chips)
		var pot_odds: float = float(call_cost) / float(pot + call_cost)

		if strength > 0.85 and roll < 0.45 and chips > call_amount * 2:
			# Raise!
			var raise_to = current_highest_bet + maxi(big_blind, current_highest_bet)
			raise_to = mini(raise_to, ai_player["current_bet"] + chips)
			var add = raise_to - ai_player["current_bet"]
			last_raise_amount = raise_to - current_highest_bet
			current_highest_bet = raise_to
			_deduct_chips(ai_player, add)
			_set_player_action(ai_player, "Raise $%d" % raise_to if not ai_player["is_all_in"] else "All-In $%d" % raise_to)
		elif strength >= pot_odds or strength > 0.45 or call_amount <= big_blind:
			# Call
			_deduct_chips(ai_player, call_cost)
			_set_player_action(ai_player, "Call $%d" % call_cost if not ai_player["is_all_in"] else "All-In $%d" % call_cost)
		else:
			# Fold
			ai_player["is_folded"] = true
			for c in ai_player["cards"]:
				c.set_dim(true)
			_set_player_action(ai_player, "Fold")

	_update_player_display(ai_player)
	_update_pot_display()

	current_actor_idx = _find_next_active_player(current_actor_idx)
	_process_next_betting_action()

func _advance_to_next_stage() -> void:
	# Reset round bets for all players
	for p in players:
		p["current_bet"] = 0
		_update_player_display(p)
	current_highest_bet = 0
	last_raise_amount = big_blind
	_clear_all_player_actions()

	match current_stage:
		GameStage.PRE_FLOP:
			current_stage = GameStage.FLOP
			_deal_community_cards(3)
		GameStage.FLOP:
			current_stage = GameStage.TURN
			_deal_community_cards(1)
		GameStage.TURN:
			current_stage = GameStage.RIVER
			_deal_community_cards(1)
		GameStage.RIVER:
			current_stage = GameStage.SHOWDOWN
			_handle_showdown()

func _deal_community_cards(count: int) -> void:
	for i in range(count):
		if community_cards.size() >= community_container.get_child_count():
			break
		var card_data = deck.pop_back()
		community_card_data.append(card_data)

		var card_node: PokerCard = PokerCardScene.instantiate()
		card_layer.add_child(card_node)
		card_node.setup(card_data["suit"], card_data["rank"], true)

		var slot_idx = community_cards.size()
		var slot_node: Control = community_container.get_child(slot_idx) as Control
		var target_pos: Vector2 = slot_node.global_position

		if is_instant_mode:
			card_node.global_position = target_pos
		else:
			var start_pos = deck_position_node.global_position if deck_position_node != null else Vector2(640, 260)
			card_node.global_position = start_pos
			card_node.move_to(target_pos, 0.22)

		community_cards.append(card_node)

	_update_human_hand_desc()

	# Action starts with first active player to the left of dealer
	current_actor_idx = _find_next_active_player(dealer_seat_idx)
	_start_betting_round()

func _handle_showdown() -> void:
	round_info_label.text = "Showdown!"
	controls_panel.visible = false

	# 1. Reveal all hole cards of remaining players
	for p in players:
		if not p["is_folded"]:
			for c in p["cards"]:
				c.flip(true, 0.2)

	# 2. Evaluate all hands
	var evaluations: Array[Dictionary] = []
	for p in players:
		if not p["is_folded"]:
			var pool = []
			for c in p["cards"]:
				pool.append({ "suit": c.suit, "rank": c.rank, "card_node": c })
			for i in range(community_card_data.size()):
				var cd = community_card_data[i]
				pool.append({ "suit": cd["suit"], "rank": cd["rank"], "card_node": community_cards[i] })

			var eval_res = PokerHandEvaluator.evaluate_best_hand(pool)
			eval_res["player"] = p
			evaluations.append(eval_res)

			if p["hand_desc_label"] != null:
				p["hand_desc_label"].text = eval_res["description"]
				p["hand_desc_label"].visible = true

	# 3. Find highest score
	var winning_evals: Array[Dictionary] = []
	for ev in evaluations:
		if winning_evals.is_empty():
			winning_evals.append(ev)
		else:
			var cmp = PokerHandEvaluator.compare_scores(ev["score"], winning_evals[0]["score"])
			if cmp > 0:
				winning_evals.clear()
				winning_evals.append(ev)
			elif cmp == 0:
				winning_evals.append(ev)

	# 4. Highlight winning cards and distribute pot
	var split_pot: int = pot / winning_evals.size()
	var winner_names: Array[String] = []

	for ev in winning_evals:
		var p = ev["player"]
		winner_names.append(p["name"])
		p["chips"] += split_pot
		_set_player_action(p, "WINNER +$%d" % split_pot)
		_update_player_display(p)

		# Highlight winning cards
		for c_item in ev["cards"]:
			if c_item is Dictionary and "card_node" in c_item and is_instance_valid(c_item["card_node"]):
				c_item["card_node"].set_highlight(true)

	var winner_desc: String = winning_evals[0]["description"]
	var win_msg: String
	if winner_names.size() == 1:
		win_msg = "%s won $%d with %s!" % [winner_names[0], pot, winner_desc]
	else:
		win_msg = "Tie! %s split $%d with %s!" % [", ".join(winner_names), pot, winner_desc]

	winner_title_label.text = "HAND WINNER"
	winner_details_label.text = win_msg
	showdown_banner.visible = true

	var human_won: bool = ("You" in winner_names)
	GameSettings.record_holdem_hand(human_won, pot)
	hand_finished.emit(winner_names, pot)

	pot = 0
	_update_pot_display()

func _end_hand_single_winner(winner: Dictionary) -> void:
	round_info_label.text = "%s Wins (Opponents Folded)" % winner["name"]
	controls_panel.visible = false

	winner["chips"] += pot
	_set_player_action(winner, "WINNER +$%d" % pot)
	_update_player_display(winner)

	winner_title_label.text = "ALL OPPONENTS FOLDED"
	winner_details_label.text = "%s wins the pot of $%d!" % [winner["name"], pot]
	showdown_banner.visible = true

	var human_won: bool = winner["is_human"]
	GameSettings.record_holdem_hand(human_won, pot)
	hand_finished.emit([winner["name"]], pot)

	pot = 0
	_update_pot_display()

func _on_next_hand_clicked() -> void:
	start_new_hand()

func _show_game_over(player_won: bool, message: String) -> void:
	game_over_title.text = "TOURNAMENT CHAMPION!" if player_won else "OUT OF CHIPS"
	game_over_desc.text = message
	btn_rebuy.text = "Play Again ($%d)" % starting_chips
	game_over_modal.visible = true

func _on_rebuy_clicked() -> void:
	game_over_modal.visible = false
	reset_entire_match()

func reset_entire_match() -> void:
	for p in players:
		p["chips"] = starting_chips
		_update_player_display(p)
	dealer_seat_idx = 0
	hand_number = 0
	start_new_hand()

func _on_menu_clicked() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _find_next_active_player(from_idx: int) -> int:
	var count = players.size()
	for i in range(1, count + 1):
		var check_idx = (from_idx + i) % count
		var p = players[check_idx]
		if not p["is_folded"] and p["chips"] > 0:
			return check_idx
		elif not p["is_folded"] and p["is_all_in"]:
			return check_idx
	return from_idx

func _get_active_player_indices() -> Array[int]:
	var active: Array[int] = []
	for i in range(players.size()):
		if not players[i]["is_folded"] and (players[i]["chips"] > 0 or players[i]["is_all_in"]):
			active.append(i)
	return active
