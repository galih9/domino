class_name KoiKoiGame
extends Control

## Koi-Koi Hanafuda Game Controller.
## Manages round dealing, matching against field, deck draws, AI turns,
## Yaku evaluation, Koi-Koi vs Stop decisions, scoring multipliers, and match progression.

const HanafudaCardData = preload("res://scripts/HanafudaCardData.gd")
const KoiKoiEvaluator = preload("res://scripts/KoiKoiEvaluator.gd")
const KoiKoiAI = preload("res://scripts/KoiKoiAI.gd")
const HanafudaCard = preload("res://scripts/HanafudaCard.gd")
const HanafudaCardScene = preload("res://scenes/hanafuda_card.tscn")

enum TurnState {
	IDLE,
	PLAYER_HAND_SELECT,
	PLAYER_FIELD_CHOICE,
	DRAW_PHASE,
	PLAYER_DRAW_CHOICE,
	AI_TURN,
	KOIKOI_DECISION,
	ROUND_OVER,
	MATCH_OVER
}

@export var is_instant_mode: bool = false

# Match settings and state
var total_rounds: int = 3
var current_round: int = 1
var player_total_score: int = 0
var ai_total_score: int = 0
var current_dealer_is_player: bool = true
var viewing_yaku_enabled: bool = true
var ai_difficulty: String = "Normal"

# Round state
var turn_state: TurnState = TurnState.IDLE
var is_player_turn: bool = true
var player_called_koikoi: bool = false
var ai_called_koikoi: bool = false
var player_last_yaku_pts: int = 0
var ai_last_yaku_pts: int = 0
var round_in_progress: bool = false

# Card collections
var deck_data: Array[Dictionary] = []
var player_hand: Array[HanafudaCard] = []
var ai_hand: Array[HanafudaCard] = []
var field_cards: Array[HanafudaCard] = []
var player_captured: Array[HanafudaCard] = []
var ai_captured: Array[HanafudaCard] = []

# Action tracking for choices
var pending_hand_card: HanafudaCard = null
var pending_drawn_card: HanafudaCard = null
var pending_field_choices: Array = []

# Node references
@onready var table_background: Panel = $TableBackground
@onready var round_label: Label = $TopBar/LeftHBox/RoundLabel
@onready var player_score_label: Label = $TopBar/ScoreHBox/PlayerScorePanel/PlayerScoreLabel
@onready var ai_score_label: Label = $TopBar/ScoreHBox/AIScorePanel/AIScoreLabel
@onready var status_banner: Label = $StatusBanner

# Captured trays
@onready var ai_captured_container: HBoxContainer = $AICapturedArea/HBox
@onready var player_captured_container: HBoxContainer = $PlayerCapturedArea/HBox
@onready var ai_captured_lbl: Label = $AICapturedArea/TitleLabel
@onready var player_captured_lbl: Label = $PlayerCapturedArea/TitleLabel

# Containers
@onready var ai_hand_container: Control = $AIHandArea
@onready var field_container: Control = $FieldArea
@onready var player_hand_container: Control = $PlayerHandArea
@onready var deck_slot: Control = $DeckSlot
@onready var deck_count_label: Label = $DeckSlot/CountBadge/Label

# Modals & Dialogs
@onready var koikoi_modal: Control = $KoiKoiModal
@onready var koikoi_yaku_list_lbl: Label = $KoiKoiModal/Panel/VBox/YakuListLabel
@onready var koikoi_points_lbl: Label = $KoiKoiModal/Panel/VBox/PointsLabel
@onready var btn_koikoi: Button = $KoiKoiModal/Panel/VBox/ButtonsHBox/BtnKoiKoi
@onready var btn_shoubu: Button = $KoiKoiModal/Panel/VBox/ButtonsHBox/BtnShoubu

@onready var round_dialog: Control = $RoundDialog
@onready var round_title_lbl: Label = $RoundDialog/Panel/VBox/TitleLabel
@onready var round_details_lbl: Label = $RoundDialog/Panel/VBox/DetailsLabel
@onready var btn_next_round: Button = $RoundDialog/Panel/VBox/BtnNextRound

