extends Node2D

signal combat_ended(victory: bool)

##test 

@onready var turn_order_display = $CombatUI/TurnOrder
@onready var combat_log = $CombatUI/CombatLog
@onready var target_selector = $CombatUI/TargetSelector
@onready var combat_ui = $CombatUI
@onready var front_row = $UnitPositions/FrontRow
@onready var back_row = $UnitPositions/BackRow
@onready var enemy_positions = $CombatPositions/EnemyPositions
@onready var combat_positions = $CombatPositions
@onready var party_positions = $CombatPositions/PartyPositions
@onready var combat_state = $CombatState
@onready var combat_manager = $CombatManager
@onready var background = $Background

var current_unit: BaseCharacter
var party_units = []
var enemy_units = []
var combat_active: bool = false
var player_party: Array[BaseCharacter] = []
var enemy_party: Array[BaseCharacter] = []

func _ready():
	_connect_combat_signals()
	combat_ui.hide()
	combat_ended.connect(_on_scene_combat_ended)

func _connect_combat_signals():
	combat_manager.combat_started.connect(_on_combat_started)
	combat_manager.combat_state_changed.connect(_on_combat_state_changed)
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.turn_ended.connect(_on_turn_ended)
	combat_manager.action_performed.connect(_on_action_performed)
	combat_manager.damage_dealt.connect(_on_damage_dealt)
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.rewards_ready.connect(_on_rewards_ready)
	combat_manager.level_up.connect(_on_level_up)
	combat_ui.action_selected.connect(_on_action_selected)
	combat_ui.target_selected.connect(_on_target_selected)
	combat_manager.summon_added.connect(_on_summon_added)
	combat_manager.summon_removed.connect(_on_summon_removed)
	combat_manager.turn_manager.turn_order_updated.connect(_on_turn_order_updated)
	combat_ui.skill_selected.connect(_on_skill_selected)
	combat_ui.summon_result_received.connect(_on_summon_result)
	combat_manager.summon_failed.connect(_on_summon_failed)
	combat_manager.summon_expired.connect(_on_summon_expired)
	combat_manager.summon_duration_updated.connect(_on_summon_duration_updated)
	combat_manager.summon_state_changed.connect(_on_summon_state_changed)
	combat_manager.summon_effect_applied.connect(_on_summon_effect_applied)
	combat_manager.summon_link_broken.connect(_on_summon_link_broken)
	combat_manager.summon_animation_started.connect(_on_summon_animation_started)
	combat_manager.summon_animation_finished.connect(_on_summon_animation_finished)
	combat_manager.summon_behavior_changed.connect(_on_summon_behavior_changed)
	combat_manager.summon_turn_started.connect(_on_summon_turn_started)
	combat_manager.summon_turn_ended.connect(_on_summon_turn_ended)
	combat_manager.summon_ai_decision_made.connect(_on_summon_ai_decision_made)
	combat_manager.summon_ai_state_updated.connect(_on_summon_ai_state_updated)
	combat_manager.summon_target_changed.connect(_on_summon_target_changed)
	combat_manager.summon_strategy_changed.connect(_on_summon_strategy_changed)
	combat_manager.summon_effect_triggered.connect(_on_summon_effect_triggered)
	combat_manager.summon_link_effect_updated.connect(_on_summon_link_effect_updated)
	combat_manager.summon_stats_updated.connect(_on_summon_stats_updated)
	combat_manager.summon_combat_message.connect(_on_summon_combat_message)
	combat_manager.summon_status_message.connect(_on_summon_status_message)
	combat_manager.summon_position_updated.connect(_on_summon_position_updated)
	combat_manager.summon_animation_queued.connect(_on_summon_animation_queued)
	combat_manager.summon_effect_spawned.connect(_on_summon_effect_spawned)
	combat_manager.summon_range_updated.connect(_on_summon_range_updated)
	combat_manager.summon_position_changed.connect(_on_summon_position_changed)
	combat_manager.summon_formation_updated.connect(_on_summon_formation_updated)
	combat_manager.summon_range_check_failed.connect(_on_summon_range_check_failed)
	combat_manager.summon_position_invalid.connect(_on_summon_position_invalid)
	combat_manager.summon_formation_broken.connect(_on_summon_formation_broken)
	combat_manager.unit_position_changed.connect(_on_unit_position_changed)
	combat_manager.unit_stats_changed.connect(_on_unit_stats_changed)
	combat_manager.skill_cooldown_updated.connect(_on_skill_cooldown_updated)
	combat_manager.resource_depleted.connect(_on_resource_depleted)
	combat_manager.status_effect_applied.connect(_on_status_effect_applied)
	combat_manager.status_effect_removed.connect(_on_status_effect_removed)
	combat_manager.condition_triggered.connect(_on_condition_triggered)
	combat_manager.resistance_check_failed.connect(_on_resistance_check_failed)
	combat_manager.immunity_triggered.connect(_on_immunity_triggered)
	combat_manager.mana_spent.connect(_on_mana_spent)
	combat_manager.round_started.connect(_on_round_started)
	combat_manager.round_ended.connect(_on_round_ended)
	combat_manager.row_changed.connect(_on_row_changed)

