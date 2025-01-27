extends BaseCharacter
class_name EnemyCharacter

# Enemy specific properties
var difficulty_level: int = 1
var enemy_type: String = "normal"  # normal, elite, boss
var loot_table: Array[Dictionary] = []
var behavior_pattern: String = "aggressive"  # aggressive, defensive, tactical
var spawn_level: int = 1

# Combat behavior
var preferred_row: int = 0  # 0 for front, 1 for back
var skill_preferences: Dictionary = {
	"low_health": 0,  # Skill index to use when low health
	"high_health": 0  # Skill index to use when high health
}

# Signals
signal loot_dropped(items: Array)

func _init():
	super._init()

func initialize_enemy(enemy_data: Dictionary):
	character_name = enemy_data.name
	level = enemy_data.level
	enemy_type = enemy_data.type
	loot_table = enemy_data.loot_table
	behavior_pattern = enemy_data.behavior
	preferred_row = enemy_data.preferred_row
	skill_preferences = enemy_data.skill_preferences
	
	# Scale stats based on level and difficulty
	scale_stats()

func scale_stats():
	var level_multiplier = 1.0 + (0.1 * (level - 1))
	var difficulty_multiplier = 1.0
	
	match enemy_type:
		"elite":
			difficulty_multiplier = 1.5
		"boss":
			difficulty_multiplier = 2.5
	
	STR = int(STR * level_multiplier * difficulty_multiplier)
	AGI = int(AGI * level_multiplier * difficulty_multiplier)
	INT = int(INT * level_multiplier * difficulty_multiplier)
	VIT = int(VIT * level_multiplier * difficulty_multiplier)
	TEC = int(TEC * level_multiplier * difficulty_multiplier)
	WIS = int(WIS * level_multiplier * difficulty_multiplier)
	
	calculate_secondary_stats()

func choose_action() -> Dictionary:
	var action = {
		"type": "none",
		"target": null,
		"skill_index": -1
	}
	
	# Low health behavior
	if current_hp < max_hp * 0.3:
		if current_row != preferred_row:
			return {"type": "move", "target": null}
		elif has_healing_skill():
			return {
				"type": "skill",
				"target": self,
				"skill_index": get_healing_skill_index()
			}
	
	# Normal behavior based on pattern
	match behavior_pattern:
		"aggressive":
			action = choose_aggressive_action()
		"defensive":
			action = choose_defensive_action()
		"tactical":
			action = choose_tactical_action()
	
	return action

func choose_aggressive_action() -> Dictionary:
	if current_row != 0:  # If not in front row
		return {"type": "move", "target": null}  # Move to front
	
	# 30% chance to use skill if available
	if has_offensive_skill() and randf() < 0.3:
		return {
			"type": "skill",
			"target": null,  # CombatManager will select appropriate target
			"skill_index": skill_preferences.high_health
		}
	
	return {
		"type": "attack",
		"target": null  # CombatManager will select appropriate target
	}

func choose_defensive_action() -> Dictionary:
	if current_hp < max_hp * 0.5:
		return {"type": "defend"}
	
	if current_row == 0 and current_hp < max_hp * 0.7:
		return {"type": "move", "target": null}  # Move to back row
	
	return choose_aggressive_action()

func choose_tactical_action() -> Dictionary:
	if current_row != preferred_row:
		return {"type": "move", "target": null}
	
	if has_offensive_skill() and current_mana >= skills[skill_preferences.high_health].mana_cost:
		return {
			"type": "skill",
			"target": null,
			"skill_index": skill_preferences.high_health
		}
	
	return {
		"type": "attack",
		"target": null
	}

func has_offensive_skill() -> bool:
	return skill_preferences.high_health >= 0 and skill_preferences.high_health < skills.size()

func has_healing_skill() -> bool:
	return skill_preferences.low_health >= 0 and skill_preferences.low_health < skills.size()

func get_healing_skill_index() -> int:
	return skill_preferences.low_health

func drop_loot() -> Array:
	var drops = []
	for item in loot_table:
		if randf() <= item.drop_rate:
			drops.append(item.item)
	
	emit_signal("loot_dropped", drops)
	return drops

func die():
	drop_loot()
	super.die()
