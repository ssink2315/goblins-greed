extends Node

enum AI_STRATEGY { AGGRESSIVE, DEFENSIVE, SUPPORT, RANDOM }
enum TargetPriority { LOWEST_HP, HIGHEST_THREAT, MOST_BUFFS, LEAST_RESISTANT }

signal action_chosen(action: Dictionary)

var combat_manager: Node
var calculator: Node
@onready var summon_ai = $SummonAI

# Add role-based behavior constants
const ROLE_BEHAVIORS = {
	"TANK": {
		"defensive_threshold": 0.4,  # HP % to prioritize defense
		"taunt_threshold": 0.7,     # HP % to use taunt abilities
		"protect_range": 200.0      # Distance to protect allies
	},
	"HEALER": {
		"heal_threshold": 0.6,      # HP % to prioritize healing
		"emergency_threshold": 0.3,  # HP % for emergency heals
		"buff_priority": 0.8        # Priority for buffing vs healing
	},
	"DPS": {
		"burst_threshold": 0.3,     # Enemy HP % to use burst skills
		"aoe_threshold": 3,         # Min enemies for AOE priority
		"combo_priority": 0.7       # Priority for maintaining combos
	},
	"SUPPORT": {
		"buff_threshold": 0.8,      # HP % to prioritize buffs
		"debuff_priority": 0.6,     # Priority for debuffing vs buffing
		"formation_range": 150.0    # Distance to maintain from allies
	}
}

# Add team coordination constants
const TEAM_TACTICS = {
	"FOCUS_FIRE": {
		"priority": 0.8,
		"min_attackers": 2,
		"target_threshold": 0.5  # Target HP % for focus fire
	},
	"PROTECT_HEALER": {
		"priority": 0.9,
		"protection_range": 200.0,
		"health_threshold": 0.4
	},
	"COMBO_SETUP": {
		"priority": 0.7,
		"max_setup_turns": 2,
		"min_combo_damage": 1.5  # Multiplier to consider combo worth setting up
	}
}

# Add team state tracking
var team_target: BaseCharacter = null
var planned_combos: Array[Dictionary] = []
var protecting_units: Dictionary = {}  # key: protector, value: protected unit

# Add adaptive strategy constants
const ADAPTATION_THRESHOLDS = {
	"PARTY_HP": 0.5,      # Party HP % to trigger defensive adaptation
	"MANA_LOW": 0.3,      # MP % to trigger resource conservation
	"DAMAGE_SPIKE": 0.4,  # HP loss % in one turn to trigger defensive stance
	"HEALING_PRESSURE": 0.6  # Party damage % to prioritize healing
}

# Add strategy tracking
var strategy_history: Array[Dictionary] = []
var party_damage_taken: Dictionary = {}
var successful_actions: Dictionary = {}
var failed_actions: Dictionary = {}

func _ready():
	combat_manager = get_parent()
	calculator = combat_manager.get_node("CombatCalculator")

func take_turn(character: BaseCharacter):
	# Add slight delay for better game feel
	await get_tree().create_timer(0.5).timeout
	
	var action_data
	if character in combat_manager.summons:
		action_data = summon_ai.get_summon_action(character)
	else:
		action_data = _decide_action(character)
	
	if action_data:
		action_chosen.emit(action_data)

func _decide_action(character: BaseCharacter) -> Dictionary:
	var role = character.role
	var allies = combat_manager.get_allies_of(character)
	
	# Check for team tactics first
	var team_action = _check_team_tactics(character, allies)
	if not team_action.is_empty():
		return team_action
	
	# Fall back to role-based behavior
	return _get_role_based_action(character, role)

func _check_team_tactics(character: BaseCharacter, allies: Array) -> Dictionary:
	# Check if we should join focus fire
	if team_target and team_target.is_alive():
		if _should_focus_fire(character, team_target):
			return _create_focus_fire_action(character, team_target)
	
	# Check if we need to protect healer
	var healer = allies.filter(func(ally): return ally.role == "HEALER")
	if not healer.is_empty() and _should_protect_healer(character, healer[0]):
		return _create_protect_action(character, healer[0])
	
	# Check for combo opportunities
	var combo_action = _check_combo_opportunities(character, allies)
	if not combo_action.is_empty():
		return combo_action
	
	return {}

func _should_focus_fire(attacker: BaseCharacter, target: BaseCharacter) -> bool:
	var tactics = TEAM_TACTICS.FOCUS_FIRE
	var attackers = combat_manager.get_allies_of(attacker).filter(
		func(ally): return ally.get_target() == target
	)
	
	return (attackers.size() >= tactics.min_attackers and 
			target.current_hp / target.max_hp <= tactics.target_threshold)