func _on_turn_order_updated(order: Array):
	turn_order_display.update_turn_order(order)

func _on_combat_started(party: Array, enemies: Array):
	combat_active = true
	party_units = party
	enemy_units = enemies
	_position_units()
	combat_ui.setup_party_status(party)
	combat_ui.show()
	combat_ui.update_turn_order(combat_manager.turn_manager.current_order)
	combat_ui.update_unit_displays()

func _position_units():
	# Position party members
	for i in range(party_units.size()):
		var unit = party_units[i]
		var row_node = party_positions.get_node("FrontRow" if unit.current_row == 0 else "BackRow")
		var position_node = row_node.get_node("Pos" + str(i + 1))
		unit.global_position = position_node.global_position

	# Position enemies
	for i in range(enemy_units.size()):
		var unit = enemy_units[i]
		var row_node = enemy_positions.get_node("FrontRow" if unit.current_row == 0 else "BackRow")
		var position_node = row_node.get_node("Pos" + str(i + 1))
		unit.global_position = position_node.global_position

func _on_combat_state_changed(new_state: int):
	match new_state:
		CombatEnums.CombatState.PLAYER_TURN:
			if current_unit in combat_manager.player_party:
				combat_ui.enable_action_buttons()
			else:
				combat_ui.disable_action_buttons()
		CombatEnums.CombatState.ENEMY_TURN:
			combat_ui.disable_action_buttons()
		CombatEnums.CombatState.VICTORY:
			_handle_victory()
		CombatEnums.CombatState.DEFEAT:
			_handle_defeat()

func _on_turn_started(unit: BaseCharacter):
	current_unit = unit
	combat_ui.set_active_character(unit)
	combat_log.add_turn_message(unit)

func _on_turn_ended(unit: BaseCharacter):
	combat_ui.update_unit_displays()
	combat_manager.process_summon_effects()

func _on_action_selected(action_type: int):
	match action_type:
		CombatEnums.ActionType.ATTACK:
			combat_ui.start_target_selection(get_valid_targets(current_unit))
		CombatEnums.ActionType.DEFEND:
			combat_manager.perform_action(current_unit, {"type": action_type})
		CombatEnums.ActionType.MOVE:
			combat_manager.perform_action(current_unit, {"type": action_type})
		CombatEnums.ActionType.SUMMON:
			var summon_skills = current_unit.get_summon_skills()
			if summon_skills.is_empty():
				combat_ui.show_message("No summon skills available!")
				return
			combat_ui.show_skill_selection(summon_skills)

func _on_target_selected(target: BaseCharacter):
	var action = {
		"type": combat_ui.current_action_type,
		"target": target
	}
	combat_manager.perform_action(current_unit, action)

func _on_action_performed(unit: BaseCharacter, action: Dictionary):
	var message = create_action_message(unit, action)
	combat_ui.combat_log.add_message(message)

func _on_damage_dealt(attacker: BaseCharacter, target: BaseCharacter, amount: int, element: String = ""):
	combat_ui.show_damage(target, amount, element)
	combat_ui.update_party_status()

