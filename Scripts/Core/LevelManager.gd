extends Node
class_name LevelManager

signal gain_level(new_level: int)
signal stats_increased(stat_increases: Dictionary)

const BASE_XP_REQUIREMENT: int = 100
const XP_GROWTH_FACTOR: float = 1.5

var character: BaseCharacter
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = BASE_XP_REQUIREMENT

func _init(owner: BaseCharacter):
	character = owner
	_calculate_next_level_xp()

func add_experience(amount: int):
	current_xp += amount
	while current_xp >= xp_to_next_level:
		level_up()

func level_up():
	current_xp -= xp_to_next_level
	current_level += 1
	
	var stat_increases = _calculate_stat_growth()
	_apply_stat_increases(stat_increases)
	
	_calculate_next_level_xp()
	
	emit_signal("level_up", current_level)
	emit_signal("stats_increased", stat_increases)

func _calculate_next_level_xp():
	xp_to_next_level = int(BASE_XP_REQUIREMENT * pow(XP_GROWTH_FACTOR, current_level - 1))

func _calculate_stat_growth() -> Dictionary:
	var growth_rates = GameDatabase.classes[character.class_type]["stat_growth"]
	var increases = {}
	
	# Calculate base increases from growth rates
	for stat in growth_rates:
		var base_increase = growth_rates[stat]
		var random_bonus = randi() % 2  # 0 or 1 random bonus
		increases[stat] = base_increase + random_bonus
	
	return increases

func _apply_stat_increases(increases: Dictionary):
	for stat in increases:
		var current_value = character.get(stat)
		character.set(stat, current_value + increases[stat])
	
	character.calculate_secondary_stats()

# Get formatted string of stat changes for UI
func get_level_up_text(stat_increases: Dictionary) -> String:
	var text = "Level Up! %s is now level %d\n" % [character.character_name, current_level]
	text += "Stat Increases:\n"
	for stat in stat_increases:
		text += "%s: +%d\n" % [stat, stat_increases[stat]]
	return text
