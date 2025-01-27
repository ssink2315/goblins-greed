extends Node

signal combat_started(party: Array, enemies: Array)
signal combat_state_changed(new_state: int)
signal turn_started(unit: BaseCharacter)
signal turn_ended(unit: BaseCharacter)
signal action_performed(unit: BaseCharacter, action: Dictionary)
signal damage_dealt(attacker: BaseCharacter, target: BaseCharacter, amount: int, element: String)
signal combat_ended(result: String)
signal row_changed(unit: BaseCharacter, new_row: int)
signal status_effect_applied(unit: BaseCharacter, effect: Dictionary)
signal status_effect_removed(unit: BaseCharacter, effect_id: String)
signal mana_spent(unit: BaseCharacter, amount: int)
signal round_started(round_number: int)
signal round_ended(round_number: int)
signal rewards_ready(exp: int, gold: int, drops: Array)
signal level_up(character: BaseCharacter, new_level: int, stat_increases: Dictionary)
signal summon_added(summoner: BaseCharacter, summon: BaseCharacter, position: Vector2)
signal summon_removed(summon: BaseCharacter)
signal summon_state_changed(summon: BaseCharacter, state: Dictionary)
signal summon_effect_applied(summon: BaseCharacter, effect: Dictionary)
signal summon_link_broken(summoner: BaseCharacter, summon: BaseCharacter)
signal summon_failed(summoner: BaseCharacter, message: String)
signal summon_expired(summon: BaseCharacter)
signal summon_duration_updated(summon: BaseCharacter, turns_remaining: int)
signal summon_animation_started(summon: BaseCharacter, animation_type: String)
signal summon_animation_finished(summon: BaseCharacter)
signal summon_behavior_changed(summon: BaseCharacter, new_behavior: int)
signal summon_turn_started(summon: BaseCharacter)
signal summon_turn_ended(summon: BaseCharacter)
signal summon_ai_decision_made(summon: BaseCharacter, action: Dictionary)
signal summon_ai_state_updated(summon: BaseCharacter, state: Dictionary)
signal summon_target_changed(summon: BaseCharacter, target: BaseCharacter)
signal summon_strategy_changed(summon: BaseCharacter, strategy: int)
signal summon_effect_triggered(unit: BaseCharacter, effect: Dictionary)
signal summon_link_effect_updated(summoner: BaseCharacter, summon: BaseCharacter, effect: Dictionary)
signal summon_stats_updated(summon: BaseCharacter, old_stats: Dictionary, new_stats: Dictionary)
signal summon_combat_message(message: String, color: Color)
signal summon_status_message(summon: BaseCharacter, status: String, color: Color)
signal summon_position_updated(summon: BaseCharacter, new_position: Vector2)
signal summon_animation_queued(summon: BaseCharacter, anim_name: String)
signal summon_effect_spawned(effect_scene: PackedScene, position: Vector2)
signal summon_range_updated(summon: BaseCharacter, range_data: Dictionary)
signal summon_position_changed(summon: BaseCharacter, old_pos: Vector2, new_pos: Vector2)
signal summon_formation_updated(side: Array, formation: Dictionary)
signal summon_range_check_failed(summon: BaseCharacter, target: BaseCharacter)
signal summon_position_invalid(summon: BaseCharacter, position: Vector2)
signal summon_formation_broken(summon: BaseCharacter)
signal unit_position_changed(unit: BaseCharacter, old_pos: Vector2, new_pos: Vector2)
signal unit_stats_changed(unit: BaseCharacter, old_stats: Dictionary, new_stats: Dictionary)
signal skill_cooldown_updated(unit: BaseCharacter, skill: Skill, remaining: int)
signal resource_changed(unit: BaseCharacter, resource_type: String, amount: int)
signal resource_depleted(unit: BaseCharacter, resource_type: String)
signal condition_triggered(unit: BaseCharacter, condition: String)
signal resistance_check_failed(unit: BaseCharacter, effect_type: String)
signal immunity_triggered(unit: BaseCharacter, effect_type: String)
signal action_interrupted(unit: BaseCharacter, action: Dictionary)
signal action_cancelled(action: Dictionary)
signal target_selection_cancelled()
signal turn_skipped(unit: BaseCharacter, reason: String)
signal counter_triggered(source: BaseCharacter, target: BaseCharacter, action: Dictionary)
signal reaction_triggered(source: BaseCharacter, target: BaseCharacter, reaction_type: String)
signal rewards_distributed(rewards: Dictionary)
signal unit_leveled_up(unit: BaseCharacter)
signal combat_message(text: String, color: Color)
signal unit_stats_updated(unit: BaseCharacter)
signal turn_order_changed(order: Array)
signal action_animation_started(action: Dictionary)
signal action_animation_finished(action: Dictionary)
signal action_started(action: Dictionary)
signal action_completed(action: Dictionary)
signal combo_updated(count: int, multiplier: float)
signal combat_stats_updated(stats: Dictionary)

# Add combat flow states and signals
signal combat_flow_state_changed(old_state: String, new_state: String)
signal action_queued(action: Dictionary)
signal state_recovered(previous_state: String)

# Add error handling signals (keep existing signals)
signal error_occurred(error: Dictionary)
signal error_recovered(error: Dictionary)
signal state_saved(state: Dictionary)
signal state_loaded(state: Dictionary)

# Add error types while keeping existing enums
const ERROR_TYPES = {
	"INVALID_ACTION": "Invalid action attempted",
	"INVALID_STATE": "Invalid combat state",
	"RESOURCE_DEPLETED": "Required resource depleted",
	"TARGET_INVALID": "Invalid target",
	"INTERRUPTED": "Action interrupted",
	"STATE_CORRUPTION": "Combat state corruption detected"
}

# Add state management (preserve existing variables)
var state_history: Array[Dictionary] = []
var max_history_size: int = 10
var error_log: Array[Dictionary] = []

enum CombatFlowState {
	IDLE,
	SELECTING_ACTION,
	SELECTING_TARGET,
	EXECUTING_ACTION,
	PROCESSING_EFFECTS,
	TRANSITIONING,
	INTERRUPTED,
	CANCELLING
}

var current_flow_state: int = CombatFlowState.IDLE
var action_queue: Array[Dictionary] = []
var interrupted_action: Dictionary
var previous_state: int

@onready var player_control = $PlayerControl
@onready var ai_control = $AIControl
@onready var combat_calculator = $CombatCalculator
@onready var combat_ui = $CombatUI
@onready var turn_manager = $TurnOrderManager
@onready var action_resolver = $ActionResolver
@onready var combat_rewards = $CombatRewards

var current_state = CombatEnums.CombatState.INITIALIZING
var combat_type = CombatEnums.CombatType.RANDOM_ENCOUNTER
var active_unit: BaseCharacter
var player_party: Array[BaseCharacter] = []
var enemy_party: Array[BaseCharacter] = []
var front_row: Array[BaseCharacter] = []
var back_row: Array[BaseCharacter] = []
var round_number: int = 1
var combat_log: Array = []
var max_log_entries: int = 50
var max_units_per_side := 12
var summons: Dictionary = {} # key: summon, value: summoner
var summon_durations: Dictionary = {} # key: summon, value: turns_remaining
var current_phase: CombatPhase = CombatPhase.INIT
var is_processing_action: bool = false

# Enhance combat statistics system
var combat_stats: Dictionary = {
	# Existing stats
	"rounds": 0,
	"total_damage_dealt": 0,
	"total_healing_done": 0,
	"actions_taken": 0,
	"critical_hits": 0,
	"status_effects_applied": 0,
	"items_used": 0,
	"skills_used": 0,
	
	# New detailed stats
	"damage_by_type": {
		"physical": 0,
		"magical": 0,
		"true": 0
	},
	"damage_by_element": {},  # Will be populated with elements as they occur
	"healing_by_source": {
		"skills": 0,
		"items": 0,
		"effects": 0
	},
	"mana_usage": {
		"spent": 0,
		"regenerated": 0
	},
	"status_effects": {
		"applied": {},  # Effect name -> count
		"resisted": 0,
		"cleansed": 0
	},
	"combat_flow": {
		"turns_taken": 0,
		"actions_per_turn": [],
		"average_turn_duration": 0.0
	}
}

var unit_stats: Dictionary = {}  # Tracks per-unit statistics

# Add these reward-related variables
var combat_rewards: Dictionary = {
	"exp": 0,
	"gold": 0,
	"items": [],
	"bonus_multiplier": 1.0
}

# Add combo system variables
var combo_counter: int = 0
var last_attacker_side: String = ""  # "player" or "enemy"

# Add counter system variables and signals
signal counter_triggered(source: BaseCharacter, target: BaseCharacter, action: Dictionary)

# Counter chances and conditions
const COUNTER_BASE_CHANCE = 0.2  # 20% base counter chance
const COUNTER_DAMAGE_MOD = 0.7   # Counter attacks deal 70% damage