func _on_combat_ended(result: String):
	combat_active = false
	combat_ended.emit(result == "victory")
	
	if result == "Victory!":
		combat_log.add_message("Victory!", Color.GREEN)
		_handle_victory()
	else:
		combat_log.add_message("Defeat...", Color.RED)
		_handle_defeat()
	
	# Wait for log messages before ending
	await get_tree().create_timer(2.0).timeout

func get_valid_targets(for_unit: BaseCharacter) -> Array:
	if for_unit in party_units:
		return enemy_units.filter(func(enemy): return enemy.is_alive())
	return party_units.filter(func(member): return member.is_alive())

func create_action_message(unit: BaseCharacter, action: Dictionary) -> String:
	match action.type:
		CombatEnums.ActionType.ATTACK:
			return "%s attacked %s for %d damage!" % [
				unit.character_name,
				action.target.character_name,
				action.result.damage
			]
		CombatEnums.ActionType.DEFEND:
			return "%s is defending!" % [unit.character_name]
		CombatEnums.ActionType.MOVE:
			var row_name = "back row" if unit.current_row == 1 else "front row"
			return "%s moved to %s!" % [unit.character_name, row_name]
	return ""

func _handle_victory():
	var exp_gained = _calculate_exp_reward()
	var gold_gained = _calculate_gold_reward()
	
	combat_log.add_message("Gained " + str(exp_gained) + " EXP")
	combat_log.add_message("Found " + str(gold_gained) + " Gold")
	
	# Apply rewards
	for character in player_party:
		if character.is_alive():
			character.gain_exp(exp_gained)
	GameManager.add_gold(gold_gained)

func _handle_defeat():
	# Handle game over or retreat
	GameManager.handle_party_defeat()

func _calculate_exp_reward() -> int:
	var total_exp = 0
	for enemy in enemy_units:
		total_exp += enemy.exp_value
	return total_exp

func _calculate_gold_reward() -> int:
	var total_gold = 0
	for enemy in enemy_units:
		total_gold += enemy.gold_value
	return total_gold

func _on_rewards_ready(exp: int, gold: int, drops: Array):
	combat_ui.show_rewards_screen(exp, gold, drops)

func _on_level_up(character: BaseCharacter, new_level: int, stat_increases: Dictionary):
	combat_ui.show_level_up(character, new_level, stat_increases)

func cleanup_combat():
	# Clean up any remaining effects, animations, or temporary nodes
	combat_ui.hide()
	combat_active = false
	
	# Reset any combat-specific states
	current_unit = null
	
	# Additional cleanup as needed
	combat_ui.update_unit_displays()

func _on_summon_added(summoner: BaseCharacter, summon: BaseCharacter, position: Vector2):
	combat_ui.update_turn_order(combat_manager.turn_manager.current_order)
	combat_ui.update_unit_displays()

func _on_summon_removed(summon: BaseCharacter):
	combat_ui.update_turn_order(combat_manager.turn_manager.current_order)
	combat_ui.update_unit_displays()

func _on_skill_selected(skill: Skill):
	if skill.is_summon_skill:
		var action = {
			"type": CombatEnums.ActionType.SUMMON,
			"source": current_unit,
			"skill": skill
		}
		combat_manager.perform_action(current_unit, action)
	else:
		combat_ui.start_target_selection(
			combat_manager.get_valid_targets(current_unit, CombatEnums.ActionType.SKILL, {"skill": skill})
		)

func _on_summon_result(result: Dictionary):
	combat_ui.show_summon_result(result)

func _on_summon_failed(summoner: BaseCharacter, message: String):
	combat_ui.show_summon_result({
		"success": false,
		"source": summoner,
		"message": message
	})

func _on_summon_expired(summon: BaseCharacter):
	combat_ui.show_message("%s has disappeared!" % summon.character_name)
	combat_ui.update_unit_displays()

func _on_summon_duration_updated(summon: BaseCharacter, turns_remaining: int):
	combat_ui.update_summon_duration(summon, turns_remaining)