@onready var match_dialog: Control = $MatchDialog
@onready var match_title_lbl: Label = $MatchDialog/Panel/VBox/TitleLabel
@onready var match_details_lbl: Label = $MatchDialog/Panel/VBox/DetailsLabel
@onready var btn_match_restart: Button = $MatchDialog/Panel/VBox/ButtonsHBox/BtnRestart
@onready var btn_match_menu: Button = $MatchDialog/Panel/VBox/ButtonsHBox/BtnMainMenu

# Top bar buttons
@onready var btn_top_menu: Button = $TopBar/RightHBox/BtnMenu
@onready var btn_top_rules: Button = $TopBar/RightHBox/BtnRules
@onready var btn_top_restart: Button = $TopBar/RightHBox/BtnRestart

# Big callout banner
@onready var callout_banner: PanelContainer = $CalloutBanner
@onready var callout_label: Label = $CalloutBanner/Label

func _ready() -> void:
	total_rounds = GameSettings.koikoi_rounds
	viewing_yaku_enabled = GameSettings.koikoi_viewing_yaku
	ai_difficulty = GameSettings.koikoi_ai_difficulty

	_setup_signals()
	_update_header_ui()

	koikoi_modal.visible = false
	round_dialog.visible = false
	match_dialog.visible = false
	callout_banner.visible = false

	start_new_match()

func _setup_signals() -> void:
	btn_top_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	btn_top_restart.pressed.connect(start_new_match)
	btn_top_rules.pressed.connect(_on_rules_clicked)

	btn_koikoi.pressed.connect(_on_player_called_koikoi)
	btn_shoubu.pressed.connect(_on_player_called_shoubu)

	btn_next_round.pressed.connect(_on_next_round_clicked)
	btn_match_restart.pressed.connect(start_new_match)
	btn_match_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func start_new_match() -> void:
	current_round = 1
	player_total_score = 0
	ai_total_score = 0
	current_dealer_is_player = true
	match_dialog.visible = false
	round_dialog.visible = false
	koikoi_modal.visible = false
	_start_round()

func _start_round() -> void:
	round_in_progress = true
	player_called_koikoi = false
	ai_called_koikoi = false
	player_last_yaku_pts = 0
	ai_last_yaku_pts = 0
	is_player_turn = current_dealer_is_player

	_clear_all_cards()
	_update_header_ui()

	# Create and deal deck
	deck_data = HanafudaCardData.create_shuffled_deck()

	# Deal 8 cards to Player, 8 to AI, 8 to Field
	for i in range(8):
		var p_card := _create_card(deck_data.pop_back(), true)
		player_hand.append(p_card)
		player_hand_container.add_child(p_card)

	for i in range(8):
		var a_card := _create_card(deck_data.pop_back(), false)
		ai_hand.append(a_card)
		ai_hand_container.add_child(a_card)

	for i in range(8):
		var f_card := _create_card(deck_data.pop_back(), true)
		field_cards.append(f_card)
		field_container.add_child(f_card)

	_layout_all_areas()

	# Check field 4 of a kind (Kyuushuu -> redeal)
	if KoiKoiEvaluator.check_field_four_of_a_kind(field_cards):
		_show_callout("FIELD REDEAL (Kyuushuu)!", 1.2)
		await _wait(1.2)
		_start_round()
		return

	# Check Teshi (4 of same month in hand)
	if KoiKoiEvaluator.check_teshi(player_hand):
		_show_callout("TESHI! (Hand of Four)", 1.5)
		_end_round_instant(true, 6, "Teshi (4 of same month in hand)")
		return
	if KoiKoiEvaluator.check_teshi(ai_hand):
		_show_callout("OPPONENT TESHI!", 1.5)
		_end_round_instant(false, 6, "Opponent Teshi (4 of same month in hand)")
		return

	# Check Kuttsuki (4 pairs in hand)
	if KoiKoiEvaluator.check_kuttsuki(player_hand):
		_show_callout("KUTTSUKI! (Four Pairs)", 1.5)
		_end_round_instant(true, 6, "Kuttsuki (Four pairs in hand)")
		return
	if KoiKoiEvaluator.check_kuttsuki(ai_hand):
		_show_callout("OPPONENT KUTTSUKI!", 1.5)
		_end_round_instant(false, 6, "Opponent Kuttsuki (Four pairs in hand)")
		return

	_start_next_turn()