const ROW_MODIFIERS = {
	"BACK_ROW_DAMAGE_MOD": 0.75,  # Back row deals 75% damage
	"BACK_ROW_DEFENSE_MOD": 1.25  # Back row takes 75% damage (1/0.75)
}

const ROW_POSITIONS = {
	"player": {
		"front": Vector2(300, 300),
		"back": Vector2(200, 300),
		"spacing": Vector2(0, 80)
	},
	"enemy": {
		"front": Vector2(700, 300),
		"back": Vector2(800, 300),
		"spacing": Vector2(0, 80)
	}
}

enum CombatPhase {
	INIT,
	START_TURN,
	ACTION_SELECT,
	TARGET_SELECT,
	ACTION_EXECUTE,
	END_TURN
}

# Add turn order management
var current_unit: BaseCharacter = null
var speed_variance: float = 0.1

# Add reaction system variables and signals
signal reaction_triggered(source: BaseCharacter, target: BaseCharacter, reaction_type: String)

const REACTION_TYPES = {
	"GUARD_ALLY": {
		"chance": 0.3,
		"damage_reduction": 0.5
	},
	"AUTO_HEAL": {
		"hp_threshold": 0.3,
		"heal_amount": 0.2
	},
	"PROTECT_BACK": {
		"chance": 0.4,
		"requirement": "front_row"
	}
}

# Add status effect system variables and signals
signal status_effect_applied(unit: BaseCharacter, effect: Dictionary)
signal status_effect_removed(unit: BaseCharacter, effect_id: String)
signal status_effect_triggered(unit: BaseCharacter, effect: Dictionary)

const STATUS_PRIORITIES = {
	"CONTROL": 0,    # Stun, Sleep, etc. process first
	"DAMAGE": 1,     # DoT effects like Poison, Burn
	"BUFF": 2,      # Positive effects
	"DEBUFF": 3     # Negative effects
}

# Add resource management variables and signals
signal resource_changed(unit: BaseCharacter, resource_type: String, amount: int)
signal resource_depleted(unit: BaseCharacter, resource_type: String)

const MP_REGEN_PER_TURN = 5  # Base MP regeneration per turn
const LOW_MP_THRESHOLD = 0.2  # 20% MP threshold for "low mana" state

# Add speed control constants and variables
const SPEED_MULTIPLIERS = {
	"SLOW": 0.5,
	"NORMAL": 1.0,
	"FAST": 2.0
}

var current_speed: float = SPEED_MULTIPLIERS.NORMAL
signal combat_speed_changed(new_speed: float)

func _ready():
	player_control.action_chosen.connect(_on_action_chosen)
	ai_control.action_chosen.connect(_on_action_chosen)
	action_resolver.action_resolved.connect(_on_action_resolved)
	turn_manager = TurnOrderManager.new()
	turn_manager.turn_order_updated.connect(_on_turn_order_updated)

func start_combat(type: int, party: Array, enemies: Array):
	current_state = CombatEnums.CombatState.INITIALIZING
	combat_type = type
	player_party = party
	enemy_party = enemies
	round_number = 1
	
	_organize_rows()
	_position_units()
	turn_manager.initialize_turn_order(party + enemies)
	
	combat_started.emit(party, enemies)
	combat_ui.combat_log.add_combat_start_message(party.size(), enemies.size())
	combat_ui.update_turn_order(turn_manager.current_order)
	
	round_started.emit(round_number)
	combat_ui.combat_log.add_round_start_message(round_number)
	
	start_next_turn()

func _organize_rows():
	front_row.clear()
	back_row.clear()
	
	for unit in player_party + enemy_party:
		if unit.is_alive():
			if unit.current_row == CombatEnums.Row.FRONT:
				front_row.append(unit)
			else:
				back_row.append(unit)

func _position_units():
	# Position player party
	var front_count = 0
	var back_count = 0
	
	for unit in player_party:
		var base_pos = ROW_POSITIONS.player.front if unit.current_row == CombatEnums.Row.FRONT else ROW_POSITIONS.player.back
		var offset = ROW_POSITIONS.player.spacing * (front_count if unit.current_row == CombatEnums.Row.FRONT else back_count)
		unit.position = base_pos + offset
		
		if unit.current_row == CombatEnums.Row.FRONT:
			front_count += 1
		else:
			back_count += 1
	
	# Position enemy party
	front_count = 0
	back_count = 0
	
	for unit in enemy_party:
		var base_pos = ROW_POSITIONS.enemy.front if unit.current_row == CombatEnums.Row.FRONT else ROW_POSITIONS.enemy.back
		var offset = ROW_POSITIONS.enemy.spacing * (front_count if unit.current_row == CombatEnums.Row.FRONT else back_count)
		unit.position = base_pos + offset
		
		if unit.current_row == CombatEnums.Row.FRONT:
			front_count += 1
		else:
			back_count += 1

func start_next_turn():
	if check_combat_end():
		return
		
	current_unit = turn_manager.get_next_unit()
	if not current_unit:
		return
	
	# Process start of turn effects
	process_status_effects(current_unit)
	current_unit.start_turn()
	
	if _check_turn_skip(current_unit):
		_end_current_turn()
		return
	
	combat_message.emit("%s's turn" % current_unit.character_name, Color.YELLOW)
	turn_started.emit(current_unit)
	_update_combat_ui()
	
	# Set state based on unit type
	current_state = CombatEnums.CombatState.PLAYER_TURN if current_unit in player_party else CombatEnums.CombatState.ENEMY_TURN
	combat_state_changed.emit(current_state)
	
	# Handle AI turns automatically
	if current_unit not in player_party:
		_queue_ai_action()

func _queue_ai_action():
	if not current_unit or current_unit in player_party:
		return
		
	# Get AI action based on role and position
	var action = _get_enemy_ai_action()
	action_queue.append(action)
	_process_action_queue()

func _get_enemy_ai_action() -> Dictionary:
	# Check if unit should change rows first
	var row_action = _get_row_change_decision()
	if not row_action.is_empty():
		return row_action
		
	# Check if unit should heal
	if current_unit.should_heal():
		var heal_action = ai_control.get_heal_action(current_unit)
		if not heal_action.is_empty():
			return heal_action
	
	# Get attack action based on position
	return _get_position_based_attack()

func _get_row_change_decision() -> Dictionary:
	# Get current row situation
	var front_allies = enemy_party.filter(func(unit): 
		return unit.is_alive() and unit.current_row == CombatEnums.Row.FRONT
	)
	var back_allies = enemy_party.filter(func(unit): 
		return unit.is_alive() and unit.current_row == CombatEnums.Row.BACK
	)
	
	# Decision factors
	var is_low_health = current_unit.current_hp < (current_unit.max_hp * 0.3)
	var is_ranged = current_unit.is_ranged
	var is_in_front = current_unit.current_row == CombatEnums.Row.FRONT
	
	# Move to back row if:
	# 1. Low health and other front row allies exist
	# 2. Ranged unit in front with other front row allies
	if is_in_front and (
		(is_low_health and front_allies.size() > 1) or
		(is_ranged and front_allies.size() > 1)
	):
		return {
			"type": CombatEnums.ActionType.MOVE,
			"source": current_unit,
			"target_row": CombatEnums.Row.BACK
		}
	
	# Move to front row if:
	# 1. No front row allies and unit isn't critically low
	# 2. Melee unit in back with no front row protection
	if not is_in_front and (
		(front_allies.is_empty() and not is_low_health) or
		(not is_ranged and front_allies.is_empty())
	):
		return {
			"type": CombatEnums.ActionType.MOVE,
			"source": current_unit,
			"target_row": CombatEnums.Row.FRONT
		}
	
	return {}

func _get_position_based_attack() -> Dictionary:
	var possible_targets = get_valid_targets(current_unit, CombatEnums.ActionType.ATTACK)
	if possible_targets.is_empty():
		return {
			"type": CombatEnums.ActionType.DEFEND,
			"source": current_unit
		}
	
	# Prioritize targets based on position
	var front_targets = possible_targets.filter(func(unit): 
		return unit.current_row == CombatEnums.Row.FRONT
	)
	var back_targets = possible_targets.filter(func(unit): 
		return unit.current_row == CombatEnums.Row.BACK
	)
	
	var target
	if current_unit.is_ranged:
		# Ranged units prioritize back row squishies
		target = back_targets.pick_random() if not back_targets.is_empty() else front_targets.pick_random()
	else:
		# Melee units attack what they can reach
		target = front_targets.pick_random() if not front_targets.is_empty() else back_targets.pick_random()
	
	return {
		"type": CombatEnums.ActionType.ATTACK,
		"source": current_unit,
		"target": target
	}