func _get_role_based_action(character: BaseCharacter, role: String) -> Dictionary:
	match role:
		"TANK":
			return _get_tank_action(character)
		"HEALER":
			return _get_healer_action(character)
		"DPS":
			return _get_dps_action(character)
		"SUPPORT":
			return _get_support_action(character)
	return {}

func _evaluate_possible_actions(character: BaseCharacter, strategy: int) -> Array:
	var scored_actions = []
	var allies = combat_manager.enemy_party
	var enemies = combat_manager.player_party
	
	# Evaluate basic attack
	for target in enemies:
		if target.is_alive():
			var score = _score_attack_action(character, target, strategy)
			scored_actions.append({
				"score": score,
				"action": {
					"type": "attack",
					"source": character,
					"target": target
				}
			})
	
	# Evaluate skills
	for skill in character.learned_skills:
		if character.current_mp >= skill.mp_cost and !character.is_skill_on_cooldown(skill):
			var targets = skill.is_support_skill() ? allies : enemies
			for target in targets:
				if target.is_alive():
					var score = _score_skill_action(character, skill, target, strategy)
					scored_actions.append({
						"score": score,
						"action": {
							"type": "skill",
							"source": character,
							"target": target,
							"skill": skill
						}
					})
	
	# Evaluate defend
	if character.current_hp < character.max_hp * 0.3:
		scored_actions.append({
			"score": _score_defend_action(character, strategy),
			"action": {
				"type": "defend",
				"source": character,
				"target": character
			}
		})
	
	return scored_actions

func _score_attack_action(attacker: BaseCharacter, target: BaseCharacter, strategy: int) -> float:
	var base_score = 50.0
	var estimated_damage = calculator.calculate_damage(attacker, target)
	
	# Adjust score based on strategy
	match strategy:
		AI_STRATEGY.AGGRESSIVE:
			base_score += estimated_damage * 1.5
			if target.current_hp <= estimated_damage:
				base_score += 100  # Prioritize killing blows
		AI_STRATEGY.DEFENSIVE:
			base_score += estimated_damage * 0.8
			if attacker.current_hp < attacker.max_hp * 0.5:
				base_score -= 20
		AI_STRATEGY.SUPPORT:
			base_score += estimated_damage * 0.6
	
	# Consider target's state
	if target.has_status_effect("Defend"):
		base_score -= 20
	if target.current_hp < target.max_hp * 0.3:
		base_score += 30  # Prioritize low HP targets
	
	return base_score

func _score_skill_action(user: BaseCharacter, skill: Skill, target: BaseCharacter, strategy: int) -> float:
	var base_score = 60.0  # Skills start with higher base score than attacks
	
	if skill.is_support_skill():
		base_score = _score_support_skill(user, skill, target, strategy)
	else:
		base_score = _score_offensive_skill(user, skill, target, strategy)
	
	# Consider MP efficiency
	base_score -= (skill.mp_cost / user.current_mp) * 20
	
	# Consider cooldown
	if skill.cooldown > 3:
		base_score -= 10
	
	return base_score

func _score_support_skill(user: BaseCharacter, skill: Skill, target: BaseCharacter, strategy: int) -> float:
	var score = 70.0
	
	# Healing skills
	if skill.has_healing():
		var hp_missing = target.max_hp - target.current_hp
		score += (hp_missing / target.max_hp) * 100
		
		if target.current_hp < target.max_hp * 0.3:
			score += 50  # Emergency healing priority
	
	# Buff skills
	if skill.has_buffs():
		if !target.has_positive_effects():
			score += 40
		else:
			score -= 20  # Avoid buff stacking
	
	return score

func _score_offensive_skill(user: BaseCharacter, skill: Skill, target: BaseCharacter, strategy: int) -> float:
	var score = 80.0
	
	# Consider damage potential
	if skill.has_damage():
		var estimated_damage = calculator.calculate_skill_damage(skill, user, target)
		score += estimated_damage * 1.2
		
		if target.current_hp <= estimated_damage:
			score += 100  # Killing blow priority
	
	# Consider debuffs
	if skill.has_debuffs():
		if !target.has_status_effect(skill.get_debuff_name()):
			score += 30
		else:
			score -= 20  # Avoid debuff stacking
	
	return score

func _score_defend_action(character: BaseCharacter, strategy: int) -> float:
	var score = 30.0
	
	# Higher score when low HP
	var hp_percent = character.current_hp / character.max_hp
	score += (1 - hp_percent) * 100
	
	# Consider strategy
	if strategy == AI_STRATEGY.DEFENSIVE:
		score += 30
	
	return score