func _create_card(data: Dictionary, face_up: bool) -> HanafudaCard:
	var card: HanafudaCard = HanafudaCardScene.instantiate()
	card.setup(data, face_up)
	card.card_clicked.connect(_on_card_clicked)
	card.card_hovered.connect(_on_card_hovered)
	return card

func _clear_all_cards() -> void:
	for c in player_hand: c.queue_free()
	for c in ai_hand: c.queue_free()
	for c in field_cards: c.queue_free()
	for c in player_captured: c.queue_free()
	for c in ai_captured: c.queue_free()
	player_hand.clear()
	ai_hand.clear()
	field_cards.clear()
	player_captured.clear()
	ai_captured.clear()
	pending_hand_card = null
	pending_drawn_card = null
	pending_field_choices.clear()

func _layout_all_areas() -> void:
	_layout_hand(player_hand, player_hand_container.size, true)
	_layout_hand(ai_hand, ai_hand_container.size, false)
	_layout_field()
	_update_deck_ui()
	_update_captured_ui()

func _layout_hand(hand: Array, area_size: Vector2, is_player: bool) -> void:
	if hand.is_empty():
		return
	var card_w: float = HanafudaCard.CARD_WIDTH
	var count: int = hand.size()
	var spacing: float = minf(74.0, (area_size.x - card_w) / maxf(1.0, float(count - 1)))
	var total_w: float = card_w + float(count - 1) * spacing
	var start_x: float = (area_size.x - total_w) * 0.5
	var y_pos: float = (area_size.y - HanafudaCard.CARD_HEIGHT) * 0.5

	for i in range(count):
		var card: HanafudaCard = hand[i]
		var target_pos := Vector2(start_x + float(i) * spacing, y_pos)
		if is_instant_mode:
			card.position = target_pos
			card.base_local_pos = target_pos
		else:
			card.move_to(target_pos, 0.2)

func _layout_field() -> void:
	if field_cards.is_empty():
		return
	var card_w: float = HanafudaCard.CARD_WIDTH
	var card_h: float = HanafudaCard.CARD_HEIGHT
	var count: int = field_cards.size()
	var cols: int = maxi(4, int(ceil(float(count) / 2.0)))
	var col_spacing: float = 78.0
	var row_spacing: float = card_h + 12.0
	var total_w: float = float(cols) * col_spacing
	var start_x: float = (field_container.size.x - total_w) * 0.5
	var start_y: float = (field_container.size.y - (row_spacing + card_h)) * 0.5

	for i in range(count):
		var card: HanafudaCard = field_cards[i]
		var row: int = i / cols
		var col: int = i % cols
		var target_pos := Vector2(start_x + float(col) * col_spacing, start_y + float(row) * row_spacing)
		if is_instant_mode:
			card.position = target_pos
			card.base_local_pos = target_pos
		else:
			card.move_to(target_pos, 0.2)

func _update_deck_ui() -> void:
	if deck_count_label != null:
		deck_count_label.text = str(deck_data.size())

func _update_captured_ui() -> void:
	var p_eval = KoiKoiEvaluator.evaluate_yaku(player_captured, viewing_yaku_enabled)
	var a_eval = KoiKoiEvaluator.evaluate_yaku(ai_captured, viewing_yaku_enabled)

	if player_captured_lbl != null:
		var p_pts = p_eval.get("total_points", 0)
		var p_txt = "YOU: %d pts" % p_pts
		if player_called_koikoi:
			p_txt += " (KOI-KOI!)"
		player_captured_lbl.text = p_txt

	if ai_captured_lbl != null:
		var a_pts = a_eval.get("total_points", 0)
		var a_txt = "OPPONENT: %d pts" % a_pts
		if ai_called_koikoi:
			a_txt += " (KOI-KOI!)"
		ai_captured_lbl.text = a_txt

