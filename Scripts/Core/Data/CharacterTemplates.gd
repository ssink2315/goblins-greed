extends Node

const PLAYER_TEMPLATES = {
    "MAGIC_KNIGHT": {
        "name": "Magic Knight",
        "race": "Human",
        "class": "Magic Knight",
        "starting_equipment": {
            "weapon": "apprentice_sword",
            "armor": "light_chainmail",
            "accessory1": "magic_ring"
        }
    },
    "ADVENTURER": {
        "name": "Adventurer",
        "race": "Ilf",
        "class": "Adventurer",
        "starting_equipment": {
            "weapon": "short_sword",
            "armor": "leather_armor",
            "accessory1": "adventurer_charm"
        }
    },
    "DEATH_KNIGHT": {
        "name": "Death Knight",
        "race": "Goblin",
        "class": "Death Knight",
        "starting_equipment": {
            "weapon": "dark_blade",
            "armor": "dark_plate",
            "accessory1": "death_sigil"
        }
    }
}

func create_player_character(template_id: String) -> PlayerCharacter:
    if not PLAYER_TEMPLATES.has(template_id):
        push_error("Template not found: " + template_id)
        return null
        
    var template = PLAYER_TEMPLATES[template_id]
    var character = PlayerCharacter.new()
    
    # Initialize base character
    character.initialize(
        template.name,
        template.race,
        template.class
    )
    
    # Add starting equipment
    for slot in template.starting_equipment:
        var item_id = template.starting_equipment[slot]
        var item = GameDatabase.get_item(item_id)
        if item:
            character.equip_item(slot, item)
    
    return character

func get_template_info(template_id: String) -> Dictionary:
    if not PLAYER_TEMPLATES.has(template_id):
        return {}
        
    var template = PLAYER_TEMPLATES[template_id]
    var race_data = GameDatabase.get_race_data(template.race)
    var class_data = GameDatabase.get_class_data(template.class)
    
    return {
        "name": template.name,
        "race": {
            "name": template.race,
            "description": race_data.description if race_data else "",
            "passive": race_data.passive_name if race_data else ""
        },
        "class": {
            "name": template.class,
            "description": class_data.description if class_data else "",
            "role": class_data.role if class_data else ""
        }
    }

# Reference existing paths from PathData.gd
func get_starting_paths(template_id: String) -> Array:
    if not PLAYER_TEMPLATES.has(template_id):
        return []
        
    var template = PLAYER_TEMPLATES[template_id]
    return PathData.get_paths_for_class(template.class) 