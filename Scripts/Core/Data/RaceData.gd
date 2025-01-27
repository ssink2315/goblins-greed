extends Resource
class_name RaceData

@export var race_name: String = ""
@export_multiline var description: String = ""
@export var base_stats: Dictionary = {
    "STR": 10,
    "AGI": 10,
    "INT": 10,
    "VIT": 10,
    "TEC": 10,
    "WIS": 10
}

@export var passive_name: String = ""
@export_multiline var passive_description: String = ""

# Load racial bonuses from an external data file
var racial_bonuses: Dictionary = {}

func _ready():
    load_racial_bonuses()

func load_racial_bonuses():
    var file = File.new()
    if file.open("res://Resources/Data/racial_bonuses.json", File.READ) == OK:
        var json_data = file.get_as_text()
        racial_bonuses = JSON.parse(json_data).result
        file.close()
    else:
        push_error("Failed to load racial bonuses from file.")

func apply_racial_bonuses(character: BaseCharacter):
    # Apply base stats
    for stat in base_stats:
        if character.get(stat) != null:
            character.set(stat, base_stats[stat])
    
    # Apply racial passive effects
    if racial_bonuses.has(race_name):
        var bonuses = racial_bonuses[race_name]
        for key in bonuses.keys():
            if character.has_method(key):
                character.call(key, bonuses[key])
    else:
        # Default case for unhandled races
        push_warning("No bonuses defined for race: " + race_name)
        # Apply default bonuses or handle gracefully
        apply_default_bonuses(character)

    character.calculate_secondary_stats()

func apply_default_bonuses(character: BaseCharacter):
    # Define default bonuses for unhandled races
    character.set("STR", character.get("STR") + 0)
    character.set("AGI", character.get("AGI") + 0)
    character.set("INT", character.get("INT") + 0)
    character.set("VIT", character.get("VIT") + 0)
    character.set("TEC", character.get("TEC") + 0)
    character.set("WIS", character.get("WIS") + 0)

func get_race_info() -> Dictionary:
    return {
        "name": race_name,
        "description": description,
        "passive_name": passive_name,
        "passive_description": passive_description,
        "base_stats": base_stats
    } 