func _update_header_ui() -> void:
	if round_label != null:
		round_label.text = "Round %d / %d" % [current_round, total_rounds]
	if player_score_label != null:
		player_score_label.text = "YOU: %d pts" % player_total_score
	if ai_score_label != null:
		ai_score_label.text = "OPPONENT: %d pts" % ai_total_score

func _start_next_turn() -> void:
	if not round_in_progress:
		return

	if player_hand.is_empty() and ai_hand.is_empty():
		_handle_round_draw()
		return

	if is_player_turn:
		turn_state = TurnState.PLAYER_HAND_SELECT
		status_banner.text = "Your Turn: Choose a card from your hand to play"
	else:
		turn_state = TurnState.AI_TURN
		status_banner.text = "Opponent is thinking..."
		_execute_ai_turn()

# --- Player Interactions ---

func _on_card_hovered(card: HanafudaCard, is_hovering: bool) -> void:
	if turn_state != TurnState.PLAYER_HAND_SELECT:
		return
	if not player_hand.has(card):
		return

	# Highlight matching cards on the field!
	if is_hovering:
		var matches: Array = KoiKoiEvaluator.find_field_matches(card.card_data, field_cards)
		for fc in field_cards:
			fc.set_matching_highlight(matches.has(fc))
	else:
		for fc in field_cards:
			fc.set_matching_highlight(false)

func _on_card_clicked(card: HanafudaCard) -> void:
	match turn_state:
		TurnState.PLAYER_HAND_SELECT:
			if player_hand.has(card):
				_handle_player_hand_card_selected(card)
		TurnState.PLAYER_FIELD_CHOICE:
			if pending_field_choices.has(card):
				_resolve_player_field_choice(card)
		TurnState.PLAYER_DRAW_CHOICE:
			if pending_field_choices.has(card):
				_resolve_player_draw_choice(card)

func _handle_player_hand_card_selected(card: HanafudaCard) -> void:
	pending_hand_card = card
	player_hand.erase(card)
	_layout_hand(player_hand, player_hand_container.size, true)

	# Clear matching highlights
	for fc in field_cards:
		fc.set_matching_highlight(false)

	var matches: Array = KoiKoiEvaluator.find_field_matches(card.card_data, field_cards)

	if matches.is_empty():
		# No match: place card directly on the field
		field_cards.append(card)
		card.reparent(field_container)
		_layout_field()
		await _wait(0.2)
		_execute_draw_phase(true)
	elif matches.size() == 1:
		# Single match: capture both cards immediately
		var matched_fc: HanafudaCard = matches[0]
		field_cards.erase(matched_fc)
		_capture_cards([card, matched_fc], true)
		_layout_field()
		await _wait(0.25)
		_execute_draw_phase(true)
	elif matches.size() == 2:
		# 2 matches: prompt player to pick one
		pending_field_choices = matches
		turn_state = TurnState.PLAYER_FIELD_CHOICE
		status_banner.text = "Two matches! Click a glowing card on the field to choose."
		for fc in matches:
			fc.set_matching_highlight(true)
	elif matches.size() >= 3:
		# 3 matches on field: capture all 4 cards!
		for fc in matches:
			field_cards.erase(fc)
		var capture_list = [card]
		capture_list.append_array(matches)
		_capture_cards(capture_list, true)
		_layout_field()
		await _wait(0.25)
		_execute_draw_phase(true)

func _resolve_player_field_choice(chosen_fc: HanafudaCard) -> void:
	for fc in pending_field_choices:
		fc.set_matching_highlight(false)
	pending_field_choices.clear()

	field_cards.erase(chosen_fc)
	_capture_cards([pending_hand_card, chosen_fc], true)
	pending_hand_card = null
	_layout_field()
	await _wait(0.25)
	_execute_draw_phase(true)

