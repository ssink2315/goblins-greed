extends Resource
class_name SkillData

enum DamageType { PHYSICAL, MAGICAL, PURE }
enum Element { NONE, FIRE, ICE, NATURE, HOLY, DARK, ARCANE }
enum TargetType { 
	SINGLE,         # Single target
	ALL,           # All valid targets
	ROW,           # Full row of targets
	RANDOM,        # Random targets
	SELF,          # Self only
	PARTY,         # Full party
	SINGLE_ALLY,   # Single ally
	ALL_ALLIES,    # All allies
	SINGLE_ENEMY,  # Single enemy
	ALL_ENEMIES    # All enemies
}

@export var skill_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var skill_type: String = "active"  # active, passive, or buff
@export var target_type: String = "single"  # Uses TargetType enum values
@export var mana_cost: int = 0
@export var cooldown: int = 0
@export var base_power: int = 0
@export var damage_type: DamageType
@export var element: Element = Element.NONE
@export var effects: Array[Dictionary] = []

signal skill_executed(data: Dictionary)

func can_use(user: BaseCharacter) -> bool:
	return user.current_mana >= mana_cost and user.get_skill_cooldown(skill_name) <= 0

func use_skill(user: BaseCharacter, targets: Array) -> Dictionary:
	if not can_use(user):
		return {
			"success": false,
			"reason": "Cannot use skill"
		}
	
	user.modify_mp(-mana_cost)
	user.set_skill_cooldown(skill_name, cooldown)
	
	var results = []
	
	match target_type:
		"single":
			results.append(_process_skill_effects(user, targets[0]))
		"all":
			for target in targets:
				results.append(_process_skill_effects(user, target))
		"self":
			results.append(_process_skill_effects(user, user))
	
	skill_executed.emit({
		"user": user,
		"targets": targets,
		"results": results
	})
	
	return {
		"success": true,
		"results": results
	}

func _process_skill_effects(user: BaseCharacter, target: BaseCharacter) -> Dictionary:
	var result = {
		"target": target,
		"damage": 0,
		"healing": 0,
		"effects": [],
		"element": element
	}
	
	if skill_type == "active":
		if base_power > 0:
			result.damage = calculate_damage(user, target)
			target.take_damage(result.damage)
		
		for effect in effects:
			var effect_result = apply_effect(target, effect)
			result.effects.append(effect_result)
	
	return result

func calculate_damage(user: BaseCharacter, target: BaseCharacter) -> int:
	var damage = base_power
	var final_damage = 0
	
	# Base damage calculation based on damage type
	match damage_type:
		DamageType.PHYSICAL:
			damage *= (user.phys_dmg_mod / 100.0)
			final_damage = max(1, damage - target.phys_def)
			if user.current_row == CombatState.Row.BACK:
				final_damage = int(final_damage * CombatState.BACK_ROW_DAMAGE_MOD)
				
		DamageType.MAGICAL:
			damage *= (user.magic_dmg_mod / 100.0)
			final_damage = max(1, damage - target.magic_def)
			
		DamageType.PURE:
			final_damage = damage # True damage ignores defense
	
	# Apply elemental modifiers
	final_damage = _apply_elemental_damage(final_damage, target)
	
	# Check for elemental weakness/resistance
	var element_modifier = target.get_element_modifier(element)
	final_damage = int(final_damage * element_modifier)
	
	return max(1, final_damage)

func _apply_elemental_damage(damage: int, target: BaseCharacter) -> int:
	match element:
		Element.NONE:
			return damage
		Element.FIRE:
			return int(damage * (1.0 - (target.fire_resistance / 100.0)))
		Element.ICE:
			return int(damage * (1.0 - (target.ice_resistance / 100.0)))
		Element.NATURE:
			return int(damage * (1.0 - (target.nature_resistance / 100.0)))
		Element.HOLY:
			return int(damage * (1.0 - (target.holy_resistance / 100.0)))
		Element.DARK:
			return int(damage * (1.0 - (target.dark_resistance / 100.0)))
		Element.ARCANE:
			return int(damage * (1.0 - (target.arcane_resistance / 100.0)))

