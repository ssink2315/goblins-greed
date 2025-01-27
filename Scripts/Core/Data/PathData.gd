extends Resource
class_name PathData

enum TalentType { MAJOR, MINOR }
enum SkillType { ACTIVE, PASSIVE, BUFF }

@export var path_id: String
@export var path_name: String
@export_multiline var description: String
@export var major_talent_pool: Array[String]  # List of major talents
@export var minor_talent_pool: Array[String]  # List of minor talents
@export var stat_distribution: Dictionary  # Distribution of stats for this path

# Default paths for races without defined skills yet
static var PLACEHOLDER_PATHS = {
    "Goblin": {
        "Shadowcraft": {
            "main_stat": "AGI",
            "secondary_stat": "TEC",
            "major_talents": [
                {"name": "Shadow Strike", "type": "Skill", "description": "Deal medium physical damage with high crit chance"},
                {"name": "Cunning Trap", "type": "Skill", "description": "Set a trap that deals damage and reduces enemy evasion"},
                {"name": "Opportunist", "type": "Passive", "description": "Gain increased damage against debuffed targets"}
            ],
            "minor_talents": [
                {"name": "Quick Fingers", "type": "Passive", "description": "Increase item use speed"},
                {"name": "Dirty Tricks", "type": "Skill", "description": "Reduce enemy accuracy"},
                {"name": "Scavenger", "type": "Passive", "description": "Chance to not consume items when used"}
            ]
        }
    },
    "Bulltribe": {
        "Tribal Might": {
            "main_stat": "STR",
            "secondary_stat": "VIT",
            "major_talents": [
                {"name": "Stampede", "type": "Skill", "description": "Deal heavy physical damage and push enemies back"},
                {"name": "War Cry", "type": "Skill", "description": "Intimidate enemies, reducing their attack"},
                {"name": "Tribal Fury", "type": "Passive", "description": "Gain increased damage at low health"}
            ],
            "minor_talents": [
                {"name": "Thick Hide", "type": "Passive", "description": "Increase physical resistance"},
                {"name": "Ground Slam", "type": "Skill", "description": "Deal AoE physical damage"},
                {"name": "Endurance", "type": "Passive", "description": "Reduce damage taken when below 50% HP"}
            ]
        }
    }
}

static var RACIAL_PATHS = {
    "Human": {
        "Leadership": {
            "main_stat": "WIS",
            "secondary_stat": "TEC",
            "major_talents": [
                "Commanding Presence",
                "Tactical Support",
                "Inspiring Rally"
            ]
        },
        "Adaptability": {
            "main_stat": "AGI",
            "secondary_stat": "VIT",
            "minor_talents": [
                "Quick Reflexes",
                "Colonizing People",
                "Improvised Tactics"
            ]
        }
    },
    "Ilf": {
        "Ilvish Grace": {
            "main_stat": "AGI",
            "secondary_stat": "STR",
            "major_talents": [
                "Ethereal Step",
                "Focused Strike",
                "Graceful Riposte"
            ]
        },
        "Ilvish Tradition": {
            "main_stat": "WIS",
            "secondary_stat": "INT",
            "minor_talents": [
                "Channel Nature's Power",
                "Piercing Shot",
                "Arcane Affinity"
            ]
        }
    },
    "Dwarf": {
        "Stoneborn Strength": {
            "main_stat": "STR",
            "secondary_stat": "VIT",
            "major_talents": [
                "Stone Skin",
                "Hammer Blow",
                "Unyielding Resolve"
            ]
        },
        "Dwarvish Lore": {
            "main_stat": "WIS",
            "secondary_stat": "TEC",
            "minor_talents": [
                "Master Craftsman",
                "Runed Hammer",
                "Runic Wisdom"
            ]
        }
    }
}