func _execute_draw_phase(is_human: bool) -> void:
	turn_state = TurnState.DRAW_PHASE
	if deck_data.is_empty():
		_after_turn_captures(is_human)
		return

	var d_data: Dictionary = deck_data.pop_back()
	_update_deck_ui()

	var drawn_card := _create_card(d_data, false)
	field_container.add_child(drawn_card)
	drawn_card.position = Vector2(20, field_container.size.y * 0.5 - 54)

	if not is_instant_mode:
		drawn_card.flip(true, 0.22)
		await _wait(0.26)
	else:
		drawn_card.set_face_up(true)

	var matches: Array = KoiKoiEvaluator.find_field_matches(drawn_card.card_data, field_cards)

	if matches.is_empty():
		field_cards.append(drawn_card)
		_layout_field()
		await _wait(0.2)
		_after_turn_captures(is_human)
	elif matches.size() == 1:
		var fc: HanafudaCard = matches[0]
		field_cards.erase(fc)
		_capture_cards([drawn_card, fc], is_human)
		_layout_field()
		await _wait(0.25)
		_after_turn_captures(is_human)
	elif matches.size() == 2:
		if is_human:
			pending_drawn_card = drawn_card
			pending_field_choices = matches
			turn_state = TurnState.PLAYER_DRAW_CHOICE
			status_banner.text = "Deck drew a match! Choose which card to capture."
			for m in matches:
				m.set_matching_highlight(true)
		else:
			# AI picks best of the 2
			var best_fc = KoiKoiAI.choose_best_field_match(matches, drawn_card.card_data, ai_captured, player_captured)
			field_cards.erase(best_fc)
			_capture_cards([drawn_card, best_fc], false)
			_layout_field()
			await _wait(0.25)
			_after_turn_captures(false)
	elif matches.size() >= 3:
		for fc in matches:
			field_cards.erase(fc)
		var cap_list = [drawn_card]
		cap_list.append_array(matches)
		_capture_cards(cap_list, is_human)
		_layout_field()
		await _wait(0.25)
		_after_turn_captures(is_human)

func _resolve_player_draw_choice(chosen_fc: HanafudaCard) -> void:
	for fc in pending_field_choices:
		fc.set_matching_highlight(false)
	pending_field_choices.clear()

	field_cards.erase(chosen_fc)
	_capture_cards([pending_drawn_card, chosen_fc], true)
	pending_drawn_card = null
	_layout_field()
	await _wait(0.25)
	_after_turn_captures(true)

func _capture_cards(cards: Array, is_human: bool) -> void:
	var target_list = player_captured if is_human else ai_captured
	var target_parent = player_captured_container if is_human else ai_captured_container

	for c in cards:
		if c.get_parent() != null:
			c.get_parent().remove_child(c)
		target_parent.add_child(c)
		c.set_face_up(true)
		c.scale = Vector2(0.5, 0.5) # Miniature preview in captured trays
		target_list.append(c)

	_update_captured_ui()

func _after_turn_captures(is_human: bool) -> void:
	var captured_list = player_captured if is_human else ai_captured
	var eval = KoiKoiEvaluator.evaluate_yaku(captured_list, viewing_yaku_enabled)
	var current_pts: int = eval.get("total_points", 0)
	var prev_pts: int = player_last_yaku_pts if is_human else ai_last_yaku_pts

	if eval.get("has_yaku", false) and current_pts > prev_pts:
		# A new or improved Yaku was achieved!
		if is_human:
			turn_state = TurnState.KOIKOI_DECISION
			_show_player_koikoi_modal(eval)
		else:
			# AI decision
			var calls_koikoi = KoiKoiAI.should_call_koikoi(
				current_pts,
				ai_captured,
				player_captured,
				ai_hand.size(),
				ai_difficulty
			)
			if calls_koikoi:
				ai_called_koikoi = true
				ai_last_yaku_pts = current_pts
				_show_callout("OPPONENT CALLED KOI-KOI!", 1.6)
				await _wait(1.6)
				is_player_turn = true
				_start_next_turn()
			else:
				# AI stops and claims victory!
				_show_callout("OPPONENT CALLS STOP (SHOUBU)!", 1.5)
				await _wait(1.5)
				_end_round_with_win(false, eval)
	else:
		# No new Yaku: switch turns
		is_player_turn = not is_player_turn
		_start_next_turn()