func _process_action_queue():
	if is_processing_action or action_queue.is_empty():
		return
		
	is_processing_action = true
	var action = action_queue.pop_front()
	
	if not _validate_action(action):
		_handle_action_failure(action, "Invalid action")
		return
	
	match action.type:
		CombatEnums.ActionType.ATTACK:
			await _process_attack(action)
		CombatEnums.ActionType.DEFEND:
			await _process_defend(action)
		CombatEnums.ActionType.SKILL:
			await _process_skill(action)
		CombatEnums.ActionType.ITEM:
			await _process_item(action)
	
	is_processing_action = false
	_update_combat_ui()
	advance_combat_state()

func _process_attack(action: Dictionary):
	var source = action.source
	var target = action.target
	
	# Calculate and apply initial damage
	var damage = source.get_attack_damage()
	if target.is_defending:
		damage = int(damage * 0.5)
	
	# Apply row modifiers
	if target.current_row == CombatEnums.Row.BACK:
		damage = int(damage * CombatEnums.BACK_ROW_DAMAGE_MOD)
	
	# Check for counter attack
	var counter_action = _check_counter_attack(target, source, damage)
	
	# Apply main attack damage
	combat_message.emit("%s attacks %s!" % [source.character_name, target.character_name], Color.WHITE)
	await get_tree().create_timer(0.2).timeout
	
	target.take_damage(damage)
	combat_message.emit("%s takes %d damage!" % [target.character_name, damage], Color.RED)
	
	# Process counter if triggered
	if counter_action:
		await _process_counter_attack(counter_action)

func _check_counter_attack(defender: BaseCharacter, attacker: BaseCharacter, incoming_damage: int) -> Dictionary:
	# Check if unit can counter (not stunned, has counter ability)
	if defender.is_stunned() or not defender.can_counter():
		return {}
	
	# Calculate counter chance
	var counter_chance = COUNTER_BASE_CHANCE
	
	# Modify chance based on conditions
	if defender.is_defending:
		counter_chance *= 1.5
	if defender.current_hp < (defender.max_hp * 0.3):
		counter_chance *= 1.2
	
	# Roll for counter
	if randf() <= counter_chance:
		return {
			"type": CombatEnums.ActionType.ATTACK,
			"source": defender,
			"target": attacker,
			"is_counter": true,
			"damage_mod": COUNTER_DAMAGE_MOD
		}
	
	return {}

func _process_counter_attack(counter_action: Dictionary):
	var source = counter_action.source
	var target = counter_action.target
	
	combat_message.emit("%s counters!" % source.character_name, Color.YELLOW)
	await get_tree().create_timer(0.2).timeout
	
	var damage = int(source.get_attack_damage() * counter_action.damage_mod)
	target.take_damage(damage)
	
	combat_message.emit("%s takes %d counter damage!" % [target.character_name, damage], Color.ORANGE)
	counter_triggered.emit(source, target, counter_action)

func _process_defend(action: Dictionary):
	var unit = action.source
	unit.is_defending = true
	combat_message.emit("%s takes a defensive stance!" % [unit.character_name], Color.YELLOW)
	await get_tree().create_timer(0.2).timeout

func _process_skill(action: Dictionary):
	var source = action.source
	var skill = action.skill
	var target = action.target
	
	# Check MP cost
	if not source.spend_mp(skill.mp_cost):
		_handle_action_failure(action, "Not enough MP!")
		return
	
	combat_message.emit("%s uses %s!" % [source.character_name, skill.name], Color.AQUA)
	await get_tree().create_timer(0.2).timeout
	
	# Process skill effects
	for effect in skill.effects:
		match effect.type:
			"damage":
				var damage = effect.base_value + (source.magic * effect.scaling)
				target.take_damage(damage)
				combat_stats.total_damage_dealt += damage
			"heal":
				var heal = effect.base_value + (source.magic * effect.scaling)
				target.heal(heal)
				combat_stats.total_healing_done += heal
			"status":
				target.add_status_effect(effect.status_effect)
				combat_stats.status_effects.applied[effect.status_effect.effect_name] = combat_stats.status_effects.applied.get(effect.status_effect.effect_name, 0) + 1

func _process_item(action: Dictionary):
	var source = action.source
	var item = action.item
	var target = action.target
	
	if not source.consume_item(item):
		_handle_action_failure(action, "Item not available!")
		return
	
	combat_message.emit("%s uses %s!" % [source.character_name, item.name], Color.GREEN)
	await get_tree().create_timer(0.2).timeout
	
	# Process item effects
	for effect in item.effects:
		match effect.type:
			"heal":
				target.heal(effect.value)
				combat_stats.total_healing_done += effect.value
				combat_stats.healing_by_source.items += effect.value
			"status_cure":
				target.remove_status_effect(effect.status_type)

func _validate_action(action: Dictionary) -> bool:
	if not action.has_all(["type", "source"]):
		return false
		
	var unit = action.source
	if not unit.is_alive() or unit != current_unit:
		return false
		
	match action.type:
		CombatEnums.ActionType.ATTACK:
			return action.has("target") and action.target.is_alive()
		CombatEnums.ActionType.DEFEND:
			return true
		CombatEnums.ActionType.SKILL:
			return action.has_all(["skill", "target"]) and unit.can_use_skill(action.skill)
		CombatEnums.ActionType.ITEM:
			return action.has_all(["item", "target"]) and unit.has_item(action.item)
	return false

func _handle_action_failure(action: Dictionary, reason: String):
	combat_message.emit(reason, Color.RED)
	if action.has("source"):
		unit_stats_updated.emit(action.source)
	
	# Move to next turn if no more actions
	if action_queue.is_empty():
		start_next_turn()

func _check_action_interruption(unit: BaseCharacter, action: Dictionary) -> bool:
	if unit.is_stunned():
		return true
	if unit.is_silenced() and action.type == "skill":
		return true
	if unit.is_confused() and randf() < 0.5:  # 50% chance to fail when confused
		return true
	return false

func _process_action_result(result: Dictionary):
	if result.is_empty():
		return
		
	# Check if this action breaks combo
	if result.type == "damage":
		var source_side = "player" if result.source in player_party else "enemy"
		if source_side != last_attacker_side:
			combo_counter = 0
			last_attacker_side = ""
			combo_updated.emit(0, 1.0)
	
	# Continue with existing action processing
	action_animation_started.emit(result)
	
	match result.type:
		"damage":
			_show_combat_message("%s deals %d damage to %s" % [
				result.source.character_name,
				result.amount,
				result.target.character_name
			], Color.RED)
			await _apply_damage(result.source, result.target, result.amount)
			
		"skill":
			_show_combat_message("%s uses %s!" % [
				result.source.character_name,
				result.skill.name
			], Color.AQUA)
			await _apply_skill_effects(result)
			
		"item":
			_show_combat_message("%s uses %s" % [
				result.source.character_name,
				result.item.name
			], Color.GREEN)
			await _apply_item_effects(result)
			
		"defend":
			_show_combat_message("%s takes a defensive stance" % [
				result.source.character_name
			], Color.YELLOW)
			_apply_defend_effect(result.source)
	
	# Signal animation end
	action_animation_finished.emit(result)
	
	# Update UI
	_update_combat_ui()
	
	is_processing_action = false
	if action_queue.is_empty():
		advance_combat_state()

func _apply_damage(attacker: BaseCharacter, target: BaseCharacter, amount: int):
	target.take_damage(amount)
	damage_dealt.emit(attacker, target, amount, "physical")

func _apply_skill_effects(result: Dictionary):
	update_combat_stats("skills_used", 1, result.source)
	update_combat_stats("actions_taken", 1, result.source)
	
	for effect in result.effects:
		match effect.type:
			"damage":
				update_combat_stats("total_damage_dealt", effect.amount)
				update_combat_stats("damage_dealt", effect.amount, result.source)
				update_combat_stats("damage_taken", effect.amount, result.target)
			"heal":
				update_combat_stats("total_healing_done", effect.amount)
				update_combat_stats("healing_done", effect.amount, result.source)
				update_combat_stats("healing_received", effect.amount, result.target)
			"status":
				update_combat_stats("status_effects_applied", 1, result.source)
	
	if result.result == ActionResolver.ActionResult.FAILED:
		combat_ui.show_message(result.reason)
		await get_tree().create_timer(0.5).timeout
		return
	
	combat_ui.combat_log.add_skill_message(
		result.source.character_name,
		result.skill.name,
		result.target.character_name
	)
	
	await get_tree().create_timer(0.2).timeout

func _apply_item_effects(result: Dictionary):
	update_combat_stats("items_used", 1, result.source)
	update_combat_stats("actions_taken", 1, result.source)
	
	for effect in result.effects:
		match effect.type:
			"heal":
				update_combat_stats("total_healing_done", effect.amount)
				update_combat_stats("healing_done", effect.amount, result.source)
				update_combat_stats("healing_received", effect.amount, result.target)
			"status":
				update_combat_stats("status_effects_applied", 1, result.source)
	
	if result.result == ActionResolver.ActionResult.FAILED:
		combat_ui.show_message(result.reason)
		await get_tree().create_timer(0.5).timeout
		return
	
	combat_ui.combat_log.add_item_message(
		result.source.character_name,
		result.item_name,
		result.target.character_name
	)
	
	await get_tree().create_timer(0.2).timeout

