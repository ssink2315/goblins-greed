extends BaseCharacter
class_name EnemyCharacter

@export var challenge_level: int = 1
@export var base_exp: int = 100
@export var base_gold: int = 50
@export var loot_table: LootTable

var preferred_row: int = CombatEnums.Row.FRONT
var aggression: float = 0.7  # Higher values mean more likely to attack vs defend
var skill_use_chance: float = 0.3
var targeting_weights = {
    "lowest_hp": 0.7,
    "highest_threat": 0.2,
    "random": 0.1
}

func _init():
    character_type = "enemy"

func choose_action() -> Dictionary:
    # Check if should use skill
    if randf() < skill_use_chance and has_usable_skills():
        var skill = _choose_skill()
        if skill.skill_index != -1:
            return {
                "type": CombatEnums.ActionType.SKILL,
                "skill_index": skill.skill_index,
                "target": null  # Will be selected by AI
            }
    
    # Decide between attack and defend
    if randf() < aggression and current_hp > max_hp * 0.3:
        return {
            "type": CombatEnums.ActionType.ATTACK,
            "target": null  # Will be selected by AI
        }
    else:
        return {
            "type": CombatEnums.ActionType.DEFEND
        }

func _choose_skill() -> Dictionary:
    var usable_skills = []
    
    for i in range(skills.size()):
        var skill = skills[i]
        if current_mana >= skill.mana_cost:
            usable_skills.append({"index": i, "skill": skill})
    
    if usable_skills.is_empty():
        return {"skill_index": -1, "skill": null}
    
    # Sort by priority/power
    usable_skills.sort_custom(func(a, b): 
        return a.skill.priority > b.skill.priority
    )
    
    return {
        "skill_index": usable_skills[0].index,
        "skill": usable_skills[0].skill
    }

func has_usable_skills() -> bool:
    return skills.any(func(skill): return current_mana >= skill.mana_cost)

func set_preferred_row(row: int):
    preferred_row = row

func set_aggression(value: float):
    aggression = clamp(value, 0.0, 1.0)

func set_skill_use_chance(value: float):
    skill_use_chance = clamp(value, 0.0, 1.0)

func set_targeting_weights(weights: Dictionary):
    targeting_weights = weights.duplicate() 