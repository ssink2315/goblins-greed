extends Resource
class_name CompanionData

@export var companion_id: String = ""
@export var possible_names: Array[String] = []
@export var possible_races: Array[String] = []
@export var possible_classes: Array[String] = []
@export var personality_range: Dictionary = {
	"kind": {"min": -5, "max": 5},
	"brave": {"min": -5, "max": 5},
	"cunning": {"min": -5, "max": 5}
}
@export var starting_relationship: int = 50
@export var preferred_combat_roles: Array[int] = []  # Uses CompanionCharacter.CombatRole enum