func _apply_defend_effect(unit: BaseCharacter):
	combat_ui.show_message("%s takes a defensive stance" % unit.character_name)
	await get_tree().create_timer(0.5).timeout

func _update_combat_ui():
	# Update turn order display
	var current_order = turn_manager.get_current_order()
	turn_order_changed.emit(current_order)
	
	# Update unit displays
	for unit in player_party + enemy_party:
		unit_stats_updated.emit(unit)

func _show_combat_message(message: String, color: Color = Color.WHITE):
	combat_message.emit(message, color)

func advance_combat_state():
	match current_state:
		CombatEnums.CombatState.INITIALIZING:
			if _initialize_combat():
				current_state = CombatEnums.CombatState.ROUND_START
				combat_state_changed.emit(current_state)
				start_next_turn()
		
		CombatEnums.CombatState.ROUND_START:
			if current_unit in player_party:
				current_state = CombatEnums.CombatState.PLAYER_TURN
			else:
				current_state = CombatEnums.CombatState.ENEMY_TURN
			combat_state_changed.emit(current_state)
			_start_unit_turn()
		
		CombatEnums.CombatState.PLAYER_TURN, CombatEnums.CombatState.ENEMY_TURN:
			if is_processing_action:
				current_state = CombatEnums.CombatState.ANIMATING
				combat_state_changed.emit(current_state)
			elif action_queue.is_empty():
				_end_current_turn()
		
		CombatEnums.CombatState.ANIMATING:
			if not is_processing_action:
				if check_combat_end():
					return
				current_state = CombatEnums.CombatState.ROUND_START
				combat_state_changed.emit(current_state)
				start_next_turn()

func _start_unit_turn():
	if not current_unit:
		return
	
	# Process start of turn effects
	process_status_effects(current_unit)
	
	# Regenerate MP
	var mp_regen = _calculate_mp_regen(current_unit)
	if mp_regen > 0:
		current_unit.restore_mp(mp_regen)
		combat_message.emit("%s recovers %d MP" % [current_unit.character_name, mp_regen], Color.BLUE)
	
	current_unit.start_turn()
	
	# Check for turn skip conditions
	if _check_turn_skip(current_unit):
		_end_current_turn()
		return
	
	turn_started.emit(current_unit)
	_update_combat_ui()
	
	# Handle AI turns automatically
	if current_unit not in player_party:
		_queue_ai_action()

func _calculate_mp_regen(unit: BaseCharacter) -> int:
	var regen = MP_REGEN_PER_TURN
	
	# Modify regen based on status effects
	for effect in unit.get_active_status_effects():
		match effect.effect_name:
			"MP Regen Up":
				regen = int(regen * 1.5)
			"MP Regen Down":
				regen = int(regen * 0.5)
	
	# Bonus MP regen when defending
	if unit.is_defending:
		regen = int(regen * 1.5)
	
	return regen

func _check_low_mp_state(unit: BaseCharacter) -> bool:
	return float(unit.current_mp) / unit.max_mp <= LOW_MP_THRESHOLD

func _prepare_new_round():
	round_started.emit(round_number)
	combat_ui.combat_log.add_round_start_message(round_number)
	
	# Process start of round effects
	for unit in player_party + enemy_party:
		if unit.is_alive():
			unit.on_round_start()
			process_status_effects(unit)
	
	# Update turn order
	turn_manager.initialize_turn_order(player_party + enemy_party)
	combat_ui.update_turn_order(turn_manager.current_order)
	
	advance_combat_state()

func _end_current_turn():
	if not current_unit:
		return
		
	turn_ended.emit(current_unit)
	current_unit.end_turn()
	
	# Process end of turn effects
	process_status_effects(current_unit)
	
	# Process summon effects if needed
	if current_unit in summons.values():
		process_summon_effects()
	
	# Clear any temporary effects
	current_unit.clear_temporary_effects()

	current_unit = null
	current_phase = CombatPhase.START_TURN
	advance_combat_state()

func advance_combat_round():
	_log_combat_event("round_end", {"round": round_number})
	
	current_state = CombatEnums.CombatState.ROUND_END
	combat_state_changed.emit(current_state)
	
	round_ended.emit(round_number)
	round_number += 1
	
	# Process end of round effects
	for unit in player_party + enemy_party:
		if unit.is_alive():
			unit.on_round_end()
			# Reduce cooldowns
			unit.tick_cooldowns()
	
	# Process summon effects
	process_summon_effects()
	
	# Start new round
	current_phase = CombatPhase.INIT
	advance_combat_state()
	
	_log_combat_event("round_start", {"round": round_number})

func process_status_effects(unit: BaseCharacter):
	if not unit or not unit.is_alive():
		return
		
	var active_effects = unit.get_active_status_effects()
	# Sort effects by priority
	active_effects.sort_custom(func(a, b): 
		return STATUS_PRIORITIES[a.effect_type] < STATUS_PRIORITIES[b.effect_type]
	)
	
	for effect in active_effects:
		# Process duration
		if effect.duration > 0:
			effect.duration -= 1
			if effect.duration <= 0:
				_remove_status_effect(unit, effect)
				continue
		
		# Process effect
		match effect.effect_name:
			"Burn":
				var damage = effect.damage_per_turn * effect.stack_count
				var final_damage = int(damage * (1.0 - (unit.magic_res / 100.0)))
				unit.take_damage(final_damage, "magical", "fire")
				combat_message.emit("%s takes %d burn damage" % [
					unit.character_name, 
					final_damage
				], Color.ORANGE)
				
			"Poison":
				var damage = effect.damage_per_turn * effect.stack_count
				var final_damage = int(damage * (1.0 - (unit.magic_res / 100.0)))
				unit.take_damage(final_damage, "magical", "nature")
				combat_message.emit("%s takes %d poison damage" % [
					unit.character_name, 
					final_damage
				], Color.PURPLE)
				
			"Stun":
				unit.skip_turn = true
				combat_message.emit("%s is stunned!" % unit.character_name, Color.YELLOW)
		
		status_effect_triggered.emit(unit, effect)
	
	unit_stats_updated.emit(unit)

func apply_status_effect(target: BaseCharacter, effect: StatusEffect):
	# Check immunities and resistances
	if not _can_apply_status(target, effect):
		return
	
	# Check for existing effect
	var existing = target.get_status_effect(effect.effect_name)
	if existing:
		if existing.can_stack and existing.stack_count < existing.max_stacks:
			existing.stack_count += 1
			combat_message.emit("%s's %s stacks! (x%d)" % [
				target.character_name,
				effect.effect_name,
				existing.stack_count
			], Color.YELLOW)
		else:
			# Refresh duration if can't stack
			existing.duration = effect.duration
	else:
		# Apply new effect
		target.add_status_effect(effect)
		combat_message.emit("%s is afflicted with %s!" % [
			target.character_name,
			effect.effect_name
		], Color.PURPLE)
	
	status_effect_applied.emit(target, effect)
	combat_stats.status_effects.applied[effect.effect_name] = combat_stats.status_effects.applied.get(effect.effect_name, 0) + 1

func _can_apply_status(unit: BaseCharacter, effect: StatusEffect) -> bool:
	# Check immunities
	if unit.is_immune_to(effect.effect_type):
		combat_message.emit("%s is immune to %s!" % [
			unit.character_name,
			effect.effect_name
		], Color.YELLOW)
		return false
	
	# Check resistance chance
	var resist_chance = unit.get_status_resistance(effect.effect_type)
	if resist_chance > 0 and randf() < resist_chance:
		combat_message.emit("%s resists %s!" % [
			unit.character_name,
			effect.effect_name
		], Color.YELLOW)
		return false
	
	return true

func _remove_status_effect(unit: BaseCharacter, effect: StatusEffect):
	unit.remove_status_effect(effect.effect_name)
	combat_message.emit("%s's %s wore off" % [
		unit.character_name,
		effect.effect_name
	], Color.YELLOW)
	status_effect_removed.emit(unit, effect.effect_name)

func _on_action_chosen(action: Dictionary):
	current_state = CombatEnums.CombatState.ANIMATING
	combat_state_changed.emit(current_state)
	
	action.source = active_unit
	var result = action_resolver.resolve_action(action)
	
	# Apply effects before showing results
	match result.type:
		"damage":
			apply_damage(result.source, result.target, result)
		"heal":
			apply_healing(result.source, result.target, result.amount)
		"status":
			apply_status_effect(result.target, result.effect)
	
	# Show results in UI
	combat_ui.show_action_result({
		"source": active_unit,
		"target": action.target,
		"result": result
	})
	
	action_performed.emit(active_unit, action)
	
	# Check combat end before continuing
	if check_combat_end():
		return
		
	await get_tree().create_timer(0.5).timeout
	start_next_turn()

