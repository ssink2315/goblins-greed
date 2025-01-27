# ArmorData.gd
extends ItemData
class_name ArmorData

# Enum for armor types
enum ArmorType { LIGHT, MEDIUM, HEAVY, ROBES, GARMENTS }

# Armor-specific properties
@export var armor_type: ArmorType
@export var defense: int = 0
@export var magic_defense: int = 0
@export var evasion: float = 0.0  # Evasion percentage
@export var movement_penalty: float = 0.0  # Penalty to agility/speed

# Methods
func get_defense_stats() -> String:
	return "DEF: %d, MDEF: %d" % [defense, magic_defense]
