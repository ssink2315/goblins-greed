# IdolData.gd
extends ItemData
class_name IdolData

@export var passive_effect: String = ""  # E.g., "Increases healing received by 15%."
@export var effect_stats: Dictionary = {}  # Example: {"hp_regeneration": 5, "crit_chance": 10}

# Methods
func get_passive_effect() -> String:
	return passive_effect