func _on_action_resolved(result: Dictionary):
	# Add state transition
	if result.type != "defend":
		current_state = CombatEnums.CombatState.ANIMATING
		combat_state_changed.emit(current_state)
	
	# Process result
	match result.type:
		"damage":
			if result.result == ActionResolver.ActionResult.MISSED:
				combat_ui.show_miss(result.target)
				combat_ui.combat_log.add_message(
					"%s's attack missed %s!" % [result.source.character_name, result.target.character_name],
					Color.GRAY
				)
			else:
				apply_damage(result.source, result.target, result.amount)
		
		"skill":
			if result.result == ActionResolver.ActionResult.FAILED:
				combat_ui.combat_log.add_message(
					"Failed to use %s: %s" % [result.skill_name, result.reason],
					Color.RED
				)
			else:
				for effect in result.effects:
					match effect.type:
						"damage": apply_damage(result.source, result.target, effect)
						"heal": apply_healing(result.source, result.target, effect.amount)
						"status": apply_status_effect(result.target, effect.status)
				
				combat_ui.combat_log.add_skill_message(
					result.source.character_name,
					result.skill_name,
					result.target.character_name
				)
		
		"item":
			if result.result == ActionResolver.ActionResult.FAILED:
				combat_ui.combat_log.add_message(
					"Failed to use %s: %s" % [result.item_name, result.reason],
					Color.RED
				)
			else:
				for effect in result.effects:
					match effect.type:
						"heal": apply_healing(result.source, result.target, effect.amount)
						"status": apply_status_effect(result.target, effect.status)
				
				combat_ui.combat_log.add_item_message(
					result.source.character_name,
					result.item_name,
					result.target.character_name
				)
		
		"defend":
			combat_ui.combat_log.add_message(
				"%s takes a defensive stance" % result.source.character_name,
				Color.AQUA
			)
	
	if check_combat_end():
		return
		
	await get_tree().create_timer(0.5).timeout
	start_next_turn()

func apply_damage(attacker: BaseCharacter, target: BaseCharacter, result: Dictionary):
	target.take_damage(result.amount)
	damage_dealt.emit(attacker, target, result.amount, result.element if "element" in result else "physical")

func apply_healing(source: BaseCharacter, target: BaseCharacter, amount: int):
	target.heal(amount)

func check_combat_end() -> bool:
	var player_alive = player_party.any(func(unit): return unit.is_alive())
	var enemy_alive = enemy_party.any(func(unit): return unit.is_alive())
	
	if not enemy_alive:
		current_state = CombatEnums.CombatState.VICTORY
		combat_state_changed.emit(current_state)
		_show_combat_message("Victory!", Color.GREEN)
		return true
		
	if not player_alive:
		current_state = CombatEnums.CombatState.DEFEAT
		combat_state_changed.emit(current_state)
		_show_combat_message("Defeat!", Color.RED)
		return true
		
	return false

func _end_combat(result: String):
	if result == "victory":
		combat_rewards.calculate_rewards(player_party, enemy_party)
	else:
		combat_ended.emit({"result": result})
	
	current_phase = CombatPhase.INIT
	current_unit = null
	action_queue.clear()
	is_processing_action = false

func calculate_combat_rewards():
	var base_exp: int = 0
	var base_gold: int = 0
	var items: Array = []
	
	# Calculate base rewards from defeated enemies
	for enemy in enemy_party:
		if enemy is EnemyCharacter:
			# Base rewards
			base_exp += enemy.base_exp
			base_gold += enemy.base_gold
			
			# Add items from loot table if enemy has one
			if enemy.loot_table:
				var loot = enemy.loot_table.generate_loot()
				items.append_array(loot)
	
	# Apply modifiers based on combat performance
	var performance_multiplier = _calculate_performance_multiplier()
	
	combat_rewards = {
		"exp": int(base_exp * performance_multiplier),
		"gold": int(base_gold * performance_multiplier),
		"items": items,
		"bonus_multiplier": performance_multiplier
	}

func _calculate_performance_multiplier() -> float:
	var multiplier = 1.0
	
	# Bonus for quick victory (fewer rounds)
	if round_number <= 3:
		multiplier += 0.2
	elif round_number <= 5:
		multiplier += 0.1
	
	# Bonus for efficient combat (high damage per round)
	var avg_damage_per_round = combat_stats.total_damage_dealt / max(round_number, 1)
	if avg_damage_per_round > 100:
		multiplier += 0.15
	
	# Bonus for party survival
	var survival_rate = _calculate_party_survival_rate()
	multiplier += survival_rate * 0.2
	
	# Penalty for excessive item usage
	if combat_stats.items_used > round_number * 2:
		multiplier -= 0.1
	
	return clamp(multiplier, 0.5, 2.0)

func _calculate_party_survival_rate() -> float:
	var alive_count = 0
	for unit in player_party:
		if unit.is_alive():
			alive_count += 1
	return float(alive_count) / player_party.size()

func distribute_rewards():
	if combat_rewards.exp <= 0:
		return
	
	# Calculate individual exp share
	var alive_party_members = player_party.filter(func(unit): return unit.is_alive())
	if alive_party_members.is_empty():
		return
		
	var exp_share = combat_rewards.exp / alive_party_members.size()
	
	# Distribute experience and check for level ups
	var level_ups: Array = []
	for unit in alive_party_members:
		var leveled = unit.gain_experience(exp_share)
		if leveled:
			level_ups.append(unit)
	
	# Emit rewards signals
	rewards_distributed.emit(combat_rewards)
	if not level_ups.is_empty():
		for unit in level_ups:
			unit_leveled_up.emit(unit)

func get_valid_targets(unit: BaseCharacter, action_type: int, data: Dictionary = {}) -> Array:
	var targets: Array = []
	
	match action_type:
		CombatEnums.ActionType.ATTACK:
			targets = enemy_party.filter(func(target): return target.is_alive())
		CombatEnums.ActionType.SKILL:
			var skill = data.get("skill")
			if skill:
				match skill.target_type:
					"enemy": targets = enemy_party.filter(func(target): return target.is_alive())
					"ally": targets = player_party.filter(func(target): return target.is_alive())
					"self": targets = [unit]
					"all_enemies": targets = enemy_party.filter(func(target): return target.is_alive())
					"all_allies": targets = player_party.filter(func(target): return target.is_alive())
		CombatEnums.ActionType.ITEM:
			var item = data.get("item")
			if item:
				match item.target_type:
					"ally": targets = player_party.filter(func(target): return target.is_alive())
					"self": targets = [unit]
					"any": targets = (player_party + enemy_party).filter(func(target): return target.is_alive())
	
	return targets

func get_row_units(row: int) -> Array:
	return front_row if row == CombatEnums.Row.FRONT else back_row

func is_unit_in_row(unit: BaseCharacter, row: int) -> bool:
	return unit in get_row_units(row)