# --- AI Turn Execution ---

func _execute_ai_turn() -> void:
	if not is_instant_mode:
		await _wait(0.5)

	if ai_hand.is_empty():
		_after_turn_captures(false)
		return

	var decision: Dictionary = KoiKoiAI.choose_hand_card(ai_hand, field_cards, ai_captured, player_captured)
	var chosen_hand_card: HanafudaCard = decision.get("card", null)
	var target_fc: HanafudaCard = decision.get("target_field_card", null)

	if chosen_hand_card == null:
		chosen_hand_card = ai_hand[0]

	ai_hand.erase(chosen_hand_card)
	_layout_hand(ai_hand, ai_hand_container.size, false)
	chosen_hand_card.set_face_up(true)

	if target_fc != null and field_cards.has(target_fc):
		field_cards.erase(target_fc)
		_capture_cards([chosen_hand_card, target_fc], false)
		_layout_field()
		await _wait(0.25)
		_execute_draw_phase(false)
	else:
		# Check if any matches existed
		var matches: Array = KoiKoiEvaluator.find_field_matches(chosen_hand_card.card_data, field_cards)
		if matches.is_empty():
			field_cards.append(chosen_hand_card)
			chosen_hand_card.reparent(field_container)
			_layout_field()
			await _wait(0.2)
			_execute_draw_phase(false)
		elif matches.size() == 1:
			var mfc: HanafudaCard = matches[0]
			field_cards.erase(mfc)
			_capture_cards([chosen_hand_card, mfc], false)
			_layout_field()
			await _wait(0.25)
			_execute_draw_phase(false)
		elif matches.size() == 2:
			var best_m = KoiKoiAI.choose_best_field_match(matches, chosen_hand_card.card_data, ai_captured, player_captured)
			field_cards.erase(best_m)
			_capture_cards([chosen_hand_card, best_m], false)
			_layout_field()
			await _wait(0.25)
			_execute_draw_phase(false)
		elif matches.size() >= 3:
			for m in matches:
				field_cards.erase(m)
			var clist = [chosen_hand_card]
			clist.append_array(matches)
			_capture_cards(clist, false)
			_layout_field()
			await _wait(0.25)
			_execute_draw_phase(false)

# --- Koi-Koi Decisions & Round Finish ---

func _show_player_koikoi_modal(eval: Dictionary) -> void:
	var y_text: String = ""
	for y in eval.get("yaku_list", []):
		y_text += "• %s (%d pts)\n" % [y.get("name"), y.get("points")]

	var base_pts: int = eval.get("total_points", 0)
	var final_calc = KoiKoiEvaluator.calculate_final_score(base_pts, ai_called_koikoi)

	koikoi_yaku_list_lbl.text = y_text
	var pts_str: String = "Base: %d pts" % base_pts
	if final_calc.multiplier > 1:
		pts_str += "  →  Multiplier x%d = %d pts!" % [final_calc.multiplier, final_calc.final_points]
	koikoi_points_lbl.text = pts_str

	koikoi_modal.visible = true

func _on_player_called_koikoi() -> void:
	koikoi_modal.visible = false
	player_called_koikoi = true
	var eval = KoiKoiEvaluator.evaluate_yaku(player_captured, viewing_yaku_enabled)
	player_last_yaku_pts = eval.get("total_points", 0)

	GameSettings.record_koikoi_round(false, 0, true)
	_show_callout("KOI-KOI!", 1.5)
	await _wait(1.5)

	is_player_turn = false
	_start_next_turn()

func _on_player_called_shoubu() -> void:
	koikoi_modal.visible = false
	var eval = KoiKoiEvaluator.evaluate_yaku(player_captured, viewing_yaku_enabled)
	_show_callout("SHOUBU (STOP)!", 1.5)
	await _wait(1.5)
	_end_round_with_win(true, eval)