func _on_summon_state_changed(summon: BaseCharacter, state: Dictionary):
	combat_ui.update_summon_state(summon, state)

func _on_summon_effect_applied(summon: BaseCharacter, effect: Dictionary):
	combat_ui.show_summon_effect_applied(summon, effect)

func _on_summon_link_broken(summoner: BaseCharacter, summon: BaseCharacter):
	combat_ui.show_message("Link broken between %s and %s!" % [
		summoner.character_name,
		summon.character_name
	])

func _on_summon_animation_started(summon: BaseCharacter, animation_type: String):
	combat_ui.play_summon_animation(summon, animation_type)

func _on_summon_animation_finished(summon: BaseCharacter):
	combat_ui.update_unit_displays()

func _on_summon_behavior_changed(summon: BaseCharacter, new_behavior: int):
	var behavior_name = SummonAI.SummonBehavior.keys()[new_behavior]
	combat_ui.show_message("%s's behavior changed to %s" % [
		summon.character_name,
		behavior_name.capitalize()
	])

func _on_summon_turn_started(summon: BaseCharacter):
	combat_ui.highlight_active_unit(summon)
	combat_ui.show_message("%s's turn" % summon.character_name)

func _on_summon_turn_ended(summon: BaseCharacter):
	combat_ui.unhighlight_active_unit(summon)

func _on_summon_ai_decision_made(summon: BaseCharacter, action: Dictionary):
	var action_type = action.get("type", "")
	var target = action.get("target")
	var skill = action.get("skill")
	
	var message = "%s " % summon.character_name
	match action_type:
		"attack":
			message += "attacks %s" % target.character_name
		"skill":
			message += "uses %s on %s" % [skill.name, target.character_name]
	
	combat_ui.show_message(message)

func _on_summon_ai_state_updated(summon: BaseCharacter, state: Dictionary):
	var behavior_name = SummonAI.SummonBehavior.keys()[state.behavior].capitalize()
	if state.allies_need_support:
		combat_ui.show_message("%s is providing support!" % summon.character_name)
	combat_ui.update_summon_state(summon, state)

func _on_summon_target_changed(summon: BaseCharacter, target: BaseCharacter):
	combat_ui.highlight_target(target)

func _on_summon_strategy_changed(summon: BaseCharacter, strategy: int):
	var strategy_name = AIControl.AI_STRATEGY.keys()[strategy].capitalize()
	combat_ui.show_message("%s changed strategy to %s" % [
		summon.character_name,
		strategy_name
	])

func _on_summon_effect_triggered(summon: BaseCharacter, effect: Dictionary):
	combat_ui.show_effect_activation(summon, effect)
	combat_ui.show_message("%s: %s activated!" % [
		summon.character_name,
		effect.name
	])
	
func _on_summon_link_effect_updated(summoner: BaseCharacter, summon: BaseCharacter, effect: Dictionary):
	combat_ui.update_link_effect(summoner, summon, effect)
	if effect.has("message"):
		combat_ui.show_message(effect.message)
	
func _on_summon_stats_updated(summon: BaseCharacter, old_stats: Dictionary, new_stats: Dictionary):
	var changes = []
	for stat in new_stats.keys():
		if new_stats[stat] != old_stats[stat]:
			var change = new_stats[stat] - old_stats[stat]
			if change != 0:
				changes.append("%s %+d" % [stat, change])
	
	if not changes.is_empty():
		combat_ui.show_message("%s stats updated: %s" % [
			summon.character_name,
			", ".join(changes)
		])

func _on_summon_combat_message(message: String, color: Color):
	combat_ui.combat_log.add_message(message, color)
	
func _on_summon_status_message(summon: BaseCharacter, status: String, color: Color):
	var message = "%s: %s" % [summon.character_name, status]
	combat_ui.combat_log.add_message(message, color)

func _on_summon_position_updated(summon: BaseCharacter, new_position: Vector2):
	var tween = create_tween()
	tween.tween_property(summon, "global_position", new_position, 0.3)
	await tween.finished
	combat_ui.update_unit_displays()