func apply_effect(target: BaseCharacter, effect: Dictionary) -> Dictionary:
	var effect_result = {
		"type": effect.type,
		"success": true
	}
	
	match effect.type:
		"status":
			target.apply_status(effect.status, effect.duration)
			effect_result["status"] = effect.status
			effect_result["duration"] = effect.duration
			
		"stat_modify":
			target.modify_stat(effect.stat, effect.value, effect.duration)
			effect_result["stat"] = effect.stat
			effect_result["value"] = effect.value
			effect_result["duration"] = effect.duration
			
		"heal":
			var heal_amount = int(base_power * (effect.value / 100.0))
			target.heal(heal_amount)
			effect_result["healing"] = heal_amount
			
		"buff":
			target.apply_buff(effect.buff_type, effect.value, effect.duration)
			effect_result["buff_type"] = effect.buff_type
			effect_result["value"] = effect.value
			effect_result["duration"] = effect.duration
			
		"debuff":
			target.apply_debuff(effect.debuff_type, effect.value, effect.duration)
			effect_result["debuff_type"] = effect.debuff_type
			effect_result["value"] = effect.value
			effect_result["duration"] = effect.duration
	
	return effect_result

func get_element_color() -> Color:
	match element:
		Element.FIRE:
			return Color(1, 0.2, 0.2)  # Red
		Element.ICE:
			return Color(0.2, 0.8, 1)  # Light Blue
		Element.NATURE:
			return Color(1, 1, 0)      # Yellow
		Element.HOLY:
			return Color(1, 1, 0.8)    # Light Yellow
		Element.DARK:
			return Color(0.5, 0, 0.5)  # Purple
		Element.ARCANE:
			return Color(0.6, 0.4, 0.2) # Brown
		_:
			return Color.WHITE

func get_skill_info() -> Dictionary:
	return {
		"name": skill_name,
		"description": description,
		"mana_cost": mana_cost,
		"cooldown": cooldown,
		"type": skill_type,
		"target_type": target_type,
		"damage_type": DamageType.keys()[damage_type],
		"element": Element.keys()[element],
		"element_color": get_element_color()
	}

func apply_effects(user, target, combat_system):
	var results = []
	
	for effect in effects:
		match effect.type:
			"damage":
				results.append(apply_damage(user, target, effect))
			"heal":
				results.append(apply_healing(user, target, effect))
			"buff", "debuff":
				results.append(apply_stat_modifier(target, effect))
			"status":
				results.append(apply_status(target, effect))
			"hp_cost":
				results.append(apply_hp_cost(user, effect))
			"hp_cost_max":
				var cost = int(user.max_hp * (effect.value / 100.0))
				results.append(apply_hp_cost(user, {"value": cost}))
			"multi_hit":
				for i in range(effect.hits):
					var random_target = combat_system.get_random_target(effect.get("target", "random_enemies"))
					if random_target:
						results.append(apply_damage(user, random_target, effect))
			"row_target":
				var row_targets = combat_system.get_row_targets(target)
				for row_target in row_targets:
					results.append(apply_damage(user, row_target, effect))
			"passive":
				results.append(apply_passive(user, effect))
			"party_passive":
				for member in user.get_party():
					results.append(apply_passive(member, effect))
			"status_immunity":
				results.append(apply_immunity(user, effect))
	
	return results

func apply_status(target: BaseCharacter, effect: Dictionary) -> Dictionary:
	var result = {
		"type": "status",
		"target": target,
		"status": effect.status,
		"duration": effect.duration,
		"success": true
	}
	
	target.apply_status(effect.status, effect.duration)
	return result

func apply_immunity(target: BaseCharacter, effect: Dictionary) -> Dictionary:
	var result = {
		"type": "immunity",
		"target": target,
		"status": effect.status,
		"success": true
	}
	
	target.add_status_immunity(effect.status)
	return result

func apply_hp_cost(user: BaseCharacter, effect: Dictionary) -> Dictionary:
	var result = {
		"type": "hp_cost",
		"target": user,
		"value": effect.value,
		"success": true
	}
	
	user.take_damage(effect.value)
	return result
