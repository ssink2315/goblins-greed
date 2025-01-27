extends Node

# Signals
signal action_selected(action: String, target: BaseCharacter)
signal targeting_started(valid_targets: Array)
signal targeting_ended

# Current state
var combat_manager: Node
var current_character: BaseCharacter
var current_action: String
var valid_targets: Array
var targeting_active: bool = false

# UI References
@onready var combat_ui: CanvasLayer = get_node("../CombatUI")
@onready var target_selector: Control = combat_ui.get_node("TargetSelector") if combat_ui else null

func _ready():
	combat_manager = get_parent()
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.turn_ended.connect(_on_turn_ended)
	if combat_ui and target_selector:
		_connect_signals()

func _connect_signals():
	# Connect UI button signals
	var action_menu = combat_ui.get_node("ActionMenu/Actions")
	action_menu.get_node("AttackButton").pressed.connect(_on_attack_pressed)
	action_menu.get_node("SkillButton").pressed.connect(_on_skill_pressed)
	action_menu.get_node("ItemButton").pressed.connect(_on_item_pressed)
	action_menu.get_node("DefendButton").pressed.connect(_on_defend_pressed)
	action_menu.get_node("MoveButton").pressed.connect(_on_move_pressed)

func _unhandled_input(event: InputEvent):
	if !targeting_active:
		return
		
	if event.is_action_pressed("cancel"):
		_cancel_targeting()
	elif event is InputEventMouseButton and event.pressed:
		_handle_target_selection()

func take_turn(character: BaseCharacter):
	current_character = character
	# UI will handle action selection through signals

func select_action(action: String):
	current_action = action
	valid_targets = _get_valid_targets(action)
	
	if valid_targets.is_empty():
		return
	
	targeting_active = true
	targeting_started.emit(valid_targets)

func select_target(target: BaseCharacter):
	if !targeting_active or !target in valid_targets:
		return
	
	targeting_active = false
	targeting_ended.emit()
	action_selected.emit(current_action, target)

func _cancel_targeting():
	targeting_active = false
	targeting_ended.emit()
	current_action = ""
	valid_targets.clear()

func _handle_target_selection():
	var mouse_pos = get_viewport().get_mouse_position()
	for target in valid_targets:
		if target.get_rect().has_point(mouse_pos):
			select_target(target)
			break

func _get_valid_targets(action: String) -> Array:
	match action:
		"Attack":
			return combat_manager.enemy_party.filter(func(c): return c.is_alive())
		"Skill":
			var skill = current_character.selected_skill
			if skill.is_support:
				return combat_manager.player_party.filter(func(c): return c.is_alive())
			return combat_manager.enemy_party.filter(func(c): return c.is_alive())
		"Item":
			var item = current_character.selected_item
			if item.is_support:
				return combat_manager.player_party.filter(func(c): return c.is_alive())
			return combat_manager.enemy_party.filter(func(c): return c.is_alive())
		"Defend":
			return [current_character]
	return []

func _on_turn_started(character: BaseCharacter):
	if character.is_player:
		take_turn(character)

func _on_turn_ended(_character: BaseCharacter):
	targeting_active = false
	current_action = ""
	valid_targets.clear()

func can_use_action(action: String) -> bool:
	match action:
		"Attack":
			return true
		"Skill":
			return current_character.learned_skills.size() > 0 and current_character.current_mp > 0
		"Item":
			return current_character.has_usable_items()
		"Defend":
			return true
	return false

func _on_attack_pressed():
	select_action("Attack")

func _on_skill_pressed():
	if not current_character.has_usable_skills():
		return
	select_action("Skill")

func _on_item_pressed():
	if not current_character.has_usable_items():
		return
	select_action("Item")

func _on_defend_pressed():
	select_action("Defend")

func _on_move_pressed():
	var new_row = CombatEnums.Row.BACK if current_character.current_row == CombatEnums.Row.FRONT else CombatEnums.Row.FRONT
	action_selected.emit("Move", current_character)