func _on_summon_animation_queued(summon: BaseCharacter, anim_name: String):
	if summon.has_node("AnimationPlayer"):
		summon.get_node("AnimationPlayer").play(anim_name)

func _on_summon_effect_spawned(effect_scene: PackedScene, position: Vector2):
	var effect = effect_scene.instantiate()
	effect.global_position = position
	effects_container.add_child(effect)
	effect.play()

func _on_summon_range_updated(summon: BaseCharacter, range_data: Dictionary):
	combat_ui.update_range_indicators(summon, range_data)

func _on_summon_position_changed(summon: BaseCharacter, old_pos: Vector2, new_pos: Vector2):
	var tween = create_tween()
	tween.tween_property(summon, "global_position", new_pos, 0.3)
	await tween.finished
	combat_ui.update_unit_displays()

func _on_summon_formation_updated(side: Array, formation: Dictionary):
	for unit in side:
		if unit in combat_manager.summons:
			var new_pos = formation.get(unit, unit.global_position)
			combat_manager.update_summon_position(unit, new_pos)

func _on_summon_range_check_failed(summon: BaseCharacter, target: BaseCharacter):
	combat_ui.show_message("%s is too far from %s!" % [
		summon.character_name,
		target.character_name
	])

func _on_summon_position_invalid(summon: BaseCharacter, position: Vector2):
	combat_ui.show_message("Invalid position for %s" % summon.character_name)

func _on_summon_formation_broken(summon: BaseCharacter):
	combat_ui.show_message("%s has broken formation!" % summon.character_name)

func _on_unit_position_changed(unit: BaseCharacter, old_pos: Vector2, new_pos: Vector2):
	var tween = create_tween()
	tween.tween_property(unit, "global_position", new_pos, 0.3)
	await tween.finished
	combat_ui.update_unit_displays()

func _on_unit_stats_changed(unit: BaseCharacter, old_stats: Dictionary, new_stats: Dictionary):
	combat_ui.update_unit_stats(unit, old_stats, new_stats)

func _on_skill_cooldown_updated(unit: BaseCharacter, skill: Skill, remaining: int):
	combat_ui.update_skill_cooldown(unit, skill, remaining)

func _on_resource_depleted(unit: BaseCharacter, resource_type: String):
	combat_ui.show_message("%s has no %s remaining!" % [unit.character_name, resource_type])

func _on_status_effect_applied(unit: BaseCharacter, effect: Dictionary):
	combat_ui.show_status_effect(unit, effect)
	combat_ui.show_message("%s gained %s!" % [
		unit.character_name,
		effect.name
	])
	
func _on_status_effect_removed(unit: BaseCharacter, effect: Dictionary):
	combat_ui.remove_status_effect(unit, effect)
	combat_ui.show_message("%s's %s wore off" % [
		unit.character_name,
		effect.name
	])
	
func _on_condition_triggered(unit: BaseCharacter, condition: String):
	combat_ui.show_condition_trigger(unit, condition)
	
func _on_resistance_check_failed(unit: BaseCharacter, effect_type: String):
	combat_ui.show_message("%s resisted %s!" % [
		unit.character_name,
		effect_type
	])
	
func _on_immunity_triggered(unit: BaseCharacter, effect_type: String):
	combat_ui.show_message("%s is immune to %s!" % [
		unit.character_name,
		effect_type
	])

func _on_mana_spent(unit: BaseCharacter, amount: int):
	combat_ui.show_message("%s spent %d mana" % [unit.character_name, amount])
	combat_ui.update_unit_displays()

func _on_round_started(round_number: int):
	combat_ui.show_message("Round %d started!" % round_number)

func _on_round_ended(round_number: int):
	combat_ui.show_message("Round %d ended!" % round_number)
	combat_ui.update_unit_displays()

func _on_row_changed(unit: BaseCharacter, new_row: int):
	combat_ui.show_message("%s moved to %s row" % [
		unit.character_name,
		"front" if new_row == 0 else "back"
	])
	combat_ui.update_unit_displays()

func _on_scene_combat_ended(victory: bool):
	cleanup_combat()
	get_parent().handle_combat_result(victory)
