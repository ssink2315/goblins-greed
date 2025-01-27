# WeaponData.gd
extends ItemData
class_name WeaponData

# Enum for weapon types
enum WeaponType { SWORD, GREATSWORD, STAFF, AXE, BOW, KNIFE, MACE, SPEAR }

# Weapon-specific properties
@export var weapon_type: WeaponType
@export var min_damage: int = 0
@export var max_damage: int = 0
@export var crit_chance: float = 0.0  # Critical hit percentage

# Methods
func get_damage_range() -> String:
	return "%d-%d" % [min_damage, max_damage]

func calculate_average_damage() -> float:
	return (min_damage + max_damage) / 2.0