func _end_round_with_win(is_human: bool, eval: Dictionary) -> void:
	round_in_progress = false
	turn_state = TurnState.ROUND_OVER

	var base_pts: int = eval.get("total_points", 0)
	var opp_called = ai_called_koikoi if is_human else player_called_koikoi
	var final_calc = KoiKoiEvaluator.calculate_final_score(base_pts, opp_called)
	var awarded_pts: int = final_calc.final_points

	if is_human:
		player_total_score += awarded_pts
		current_dealer_is_player = true
		GameSettings.record_koikoi_round(true, awarded_pts, player_called_koikoi)
		round_title_lbl.text = "ROUND WON!"
		round_title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.38))
	else:
		ai_total_score += awarded_pts
		current_dealer_is_player = false
		GameSettings.record_koikoi_round(false, 0, false)
		round_title_lbl.text = "ROUND LOST"
		round_title_lbl.add_theme_color_override("font_color", Color(0.92, 0.35, 0.38))

	_update_header_ui()

	var details: String = ""
	for y in eval.get("yaku_list", []):
		details += "%s: %d pts\n" % [y.get("name"), y.get("points")]

	if not final_calc.reasons.is_empty():
		details += "\nBonuses:\n"
		for r in final_calc.reasons:
			details += "★ %s\n" % r

	details += "\nTotal Awarded: %d points" % awarded_pts
	round_details_lbl.text = details

	round_dialog.visible = true

func _end_round_instant(is_human: bool, pts: int, reason: String) -> void:
	round_in_progress = false
	turn_state = TurnState.ROUND_OVER

	if is_human:
		player_total_score += pts
		current_dealer_is_player = true
		round_title_lbl.text = "INSTANT VICTORY!"
	else:
		ai_total_score += pts
		current_dealer_is_player = false
		round_title_lbl.text = "INSTANT DEFEAT"

	_update_header_ui()
	round_details_lbl.text = "%s\nAwarded: %d points" % [reason, pts]
	round_dialog.visible = true

func _handle_round_draw() -> void:
	round_in_progress = false
	turn_state = TurnState.ROUND_OVER
	round_title_lbl.text = "DRAW (O-NAGARE)"
	round_title_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	round_details_lbl.text = "Both hands emptied without a call.\nNo points awarded."
	round_dialog.visible = true

func _on_next_round_clicked() -> void:
	round_dialog.visible = false
	current_round += 1
	if current_round > total_rounds:
		_finish_match()
	else:
		_start_round()

func _finish_match() -> void:
	turn_state = TurnState.MATCH_OVER
	var won: bool = player_total_score > ai_total_score
	GameSettings.record_koikoi_match(won)

	if player_total_score > ai_total_score:
		match_title_lbl.text = "MATCH VICTORY! 🏆"
		match_title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.38))
	elif player_total_score < ai_total_score:
		match_title_lbl.text = "MATCH DEFEAT"
		match_title_lbl.add_theme_color_override("font_color", Color(0.92, 0.35, 0.38))
	else:
		match_title_lbl.text = "MATCH TIED"
		match_title_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))

	match_details_lbl.text = "Final Scores:\nYou: %d pts   |   Opponent: %d pts" % [player_total_score, ai_total_score]
	match_dialog.visible = true

func _show_callout(text: String, duration: float = 1.4) -> void:
	if callout_banner == null or callout_label == null:
		return
	callout_label.text = text
	callout_banner.visible = true
	callout_banner.modulate.a = 0.0
	callout_banner.scale = Vector2(0.8, 0.8)

	var tw = create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(callout_banner, "modulate:a", 1.0, 0.18)
	tw.tween_property(callout_banner, "scale", Vector2.ONE, 0.18)

	if not is_instant_mode:
		await _wait(duration)
		var out_tw = create_tween()
		out_tw.tween_property(callout_banner, "modulate:a", 0.0, 0.18)
		out_tw.tween_callback(func(): callout_banner.visible = false)
	else:
		callout_banner.visible = false

func _on_rules_clicked() -> void:
	# Show a helpful quick rules toast
	status_banner.text = "Match cards of the same month to capture them. Form Yaku (Brights, Animals, Ribbons, Plains) to score!"

func _wait(sec: float) -> void:
	if is_instant_mode:
		return
	await get_tree().create_timer(sec).timeout
