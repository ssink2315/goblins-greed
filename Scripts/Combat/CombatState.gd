extends Node2D

# Enums for combat states and types
enum State { INITIALIZING, PLAYER_TURN, ENEMY_TURN, ANIMATING, FINISHED }
enum Type { STORY, RANDOM_ENCOUNTER }
enum Row { FRONT, BACK }
enum ActionType { ATTACK, DEFEND, SKILL, ITEM }

# Combat modifiers
const BACK_ROW_DAMAGE_MOD = 0.85
const BACK_ROW_DEFENSE_MOD = 1.15

signal state_changed(new_state: State)
signal turn_started(unit: BaseCharacter)
signal turn_ended(unit: BaseCharacter)
signal combat_ended(victory: bool)

var current_state = State.INITIALIZING
var combat_type = Type.RANDOM_ENCOUNTER
var active_unit: BaseCharacter
var party_members: Array[BaseCharacter] = []
var enemies: Array[BaseCharacter] = []
var turn_order: Array[BaseCharacter] = []
var current_turn_index = 0

func change_state(new_state: State):
	current_state = new_state
	state_changed.emit(new_state)

func start_combat(type: Type, party: Array, enemy_group: Array):
	combat_type = type
	party_members = party
	enemies = enemy_group
	_initialize_turn_order()
	change_state(State.PLAYER_TURN)

func _initialize_turn_order():
	turn_order.clear()
	turn_order.append_array(party_members)
	turn_order.append_array(enemies)
	turn_order.sort_custom(func(a, b): return a.speed > b.speed)
	current_turn_index = 0

func start_next_turn():
	if current_state == State.FINISHED:
		return
		
	active_unit = turn_order[current_turn_index]
	
	# Skip dead units
	while not active_unit.is_alive():
		current_turn_index = (current_turn_index + 1) % turn_order.size()
		active_unit = turn_order[current_turn_index]
	
	if active_unit in party_members:
		change_state(State.PLAYER_TURN)
	else:
		change_state(State.ENEMY_TURN)
	
	turn_started.emit(active_unit)

func end_current_turn():
	turn_ended.emit(active_unit)
	current_turn_index = (current_turn_index + 1) % turn_order.size()
	
	if check_combat_end():
		return
		
	start_next_turn()

func check_combat_end():
	if are_all_enemies_defeated():
		change_state(State.FINISHED)
		combat_ended.emit(true)
		return true
	
	if is_party_defeated():
		change_state(State.FINISHED)
		combat_ended.emit(false)
		return true
	
	return false

func are_all_enemies_defeated():
	return enemies.all(func(enemy): return not enemy.is_alive())

func is_party_defeated():
	return party_members.all(func(member): return not member.is_alive())

func get_valid_targets(for_unit: BaseCharacter):
	if for_unit in party_members:
		return enemies.filter(func(enemy): return enemy.is_alive())
	return party_members.filter(func(member): return member.is_alive())

func apply_row_modifiers(damage: int, attacker: BaseCharacter):
	if attacker.current_row == Row.BACK:
		damage = int(damage * BACK_ROW_DAMAGE_MOD)
	return damage