func add_to_combat_log(message: String, type: String = "info", color: Color = Color.WHITE):
	var log_entry = {
		"round": round_number,
		"message": message,
		"type": type,
		"color": color,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	combat_log.append(log_entry)
	if combat_log.size() > max_log_entries:
		combat_log.pop_front()
	
	combat_ui.combat_log.add_message(message, color)

func _log_combat_event(event_type: String, data: Dictionary):
	var message: String
	var color: Color = Color.WHITE
	
	match event_type:
		"turn_start":
			message = "%s's turn begins" % data.unit.character_name
			color = Color.YELLOW
		
		"action":
			message = _format_action_message(data)
			color = _get_action_color(data.type)
		
		"damage":
			message = "%s deals %d damage to %s" % [
				data.source.character_name,
				data.amount,
				data.target.character_name
			]
			color = Color.RED
		
		"heal":
			message = "%s heals %s for %d HP" % [
				data.source.character_name,
				data.target.character_name,
				data.amount
			]
			color = Color.GREEN
		
		"status_effect":
			message = "%s is affected by %s" % [
				data.target.character_name,
				data.effect.name
			]
			color = Color.PURPLE
		
		"item_use":
			message = "%s uses %s on %s" % [
				data.source.character_name,
				data.item.name,
				data.target.character_name
			]
			color = Color.AQUA
		
		"round_start":
			message = "Round %d begins!" % data.round
			color = Color.YELLOW
		
		"round_end":
			message = "Round %d ends" % data.round
			color = Color.YELLOW
		
		"combat_end":
			message = "Combat ends - %s!" % data.result.capitalize()
			color = Color.YELLOW
	
	add_to_combat_log(message, event_type, color)

func _format_action_message(action_data: Dictionary) -> String:
	match action_data.type:
		"attack":
			return "%s attacks %s" % [
				action_data.source.character_name,
				action_data.target.character_name
			]
		"skill":
			return "%s uses %s on %s" % [
				action_data.source.character_name,
				action_data.skill.name,
				action_data.target.character_name
			]
		"defend":
			return "%s takes a defensive stance" % action_data.source.character_name
		_:
			return "Unknown action performed"

func _get_action_color(action_type: String) -> Color:
	match action_type:
		"attack": return Color.WHITE
		"skill": return Color.AQUA
		"defend": return Color.YELLOW
		_: return Color.WHITE

func get_combat_summary() -> Dictionary:
	return {
		"rounds": round_number,
		"combat_type": combat_type,
		"party_status": _get_party_status(player_party),
		"enemy_status": _get_party_status(enemy_party),
		"combat_log": combat_log,
		"statistics": combat_stats,
		"unit_statistics": unit_stats
	}

func _get_party_status(party: Array) -> Array:
	var status = []
	for unit in party:
		status.append({
			"name": unit.character_name,
			"hp": unit.current_hp,
			"max_hp": unit.max_hp,
			"status_effects": unit.get_status_effect_names()
		})
	return status

func change_unit_row(unit: BaseCharacter, new_row: int):
	if unit.current_row == new_row:
		return
		
	unit.current_row = new_row
	_organize_rows()
	_position_units()
	row_changed.emit(unit, new_row)

func handle_action(action: Dictionary):
	if current_state != CombatEnums.CombatState.PLAYER_TURN:
		return
		
	current_state = CombatEnums.CombatState.ANIMATING
	combat_state_changed.emit(current_state)
	
	action_queue.append(action)
	_process_action_queue()

func _handle_damage_result(result: Dictionary):
	if result.result == ActionResult.CRITICAL:
		update_combat_stats("critical_hits", 1, result.source)
	
	if result.amount > 0:
		update_combat_stats("total_damage_dealt", result.amount)
		update_combat_stats("damage_dealt", result.amount, result.source)
		update_combat_stats("damage_taken", result.amount, result.target)
	
	match result.result:
		ActionResult.MISSED:
			combat_ui.show_miss(result.target)
			await get_tree().create_timer(0.5).timeout
		ActionResult.SUCCESS, ActionResult.CRITICAL:
			if result.amount > 0:
				damage_dealt.emit(result.source, result.target, result.amount, "physical")
				await get_tree().create_timer(0.5).timeout
				
			if result.is_critical:
				combat_ui.show_critical(result.target)
				await get_tree().create_timer(0.3).timeout

func _handle_skill_result(result: Dictionary):
	update_combat_stats("skills_used", 1, result.source)
	update_combat_stats("actions_taken", 1, result.source)
	
	for effect in result.effects:
		match effect.type:
			"damage":
				update_combat_stats("total_damage_dealt", effect.amount)
				update_combat_stats("damage_dealt", effect.amount, result.source)
				update_combat_stats("damage_taken", effect.amount, result.target)
			"heal":
				update_combat_stats("total_healing_done", effect.amount)
				update_combat_stats("healing_done", effect.amount, result.source)
				update_combat_stats("healing_received", effect.amount, result.target)
			"status":
				update_combat_stats("status_effects_applied", 1, result.source)
	
	if result.result == ActionResult.FAILED:
		combat_ui.show_message(result.reason)
		await get_tree().create_timer(0.5).timeout
		return
	
	combat_ui.combat_log.add_skill_message(
		result.source.character_name,
		result.skill.name,
		result.target.character_name
	)
	
	await get_tree().create_timer(0.2).timeout

func _handle_item_result(result: Dictionary):
	update_combat_stats("items_used", 1, result.source)
	update_combat_stats("actions_taken", 1, result.source)
	
	for effect in result.effects:
		match effect.type:
			"heal":
				update_combat_stats("total_healing_done", effect.amount)
				update_combat_stats("healing_done", effect.amount, result.source)
				update_combat_stats("healing_received", effect.amount, result.target)
			"status":
				update_combat_stats("status_effects_applied", 1, result.source)
	
	if result.result == ActionResult.FAILED:
		combat_ui.show_message(result.reason)
		await get_tree().create_timer(0.5).timeout
		return
	
	combat_ui.combat_log.add_item_message(
		result.source.character_name,
		result.item_name,
		result.target.character_name
	)
	
	await get_tree().create_timer(0.2).timeout

func _handle_defend_result(result: Dictionary):
	combat_ui.show_message("%s takes a defensive stance" % result.source.character_name)
	await get_tree().create_timer(0.5).timeout

func _handle_summon_result(result: Dictionary):
	if not result.success:
		combat_ui.show_message(result.message)
		summon_failed.emit(result.source, result.message)
	else:
		summon_added.emit(result.source, result.summon, result.summon.position)
	await get_tree().create_timer(0.5).timeout

func _animate_action(action: Dictionary):
	var source = action.source
	var target = action.target
	
	match action.type:
		"attack":
			await _animate_attack(source, target)
		"skill":
			await _animate_skill(source, target, action.skill)
		"item":
			await _animate_item_use(source, target, action.item)
		"defend":
			await _animate_defend(source)

func _animate_attack(attacker: BaseCharacter, target: BaseCharacter):
	# Basic attack animation
	var original_pos = attacker.position
	var target_pos = target.position
	
	# Move towards target
	var tween = create_tween()
	tween.tween_property(attacker, "position", 
		target_pos - (target_pos - original_pos).normalized() * 50.0, 
		0.2
	)
	await tween.finished
	
	# Attack flash
	target.flash_sprite()
	
	# Return to position
	tween = create_tween()
	tween.tween_property(attacker, "position", original_pos, 0.2)
	await tween.finished

func _animate_defend(unit: BaseCharacter):
	var tween = create_tween()
	tween.tween_property(unit, "modulate", Color(0.5, 0.8, 1.0), 0.2)
	tween.tween_property(unit, "modulate", Color.WHITE, 0.2)
	await tween.finished

func can_add_summon(side: Array) -> bool:
	return side.size() < max_units_per_side

func add_summon(summoner: BaseCharacter, summon_data: Dictionary) -> BaseCharacter:
	var side = player_party if summoner in player_party else enemy_party
	if not can_add_summon(side):
		return null
		
	var summon = load(summon_data.scene_path).instantiate()
	summon.setup(summon_data)
	
	# Add to appropriate side
	side.append(summon)
	summons[summon] = summoner
	
	# Position summon
	var position = _get_next_available_position(side)
	summon.position = position
	
	# Add duration tracking if specified
	if summon_data.has("duration"):
		summon_durations[summon] = summon_data.duration
	
	# Add to turn order if in combat
	if current_state != CombatEnums.CombatState.INITIALIZING:
		turn_manager.add_unit(summon)
		turn_manager._adjust_summon_priority(summoner, summon)
	
	summon_added.emit(summoner, summon, position)
	return summon

func remove_summon(summon: BaseCharacter):
	if summon in summons:
		# Remove from turn order first
		turn_manager.remove_unit(summon)
		
		var side = player_party if summon in player_party else enemy_party
		side.erase(summon)
		summons.erase(summon)
		summon_removed.emit(summon)
		summon.queue_free()

func _get_next_available_position(side: Array) -> Vector2:
	var positions = $CombatPositions/PartyPositions if side == player_party else $CombatPositions/EnemyPositions
	var row = positions.get_node("BackRow") # Summons default to back row
	
	for pos in row.get_children():
		if not _is_position_occupied(pos.global_position):
			return pos.global_position
			
	return Vector2.ZERO

func _is_position_occupied(pos: Vector2) -> bool:
	for unit in player_party + enemy_party:
		if unit.global_position.distance_to(pos) < 10:
			return true
	return false

func process_summon_effects():
	var summons_to_remove = []
	
	# Check durations
	for summon in summon_durations.keys():
		summon_durations[summon] -= 1
		if summon_durations[summon] <= 0:
			summons_to_remove.append(summon)
	
	# Check dead summoners
	for summon in summons.keys():
		var summoner = summons[summon]
		if not summoner.is_alive():
			summons_to_remove.append(summon)
	
	# Remove marked summons
	for summon in summons_to_remove:
		remove_summon(summon)
	
	# Add duration update signals
	for summon in summons.keys():
		if summon_durations.get(summon, -1) > 0:
			summon_duration_updated.emit(summon, summon_durations[summon])
		else:
			summon_expired.emit(summon)

func _on_unit_died(unit: BaseCharacter):
	turn_manager.remove_unit(unit)
	if unit == current_unit:
		_end_current_turn()

func _process_summon_link(summoner: BaseCharacter, summon: BaseCharacter):
	if not summoner.is_alive() or not summon.is_alive():
		summon_link_broken.emit(summoner, summon)
		return false
	return true

func update_summon_state(summon: BaseCharacter):
	if summon in summons:
		var state = {
			"turns_remaining": summon_durations.get(summon, -1),
			"summoner": summons[summon],
			"effects": summon.get_active_effects()
		}
		summon_state_changed.emit(summon, state)

func _trigger_summon_animation(summon: BaseCharacter, animation_type: String):
	summon_animation_started.emit(summon, animation_type)
	# Wait for animation
	await get_tree().create_timer(0.5).timeout
	summon_animation_finished.emit(summon)

func update_summon_behavior(summon: BaseCharacter, behavior: int):
	if summon in summons:
		summon_behavior_changed.emit(summon, behavior)

func _process_summon_turn(summon: BaseCharacter):
	if not summon in summons:
		return
		
	summon_turn_started.emit(summon)
	
	# Get AI decision
	var action = summon_ai.get_summon_action(summon)
	if not action.is_empty():
		summon_ai_decision_made.emit(summon, action)
		await perform_action(summon, action)
	
	summon_turn_ended.emit(summon)

func _process_summon_ai_turn(summon: BaseCharacter):
	if not summon in summons:
		return
		
	var ai_state = {
		"behavior": summon_ai._determine_behavior(summon),
		"summoner": summons[summon],
		"allies_need_support": summon_ai._allies_need_support(summon)
	}
	summon_ai_state_updated.emit(summon, ai_state)
	
	var action = summon_ai.get_summon_action(summon)
	if action.has("target"):
		summon_target_changed.emit(summon, action.target)
	summon_ai_decision_made.emit(summon, action)

func _process_summon_effects():
	for summon in summons.keys():
		var summoner = summons[summon]
		if not summoner or not summon:
			continue
			
		# Process link effects
		if summon.has_link_effect():
			var link_effect = summon.get_link_effect()
			summon_link_effect_updated.emit(summoner, summon, link_effect)
			
		# Process stat changes
		var old_stats = summon.stats.duplicate()
		_apply_summoner_modifiers(summoner, summon)
		if old_stats != summon.stats:
			summon_stats_updated.emit(summon, old_stats, summon.stats)
			
		# Process triggered effects
		for effect in summon.get_active_effects():
			if effect.should_trigger():
				summon_effect_triggered.emit(summon, effect)

func _emit_summon_message(message: String, color: Color = Color.WHITE):
	summon_combat_message.emit(message, color)

func _emit_summon_status(summon: BaseCharacter, status: String, color: Color = Color.WHITE):
	summon_status_message.emit(summon, status, color)

func _update_summon_position(summon: BaseCharacter):
	if not summon in summons:
		return
		
	var side = player_party if summon in player_party else enemy_party
	var new_position = _get_next_available_position(side)
	if new_position != Vector2.ZERO:
		summon_position_updated.emit(summon, new_position)

func spawn_summon_effect(effect_scene: PackedScene, position: Vector2):
	summon_effect_spawned.emit(effect_scene, position)

func update_summon_range(summon: BaseCharacter):
	if summon in summons:
		var range_data = {
			"attack_range": summon.get_attack_range(),
			"skill_ranges": summon.get_skill_ranges(),
			"movement_range": summon.get_movement_range()
		}
		summon_range_updated.emit(summon, range_data)

func update_summon_position(summon: BaseCharacter, new_position: Vector2):
	if summon in summons:
		var old_pos = summon.global_position
		summon.global_position = new_position
		summon_position_changed.emit(summon, old_pos, new_position)

func check_summon_range(summon: BaseCharacter, target: BaseCharacter) -> bool:
	if not summon_ai._is_in_range(summon, target):
		summon_range_check_failed.emit(summon, target)
		return false
	return true

func validate_summon_position(summon: BaseCharacter, position: Vector2) -> bool:
	if _is_position_occupied(position):
		summon_position_invalid.emit(summon, position)
		return false
	return true

func _emit_position_change(unit: BaseCharacter, old_pos: Vector2, new_pos: Vector2):
	unit_position_changed.emit(unit, old_pos, new_pos)

func _emit_stats_change(unit: BaseCharacter, old_stats: Dictionary, new_stats: Dictionary):
	unit_stats_changed.emit(unit, old_stats, new_stats)

func _check_resistances(unit: BaseCharacter, effect: Dictionary) -> bool:
	if unit.is_immune_to(effect.type):
		immunity_triggered.emit(unit, effect.type)
		return false
	if unit.resists(effect.type):
		resistance_check_failed.emit(unit, effect.type)
		return false
	return true

func _process_action_interruption(unit: BaseCharacter, action: Dictionary) -> bool:
	if unit.is_stunned():
		action_interrupted.emit(unit, action)
		return true
	return false

func _check_turn_skip(unit: BaseCharacter) -> bool:
	if unit.is_stunned():
		turn_skipped.emit(unit, "Stunned")
		return true
	if unit.is_frozen():
		turn_skipped.emit(unit, "Frozen")
		return true
	return false

func handle_player_input(action_type: String, data: Dictionary = {}):
	if current_state != CombatEnums.CombatState.PLAYER_TURN or not current_unit:
		return
		
	match action_type:
		"action_selected":
			_handle_action_selection(data.action)
		"target_selected":
			_handle_target_selection(data.target)
		"skill_selected":
			_handle_skill_selection(data.skill)
		"item_selected":
			_handle_item_selection(data.item)
		"cancel":
			_handle_action_cancel()

func _handle_action_selection(action: String):
	match action:
		"attack":
			combat_ui.start_target_selection(
				get_valid_targets(current_unit, CombatEnums.ActionType.ATTACK)
		"skill":
			combat_ui.show_skill_list(current_unit.get_usable_skills())
		"item":
			combat_ui.show_item_list(current_unit.get_usable_items())
		"defend":
			var defend_action = {
				"type": "defend",
				"source": current_unit,
				"target": current_unit
			}
			action_queue.append(defend_action)
			_process_action_queue()

func _handle_target_selection(target: BaseCharacter):
	if not target or not current_unit:
		return
		
	var action: Dictionary
	match combat_ui.get_current_action_type():
		"attack":
			action = {
				"type": "attack",
				"source": current_unit,
				"target": target
			}
		"skill":
			var selected_skill = combat_ui.get_selected_skill()
			if selected_skill:
				action = {
					"type": "skill",
					"source": current_unit,
					"target": target,
					"skill": selected_skill
				}
		"item":
			var selected_item = combat_ui.get_selected_item()
			if selected_item:
				action = {
					"type": "item",
					"source": current_unit,
					"target": target,
					"item": selected_item
				}
	
	if action:
		action_queue.append(action)
		_process_action_queue()

func _handle_skill_selection(skill: Skill):
	if not skill or not current_unit:
		return
		
	if current_unit.current_mp < skill.mp_cost:
		combat_ui.show_message("Not enough MP!")
		return
		
	combat_ui.start_target_selection(
		get_valid_targets(current_unit, CombatEnums.ActionType.SKILL, {"skill": skill})

func _handle_item_selection(item: Item):
	if not item or not current_unit:
		return
		
	combat_ui.start_target_selection(
		get_valid_targets(current_unit, CombatEnums.ActionType.ITEM, {"item": item})

func _handle_action_cancel():
	combat_ui.hide_target_selector()
	combat_ui.hide_skill_list()
	combat_ui.hide_item_list()
	combat_ui.enable_action_buttons()

func transition_to_next_state():
	match current_state:
		CombatEnums.CombatState.INITIALIZING:
			if _initialize_combat():
				current_state = CombatEnums.CombatState.ROUND_START
				combat_state_changed.emit(current_state)
				_prepare_new_round()
		
		CombatEnums.CombatState.ROUND_START:
			current_state = CombatEnums.CombatState.PLAYER_TURN if current_unit in player_party else CombatEnums.CombatState.ENEMY_TURN
			combat_state_changed.emit(current_state)
			_start_unit_turn()
		
		CombatEnums.CombatState.PLAYER_TURN, CombatEnums.CombatState.ENEMY_TURN:
			if is_processing_action:
				current_state = CombatEnums.CombatState.ANIMATING
				combat_state_changed.emit(current_state)
			elif action_queue.is_empty():
				_end_current_turn()
		
		CombatEnums.CombatState.ANIMATING:
			if not is_processing_action:
				if check_combat_end():
					return
				current_state = CombatEnums.CombatState.ROUND_START
				combat_state_changed.emit(current_state)
				start_next_turn()

func _initialize_combat() -> bool:
	# Initialize turn order with speed variance
	turn_manager.initialize_turn_order(player_party + enemy_party)
	_update_combat_ui()
	
	# Position units
	_position_units()
	
	# Setup initial states
	for unit in player_party + enemy_party:
		unit.initialize_combat_state()
	
	combat_started.emit(player_party, enemy_party)
	return true

func _init_combat_stats():
	combat_stats.clear()
	combat_stats = {
		"rounds": 0,
		"total_damage_dealt": 0,
		"total_healing_done": 0,
		"actions_taken": 0,
		"critical_hits": 0,
		"status_effects_applied": 0,
		"items_used": 0,
		"skills_used": 0,
		
		# New detailed stats
		"damage_by_type": {
			"physical": 0,
			"magical": 0,
			"true": 0
		},
		"damage_by_element": {},  # Will be populated with elements as they occur
		"healing_by_source": {
			"skills": 0,
			"items": 0,
			"effects": 0
		},
		"mana_usage": {
			"spent": 0,
			"regenerated": 0
		},
		"status_effects": {
			"applied": {},  # Effect name -> count
			"resisted": 0,
			"cleansed": 0
		},
		"combat_flow": {
			"turns_taken": 0,
			"actions_per_turn": [],
			"average_turn_duration": 0.0
		}
	}
	
	# Initialize per-unit stats
	unit_stats.clear()
	for unit in player_party + enemy_party:
		unit_stats[unit] = {
			"damage": stats.damage_dealt,
			"healing": stats.healing_done,
			"skills": stats.skills_used,
			"items": stats.items_used
		}

func save_combat_state() -> Dictionary:
	return {
		"current_state": current_state,
		"current_phase": current_phase,
		"round_number": round_number,
		"current_unit": current_unit.get_save_data() if current_unit else null,
		"action_queue": action_queue,
		"combat_log": combat_log,
		"combat_stats": combat_stats,
		"unit_stats": _get_unit_stats_data()
	}

func load_combat_state(state: Dictionary):
	current_state = state.current_state
	current_phase = state.current_phase
	round_number = state.round_number
	combat_log = state.combat_log
	combat_stats = state.combat_stats
	
	# Restore unit stats
	_restore_unit_stats(state.unit_stats)
	
	# Restore current unit if any
	if state.current_unit:
		current_unit = _find_unit_by_data(state.current_unit)
	
	# Restore action queue
	action_queue = state.action_queue

func _get_unit_stats_data() -> Dictionary:
	var data = {}
	for unit_name in unit_stats:
		var stats = unit_stats[unit_name]
		data[unit_name] = {
			"damage": stats.damage_dealt,
			"healing": stats.healing_done,
			"skills": stats.skills_used,
			"items": stats.items_used
		}
	
	return data

func _restore_unit_stats(stats_data: Dictionary):
	unit_stats.clear()
	for unit in player_party + enemy_party:
		var unit_id = unit.get_instance_id()
		if unit_id in stats_data:
			unit_stats[unit] = stats_data[unit_id]

# Add damage calculation system
func calculate_damage(source: BaseCharacter, target: BaseCharacter, base_damage: int, damage_type: String = "physical") -> int:
	var final_damage = base_damage
	
	# Apply standard modifiers first
	final_damage = _apply_standard_modifiers(final_damage, source, target, damage_type)
	
	# Apply combo multiplier
	final_damage = _apply_combo_multiplier(final_damage, source)
	
	return max(1, final_damage)

func _apply_standard_modifiers(damage: int, attacker: BaseCharacter, target: BaseCharacter, damage_type: String) -> int:
	var modified_damage = damage
	
	# Apply attacker's offensive stats
	match damage_type:
		"physical":
			modified_damage += attacker.stats.strength
			modified_damage = _apply_critical_hit(modified_damage, attacker)
		"magical":
			modified_damage += attacker.stats.magic
	
	# Apply target's defensive stats
	match damage_type:
		"physical":
			modified_damage -= target.stats.defense
			if target.is_defending:
				modified_damage = int(modified_damage * 0.5)
		"magical":
			modified_damage -= target.stats.magic_defense
	
	# Apply row modifiers
	if target.current_row == CombatEnums.Row.BACK:
		modified_damage = int(modified_damage * CombatEnums.BACK_ROW_DAMAGE_MOD)
	
	# Apply status effect modifiers
	modified_damage = _apply_status_modifiers(modified_damage, attacker, target)
	
	return modified_damage

func _apply_combo_multiplier(damage: int, attacker: BaseCharacter) -> int:
	var attacker_side = "player" if attacker in player_party else "enemy"
	
	if last_attacker_side == attacker_side:
		combo_counter += 1
	else:
		combo_counter = 1
		last_attacker_side = attacker_side
	
	var multiplier = 1.0
	if combo_counter >= 3:
		multiplier += (combo_counter - 2) * 0.1
	
	# Update UI and combat log
	combo_updated.emit(combo_counter, multiplier)
	
	if combo_counter >= 3:
		combat_message.emit("Combo x%d! (%.1fx damage)" % [combo_counter, multiplier], Color.YELLOW)
		combat_log.add_message("Combo x%d! (%.1fx damage)" % [combo_counter, multiplier], Color.YELLOW)
	
	# Update combat stats
	if combo_counter >= 3:
		combat_stats.total_damage_dealt += int(damage * (multiplier - 1.0))
	
	return int(damage * multiplier)

func _apply_critical_hit(damage: int, source: BaseCharacter) -> int:
	var crit_chance = source.stats.get("crit_rate", 0.05) # 5% base crit rate
	if randf() <= crit_chance:
		combat_message.emit("Critical Hit!", Color.YELLOW)
		combat_stats.critical_hits += 1
		return int(damage * 1.5)
	return damage

func _apply_status_modifiers(damage: int, source: BaseCharacter, target: BaseCharacter) -> int:
	var modified_damage = damage
	
	# Check source status effects
	for effect in source.get_active_status_effects():
		match effect.type:
			"POWER_UP":
				modified_damage = int(modified_damage * 1.2)
			"POWER_DOWN":
				modified_damage = int(modified_damage * 0.8)
	
	# Check target status effects
	for effect in target.get_active_status_effects():
		match effect.type:
			"DEFENSE_UP":
				modified_damage = int(modified_damage * 0.8)
			"DEFENSE_DOWN":
				modified_damage = int(modified_damage * 1.2)
	
	return modified_damage

func calculate_healing(source: BaseCharacter, target: BaseCharacter, base_healing: int) -> int:
	var final_healing = base_healing
	
	# Apply healer's magic stat
	final_healing += source.stats.magic * 0.5
	
	# Apply healing modifiers from status effects
	for effect in source.get_active_status_effects():
		match effect.type:
			"HEALING_UP":
				final_healing = int(final_healing * 1.2)
			"HEALING_DOWN":
				final_healing = int(final_healing * 0.8)
	
	return max(1, final_healing)

# Add these error handling functions
func _handle_error(error_type: String, context: Dictionary = {}):
	# Log the error
	var error = {
		"type": error_type,
		"context": context,
		"timestamp": Time.get_unix_time_from_system()
	}
	error_log.append(error)
	error_occurred.emit(error)
	
	# Existing error handling
	match error_type:
		"invalid_state":
			combat_message.emit("Invalid combat state!", Color.RED)
			_attempt_state_recovery()
		"action_failed":
			combat_message.emit(context.get("message", "Action failed!"), Color.RED)
			_cleanup_failed_action()
		"turn_error":
			combat_message.emit("Turn processing error!", Color.RED)
			_force_next_turn()
		# Add new error types
		"INVALID_ACTION", "TARGET_INVALID":
			_recover_from_action_error(error)
		"STATE_CORRUPTION":
			_recover_from_state_corruption(error)

# Add new recovery methods
func _recover_from_action_error(error: Dictionary):
	# Clean up the failed action
	_cleanup_failed_action()
	
	# Reset the current unit's temporary states
	if current_unit:
		current_unit.reset_temporary_states()
	
	# Return to action selection if it's player's turn
	if current_unit in player_party:
		change_flow_state(CombatFlowState.SELECTING_ACTION)
	else:
		_force_next_turn()
	
	error_recovered.emit(error)

func _recover_from_state_corruption(error: Dictionary):
	# Log critical error
	print("Critical: Combat state corruption detected")
	
	# Reset to a safe state
	is_processing_action = false
	action_queue.clear()
	
	# Force combat restart if necessary
	if not _attempt_state_recovery():
		combat_ended.emit("error")
	
	error_recovered.emit(error)

# Enhance existing state recovery
func _attempt_state_recovery():
	# Reset processing flags
	is_processing_action = false
	action_queue.clear()
	
	# Save current state before recovery attempt
	var recovery_state = {
		"current_unit": current_unit,
		"current_state": current_state,
		"round_number": round_number
	}
	state_history.append(recovery_state)
	
	# Existing recovery logic
	if current_unit:
		_force_next_turn()
		return true
	else:
		current_state = CombatEnums.CombatState.INITIALIZING
		advance_combat_state()
		return false

func _cleanup_failed_action():
	# Clear any pending actions
	action_queue.clear()
	
	# Reset targeting state
	combat_ui.hide_target_selector()
	
	# Update UI
	_update_combat_ui()

func set_combat_speed(speed_key: String):
	if SPEED_MULTIPLIERS.has(speed_key):
		current_speed = SPEED_MULTIPLIERS[speed_key]
		combat_speed_changed.emit(current_speed)
		
		# Update animation speeds
		combat_ui.update_animation_speed(current_speed)

func get_adjusted_duration(base_duration: float) -> float:
	return base_duration / current_speed