# Add to existing class paths
static var CLASS_PATHS = {
    "Magic Knight": {
        "Blade Magic": {
            "main_stat": "INT",
            "secondary_stat": "STR",
            "major_talents": [
                "Runic Slash", "Ethereal Arc", "Rune-Infused Blade", 
                "Mystic Blades", "Empowered Blade", "Arcane Surge",
                "Tempest Blades", "Storm of Swords"
            ]
        },
        "Magical Training": {
            "main_stat": "INT",
            "secondary_stat": "WIS",
            "minor_talents": [
                "Magic Adept", "Spellsword Fundamentals", "Fireball",
                "Smite", "Rune Blast", "Mana Infusion",
                "Runic Protection", "Magic Potency"
            ]
        },
        "Chivalric Code": {
            "main_stat": "STR",
            "secondary_stat": "VIT",
            "major_talents": [
                "Aegis of the Empire", "Shield of Valor", "Vow of Fortitude",
                "Bulwark Blade", "Vow of Retribution", "Radiant Shield",
                "Arcane Retribution", "Honorbound Will"
            ]
        },
        "Knightly Valor": {
            "main_stat": "STR",
            "secondary_stat": "VIT",
            "minor_talents": [
                "Combat Training", "Precision Strike", "Stoic Defense",
                "Deep Resolve", "Virtuous Blade"
            ]
        }
    },
    "Death Knight": {
        "Agent of Darkness": {
            "main_stat": "INT",
            "secondary_stat": "STR",
            "major_talents": [
                "Dark Sweep", "Drain Flurry", "Dark Sacrifice",
                "Hex Blade", "Forbidden Pose", "Dark Enchanted Blade",
                "Shadow Technique", "Twilight Laceration"
            ]
        },
        "Dark Arts": {
            "main_stat": "INT",
            "secondary_stat": "WIS",
            "minor_talents": [
                "Curse", "Doom", "Corrupted Blood", "Dark Beam",
                "Imbue Darkness", "Obscene Ritual", "Summon Skeleton",
                "Blackened Mark"
            ]
        },
        "Corrupted Code": {
            "main_stat": "INT",
            "secondary_stat": "STR",
            "major_talents": [
                "Doom Blade", "Cursed Blade", "Dark Strike",
                "Necrotic Armor", "Skeletal Onslaught", "Crimson Slash",
                "Summon Skeleton Champion", "Graveborn Vengeance"
            ]
        },
        "Necromancy": {
            "main_stat": "INT",
            "secondary_stat": "WIS",
            "minor_talents": [
                "Raise Skeleton", "Bone Shield", "Grave Aura",
                "Summon Skeletal Mage", "Unholy Presence"
            ]
        }
    },
    "Adventurer": {
        "Adventuring Skills": {
            "main_stat": "STR",
            "secondary_stat": "TEC",
            "major_talents": [
                "Trained Swordsman", "Cleave", "Parry",
                "Commanding Presence", "Tactical Genius", "Combat Veteran"
            ]
        },
        "Magical Whimsy": {
            "main_stat": "INT",
            "secondary_stat": "WIS",
            "minor_talents": [
                "Restoration", "Arcane Spark", "Fire Sprite",
                "Mystic Barrier", "Magic Adept", "Spellsword Fundamentals"
            ]
        }
    },
    "Wizard": {
        "Magical Training": {
            "main_stat": "INT",
            "secondary_stat": "WIS",
            "major_talents": [
                "Magic Adept", "Spellsword Fundamentals", "Fireball",
                "Smite", "Rune Blast", "Mana Infusion",
                "Runic Protection", "Magic Potency"
            ]
        },
        "Elemental Mastery": {  # Placeholder path
            "main_stat": "INT",
            "secondary_stat": "WIS",
            "major_talents": [
                "Elemental Surge", "Chain Lightning", "Glacial Spike",
                "Inferno", "Arcane Mastery", "Elemental Barrier",
                "Meteor Storm", "Elemental Convergence"
            ]
        },
        "Arcane Studies": {  # Placeholder path
            "main_stat": "INT",
            "secondary_stat": "TEC",
            "minor_talents": [
                "Spell Research", "Mana Efficiency", "Arcane Shield",
                "Counterspell", "Spell Penetration", "Arcane Brilliance"
            ]
        }
    }
}

func get_random_major_talent() -> SkillData:
    if major_talents.is_empty():
        return null
    return major_talents[randi() % major_talents.size()]

func get_random_minor_talent() -> SkillData:
    if minor_talents.is_empty():
        return null
    return minor_talents[randi() % minor_talents.size()]

static func get_paths_for_race(race_name: String) -> Array:
    var paths = []
    if RACIAL_PATHS.has(race_name):
        paths.append_array(RACIAL_PATHS[race_name].keys())
    if PLACEHOLDER_PATHS.has(race_name):
        paths.append_array(PLACEHOLDER_PATHS[race_name].keys())
    return paths 

# Update get_paths_for_class function
static func get_paths_for_class(class_name: String) -> Array:
    if CLASS_PATHS.has(class_name):
        return CLASS_PATHS[class_name].keys()
    return []

# Update existing get_path_data function to handle both race and class paths
static func get_path_data(path_name: String, source_name: String, is_class_path: bool = false) -> Dictionary:
    var paths = CLASS_PATHS if is_class_path else RACIAL_PATHS
    if paths.has(source_name) and paths[source_name].has(path_name):
        return paths[source_name][path_name]
    return {} 

# Example of a complete path definition
func _init():
    path_id = "example_path"
    major_talent_pool = ["major_talent_1", "major_talent_2", "major_talent_3"]
    minor_talent_pool = ["minor_talent_1", "minor_talent_2"]
    stat_distribution = {"STR": 5, "AGI": 5, "VIT": 5, "INT": 5, "WIS": 5, "TEC": 5} 