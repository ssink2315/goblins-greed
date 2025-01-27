# AccessoryData.gd
extends ItemData
class_name AccessoryData

@export var stat_bonuses: Dictionary = {}  # Example: {"crit_chance": 5, "evasion": 3}

# Methods
func get_stat_bonuses() -> Dictionary:
	return stat_bonuses

func describe_bonuses() -> String:
	return ", ".join(["%s: +%d" % [stat, value] for stat, value in stat_bonuses.items()])