func _choose_attack_target(targets: Array) -> BaseCharacter:
	# Prioritize low HP targets
	targets.sort_custom(func(a, b): return a.current_hp < b.current_hp)
	return targets[0]

func _get_character_strategy(character: BaseCharacter) -> AI_STRATEGY:
	if character.ai_strategy:
		return character.ai_strategy
	
	# Default strategy based on character type
	if character.is_healer():
		return AI_STRATEGY.SUPPORT
	elif character.is_tank():
		return AI_STRATEGY.DEFENSIVE
	elif character.is_damage_dealer():
		return AI_STRATEGY.AGGRESSIVE
	
	return AI_STRATEGY.RANDOM

func _get_valid_targets(character: BaseCharacter, action: String) -> Array:
	match action:
		"Attack":
			return combat_manager.player_party.filter(func(c): return c.is_alive())
		"Skill":
			var skill = _choose_skill(character)
			if skill and skill.is_support:
				return combat_manager.enemy_party.filter(func(c): return c.is_alive())
			return combat_manager.player_party.filter(func(c): return c.is_alive())
		"Defend":
			return [character]
	return []

func _get_available_actions(character: BaseCharacter) -> Array:
	var actions = ["Attack", "Defend"]
	if character.learned_skills.size() > 0 and character.current_mp > 0:
		actions.append("Skill")
	return actions

func _choose_skill(character: BaseCharacter) -> SkillData:
	var usable_skills = character.learned_skills.filter(func(s): 
		return s.mp_cost <= character.current_mp and !character.is_skill_on_cooldown(s)
	)
	if usable_skills.is_empty():
		return null
	return usable_skills[randi() % usable_skills.size()]

func _has_healing_skill(character: BaseCharacter) -> bool:
	return character.learned_skills.any(func(s): return s.is_healing and s.mp_cost <= character.current_mp)

func _should_use_support_skill(character: BaseCharacter) -> bool:
	var allies = combat_manager.enemy_party.filter(func(c): return c.is_alive())
	return allies.any(func(c): return c.current_hp < c.max_hp * 0.6)

func _track_action_result(action: Dictionary, success: bool):
	var action_type = action.get("type", "")
	var source = action.get("source")
	
	if success:
		successful_actions[source] = successful_actions.get(source, {})
		successful_actions[source][action_type] = successful_actions[source].get(action_type, 0) + 1
	else:
		failed_actions[source] = failed_actions.get(source, {})
		failed_actions[source][action_type] = failed_actions[source].get(action_type, 0) + 1

func _adapt_strategy(character: BaseCharacter) -> AI_STRATEGY:
	var current_strategy = _get_character_strategy(character)
	var party = combat_manager.get_allies_of(character)
	
	# Track party state
	var party_hp_percent = _get_party_hp_percent(party)
	var character_mp_percent = character.current_mp / character.max_mp
	
	# Analyze recent damage patterns
	var recent_damage = party_damage_taken.get(character, [])
	var damage_spike = _detect_damage_spike(recent_damage)
	
	# Adapt based on conditions
	if damage_spike or party_hp_percent < ADAPTATION_THRESHOLDS.PARTY_HP:
		return AI_STRATEGY.DEFENSIVE
	elif _needs_healing_pressure(party):
		return AI_STRATEGY.SUPPORT
	elif character_mp_percent > ADAPTATION_THRESHOLDS.MANA_LOW and _is_advantage_state():
		return AI_STRATEGY.AGGRESSIVE
	
	return current_strategy

func _detect_damage_spike(damage_history: Array) -> bool:
	if damage_history.size() < 2:
		return false
	
	var last_damage = damage_history[-1]
	var max_hp = damage_history[-1].max_hp
	return last_damage / max_hp > ADAPTATION_THRESHOLDS.DAMAGE_SPIKE

func _needs_healing_pressure(party: Array) -> bool:
	var damaged_count = 0
	for member in party:
		if member.current_hp / member.max_hp < ADAPTATION_THRESHOLDS.HEALING_PRESSURE:
			damaged_count += 1
	return damaged_count >= party.size() / 2

func _is_advantage_state() -> bool:
	var player_party = combat_manager.player_party
	var enemy_party = combat_manager.enemy_party
	
	var player_strength = _calculate_party_strength(player_party)
	var enemy_strength = _calculate_party_strength(enemy_party)
	
	return enemy_strength > player_strength * 1.2

func _calculate_party_strength(party: Array) -> float:
	var strength = 0.0
	for member in party:
		if member.is_alive():
			strength += member.current_hp / member.max_hp
			strength += member.current_mp / member.max_mp
			strength += member.get_active_buffs().size() * 0.2
	return strength
