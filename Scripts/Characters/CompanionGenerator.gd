extends Node
class_name CompanionGenerator

const NAME_PARTS = {
	"human": {
		"first": ["Alex", "Morgan", "Jordan", "Sam", "Riley", "Taylor", "Casey", "Quinn"],
		"last": ["Smith", "Walker", "Knight", "Rivers", "Storm", "Woods", "Stone"]
	},
	"elf": {
		"first": ["Aerin", "Theron", "Lyra", "Sylvan", "Elowen", "Galad", "Varis"],
		"last": ["Starweave", "Moonwhisper", "Sunseeker", "Dawnwind", "Nightvale"]
	}
	"dwarf": {
		"first": ["Thorin", "Darin", "Grida", "Brunhild", "Balin", "Durin", "Thora"],
		"last": ["Ironbeard", "Stonefist", "Goldweaver", "Steelhart", "Deepdelver"]
	}
}

const STAT_VARIATION: int = 2  # Maximum points above or below base stats

func generate_companion(level: int = 1) -> CompanionCharacter:
	var companion = CompanionCharacter.new()
	
	# Select random race and class
	var race = _select_random_race()
	var class_title = _select_random_class()
	var name = _generate_name(race)
	
	# Generate companion data
	var companion_data = {
		"name": name,
		"race": race,
		"class_name": class_title,
		"level": level,
		"traits": _generate_personality_traits(),
		"relationship_level": randi_range(40, 60),
		"combat_role": _select_random_combat_role()
	}
	
	# Initialize companion
	companion.initialize(companion_data)
	
	# Randomize stats slightly
	_randomize_stats(companion)
	
	return companion

func _select_random_race() -> String:
	var races = GameDatabase.races.keys()
	return races[randi() % races.size()]

func _select_random_class() -> String:
	var classes = GameDatabase.classes.keys()
	return classes[randi() % classes.size()]

func _generate_name(race: String) -> String:
	var race_names = NAME_PARTS.get(race.to_lower(), NAME_PARTS["human"])
	var first = race_names["first"][randi() % race_names["first"].size()]
	var last = race_names["last"][randi() % race_names["last"].size()]
	return first + " " + last

func _generate_personality_traits() -> Dictionary:
	return {
		"kind": randi_range(-10, 10),
		"brave": randi_range(-10, 10),
		"cunning": randi_range(-10, 10)
	}

func _select_random_combat_role() -> int:
	return randi() % CompanionCharacter.CombatRole.size()

func _randomize_stats(companion: CompanionCharacter) -> void:
	# Slightly randomize each base stat
	companion.STR += randi_range(-STAT_VARIATION, STAT_VARIATION)
	companion.AGI += randi_range(-STAT_VARIATION, STAT_VARIATION)
	companion.INT += randi_range(-STAT_VARIATION, STAT_VARIATION)
	companion.VIT += randi_range(-STAT_VARIATION, STAT_VARIATION)
	companion.TEC += randi_range(-STAT_VARIATION, STAT_VARIATION)
	companion.WIS += randi_range(-STAT_VARIATION, STAT_VARIATION)
	
	# Recalculate secondary stats
	companion.calculate_secondary_stats()
