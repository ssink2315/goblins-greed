extends Node

const CombatState = preload("res://Scripts/Combat/CombatState.gd")
const CRIT_MULTIPLIER = 1.5
const ROW_DAMAGE_MODIFIER = {
	"FRONT": 1.0,
	"BACK": 0.8
}

func calculate_damage(attacker: BaseCharacter, target: BaseCharacter, skill: SkillData = null) -> Dictionary:
	var damage_type = skill.damage_type if skill else "physical"
	var base_damage = _get_base_damage(attacker, skill)
	var crit = _roll_critical(attacker, target)
	
	# Calculate modifiers
	var row_mod = ROW_DAMAGE_MODIFIER["BACK"] if target.current_row == PartyManager.ROW.BACK else ROW_DAMAGE_MODIFIER["FRONT"]
	var defense_mod = _calculate_defense_modifier(target, damage_type)
	var status_mod = _calculate_status_modifiers(attacker, target, damage_type)
	
	# Apply all modifiers
	var final_damage = base_damage * row_mod * defense_mod * status_mod
	if crit:
		final_damage *= CRIT_MULTIPLIER
	
	# Process status effects
	var applied_effects = []
	if skill:
		applied_effects = _process_status_effects(skill, attacker, target)
	
	return {
		"damage": int(final_damage),
		"critical": crit,
		"effects": applied_effects,
		"damage_type": damage_type
	}

func _get_base_damage(attacker: BaseCharacter, skill: SkillData = null) -> float:
	if skill:
		return skill.base_power * (attacker.magic_attack if skill.damage_type == "magical" else attacker.attack)
	return attacker.attack

func _roll_critical(attacker: BaseCharacter, target: BaseCharacter) -> bool:
	var crit_chance = attacker.crit_rate - target.crit_res
	return randf() < (crit_chance / 100.0)

func _calculate_defense_modifier(target: BaseCharacter, damage_type: String) -> float:
	if damage_type == "magical":
		return 1.0 - (target.magic_res / 100.0)
	else:
		return 100.0 / (100.0 + target.defense)

func _calculate_status_modifiers(attacker: BaseCharacter, target: BaseCharacter, damage_type: String) -> float:
	var modifier = 1.0
	
	# Attacker status effects
	for effect in attacker.status_effects:
		if damage_type == "physical":
			modifier *= (1.0 + effect.stat_modifiers.get("phys_dmg_mod", 0) / 100.0)
		elif damage_type == "magical":
			modifier *= (1.0 + effect.stat_modifiers.get("mag_dmg_mod", 0) / 100.0)
	
	# Target status effects
	for effect in target.status_effects:
		if damage_type == "physical":
			modifier *= (1.0 + effect.stat_modifiers.get("phys_def_mod", 0) / 100.0)
		elif damage_type == "magical":
			modifier *= (1.0 + effect.stat_modifiers.get("mag_def_mod", 0) / 100.0)
	
	return modifier

func _process_status_effects(skill: SkillData, attacker: BaseCharacter, target: BaseCharacter) -> Array:
	var applied_effects = []
	
	for effect_data in skill.status_effects:
		var effect = _create_status_effect(effect_data)
		if effect and effect.can_be_applied_to(target):
			var success_rate = effect_data.base_chance * (1.0 + attacker.status_power/100.0) * (1.0 - target.debuff_res/100.0)
			if randf() < success_rate:
				target.add_status_effect(effect)
				applied_effects.append(effect.effect_name)
	
	return applied_effects

func _create_status_effect(effect_data: Dictionary) -> StatusEffect:
	match effect_data.type:
		"burn":
			return BurnEffect.new()
		"poison":
			return PoisonEffect.new()
		"stun":
			return StunEffect.new()
	return null

func calculate_healing(healer: BaseCharacter, target: BaseCharacter, amount: int) -> int:
	var heal_power = amount * (1.0 + (healer.WIS * 0.1))
	return floor(heal_power)
