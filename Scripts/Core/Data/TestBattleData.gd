extends Node

# Basic enemy templates
const ENEMY_TEMPLATES = {
    "GOBLIN": {
        "name": "Goblin",
        "stats": {
            "STR": 8,
            "VIT": 6,
            "AGI": 8,
            "INT": 4,
            "WIS": 4,
            "TEC": 10
        },
        "skills": ["slash", "defend"],
        "ai_strategy": "AGGRESSIVE"
    },
    "SLIME": {
        "name": "Slime",
        "stats": {
            "STR": 8,
            "VIT": 8,
            "AGI": 8,
            "INT": 4,
            "WIS": 4,
            "TEC": 8
        },
        "skills": ["bounce", "split"],
        "ai_strategy": "DEFENSIVE"
    },
    "HEALER_FAIRY": {
        "name": "Healer Fairy",
        "stats": {
            "STR": 4,
            "VIT": 6,
            "AGI": 4,
            "INT": 8,
            "WIS": 8,
            "TEC": 4
        },
        "skills": ["heal", "buff"],
        "ai_strategy": "SUPPORT"
    },
    "GOBLIN_WARRIOR": {
        "name": "Goblin Warrior",
        "stats": {
            "STR": 12,
            "VIT": 10,
            "AGI": 8,
            "INT": 4,
            "WIS": 4,
            "TEC": 10
        },
        "skills": ["slash", "defend", "power_strike"],
        "ai_strategy": "AGGRESSIVE"
    },
    "GOBLIN_SHAMAN": {
        "name": "Goblin Shaman",
        "stats": {
            "STR": 6,
            "VIT": 6,
            "AGI": 7,
            "INT": 12,
            "WIS": 10,
            "TEC": 10
        },
        "skills": ["fire_bolt", "heal", "magic_shield"],
        "ai_strategy": "SUPPORT"
    }
}

# Test battle configurations
const TEST_BATTLES = {
    "TUTORIAL": {
        "name": "Tutorial Battle",
        "description": "A simple battle to learn the basics",
        "enemies": [
            {"template": "GOBLIN", "level": 1}
        ],
        "background": "forest",
        "rewards": {
            "exp": 50,
            "gold": 100,
            "items": ["potion"]
        }
    },
    "MIXED_GROUP": {
        "name": "Mixed Enemy Group",
        "description": "Battle against different enemy types",
        "enemies": [
            {"template": "GOBLIN", "level": 2},
            {"template": "SLIME", "level": 2},
            {"template": "HEALER_FAIRY", "level": 2}
        ],
        "background": "cave",
        "rewards": {
            "exp": 150,
            "gold": 300,
            "items": ["potion", "ether"]
        }
    },
    "BOSS_TEST": {
        "name": "Mini-Boss Battle",
        "description": "A challenging battle against stronger enemies",
        "enemies": [
            {"template": "GOBLIN", "level": 3, "is_boss": true},
            {"template": "HEALER_FAIRY", "level": 2},
            {"template": "HEALER_FAIRY", "level": 2}
        ],
        "background": "castle",
        "rewards": {
            "exp": 300,
            "gold": 500,
            "items": ["potion", "ether", "elixir"]
        }
    }
}

# Helper function to create enemy from template
func create_enemy(template_name: String, level: int = 1) -> BaseCharacter:
    if not ENEMY_TEMPLATES.has(template_name):
        push_error("Enemy template not found: " + template_name)
        return null
        
    var template = ENEMY_TEMPLATES[template_name]
    var enemy = BaseCharacter.new()
    
    # Set basic properties
    enemy.character_name = template.name
    enemy.level = level
    
    # Apply stats with level scaling
    for stat in template.stats:
        var base_value = template.stats[stat]
        enemy.stats[stat] = base_value + (base_value * 0.1 * (level - 1))
    
    # Add skills
    for skill_id in template.skills:
        var skill = GameDatabase.get_skill(skill_id)
        if skill:
            enemy.learned_skills.append(skill)
    
    # Set AI strategy
    enemy.ai_strategy = template.ai_strategy
    
    return enemy

# Helper function to start a test battle
func start_test_battle(battle_id: String):
    if not TEST_BATTLES.has(battle_id):
        push_error("Test battle not found: " + battle_id)
        return
        
    var battle = TEST_BATTLES[battle_id]
    var enemies = []
    
    for enemy_data in battle.enemies:
        var enemy = create_enemy(enemy_data.template, enemy_data.level)
        if enemy:
            if enemy_data.get("is_boss", false):
                enemy.is_boss = true
            enemies.append(enemy)
    
    var game_manager = get_node("/root/GameManager")
    game_manager.start_combat(enemies)

func start_new_game(player: PlayerCharacter):
    if player == null:
        push_error("Cannot start a new game without a valid player character.")
        return
    current_player = player
    party_manager.add_character(player)
    ... 