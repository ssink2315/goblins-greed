extends Resource
class_name ClassData

enum ClassType { WARRIOR, BRIGAND, WIZARD, FAE_TOUCHED, MAGIC_KNIGHT, ADVENTURER, DEATH_KNIGHT, DRAGOON }

@export var class_name: String = ""
@export_multiline var description: String = ""
@export var stat_growth: Dictionary = {
	"STR": 0,
	"AGI": 0,
	"INT": 0,
	"VIT": 0,
	"TEC": 0,
	"WIS": 0
}

@export var weapon_proficiencies: Array[String] = []
@export var armor_proficiencies: Array[String] = []
@export var starting_skills: Array[Resource] = []
@export var skill_paths: Array[String] = []
@export var class_traits: Array[Dictionary] = []

func apply_class_bonuses(character: BaseCharacter):
	# Apply stat growth
	for stat in stat_growth:
		if character.get(stat) != null:
			character.set(stat, character.get(stat) + stat_growth[stat])
	
	# Set proficiencies
	character.weapon_proficiencies = weapon_proficiencies
	character.armor_proficiencies = armor_proficiencies
	
	# Add starting skills
	for skill in starting_skills:
		character.add_skill(skill)
	
	# Apply class traits
	for trait in class_traits:
		apply_trait(character, trait)
	
	character.calculate_secondary_stats()

func apply_trait(character: BaseCharacter, trait: Dictionary):
	match trait.type:
		"stat_modifier":
			if character.get(trait.stat) != null:
				character.set(trait.stat, character.get(trait.stat) + trait.value)
		"resistance":
			character.resistances[trait.element] += trait.value
		"combat_modifier":
			match trait.modifier:
				"crit_damage":
					character.crit_dmg_bonus += trait.value
				"initiative":
					character.initiative += trait.value

func get_class_info() -> Dictionary:
	return {
		"name": class_name,
		"description": description,
		"weapon_proficiencies": weapon_proficiencies,
		"armor_proficiencies": armor_proficiencies,
		"stat_growth": stat_growth,
		"traits": class_traits
	}

# Add to existing class types
enum ClassType {
	WARRIOR,  # existing
	BRIGAND,
	WIZARD,
	FAE_TOUCHED
}

# Class definitions
const CLASS_DATA = {
	ClassType.BRIGAND: {
		"name": "Brigand",
		"description": "Quick and deadly fighters who rely on speed and precision.",
		"weapon_proficiencies": ["KNIFE", "SWORD"],
		"armor_proficiencies": ["LIGHT", "MEDIUM"],
		"stat_growth": {
			"STR": 1,
			"AGI": 2,
			"INT": 0,
			"VIT": 2,
			"TEC": 1,
			"WIS": 0
		}
	},
	ClassType.WIZARD: {
		"name": "Wizard",
		"description": "Masters of destructive magic who shape reality to their will.",
		"weapon_proficiencies": ["STAFF"],
		"armor_proficiencies": ["ROBES"],
		"stat_growth": {
			"STR": 0,
			"AGI": 0,
			"INT": 3,
			"VIT": 1,
			"TEC": 1,
			"WIS": 1
		}
	},
	ClassType.FAE_TOUCHED: {
		"name": "Fae-Touched",
		"description": "Blessed by the fae, they wield supportive magic and healing arts.",
		"weapon_proficiencies": ["MACE"],
		"armor_proficiencies": ["GARMENTS"],
		"stat_growth": {
			"STR": 0,
			"AGI": 1,
			"INT": 2,
			"VIT": 1,
			"TEC": 0,
			"WIS": 2
		}
	},
	ClassType.MAGIC_KNIGHT: {
		"name": "Magic Knight",
		"description": "Powerful warriors who wield both sword and spell.",
		"weapon_proficiencies": ["GREATSWORD", "SWORD"],
		"armor_proficiencies": ["HEAVY"],
		"stat_growth": {
			"STR": 2,
			"AGI": 0,
			"INT": 2,
			"VIT": 1,
			"TEC": 0,
			"WIS": 1
		}
	},
	ClassType.ADVENTURER: {
		"name": "Adventurer",
		"description": "Wandering heroes who care for adventure more than they do coin.",
		"weapon_proficiencies": ["SWORD", "SPEAR", "KNIFE", "AXE", "BOW", "STAFF"],
		"armor_proficiencies": ["LIGHT", "MEDIUM"],
		"stat_growth": {
			"STR": 1,
			"AGI": 1,
			"INT": 1,
			"VIT": 1,
			"TEC": 1,
			"WIS": 1
		}
	},
	ClassType.DEATH_KNIGHT: {
		"name": "Wizard",
		"description": "Masters of dark necromancies and forbidden blade arts.",
		"weapon_proficiencies": ["GREATSWORD", "SWORD"],
		"armor_proficiencies": ["HEAVY"],
		"stat_growth": {
			"STR": 2,
			"AGI": 0,
			"INT": 1,
			"VIT": 2,
			"TEC": 0,
			"WIS": 1
		}
	},
	ClassType.DRAGOON: {
		"name": "Wizard",
		"description": "Masters of destructive magic who shape reality to their will.",
		"weapon_proficiencies": ["SPEAR"],
		"armor_proficiencies": ["MEDIUM", "HEAVY"],
		"stat_growth": {
			"STR": 2,
			"AGI": 2,
			"INT": 0,
			"VIT": 1,
			"TEC": 1,
			"WIS": 0
		}
	}
}
