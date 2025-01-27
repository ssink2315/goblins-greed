extends Node

enum SummonBehavior { AGGRESSIVE, PROTECTIVE, SUPPORTIVE }

var combat_manager: Node
var calculator: Node

func _ready():
    combat_manager = get_parent()
    calculator = combat_manager.get_node("CombatCalculator")

func get_summon_action(summon: BaseCharacter) -> Dictionary:
    if not summon.is_alive():
        return {}
        
    var summoner = combat_manager.summons[summon]
    if not summoner or not summoner.is_alive():
        combat_manager.remove_summon(summon)
        return {}
    
    var behavior = _determine_behavior(summon)
    match behavior:
        SummonBehavior.PROTECTIVE:
            return _get_protective_action(summon, summoner)
        SummonBehavior.SUPPORTIVE:
            return _get_supportive_action(summon)
        _: # AGGRESSIVE or default
            return _get_aggressive_action(summon)

func _determine_behavior(summon: BaseCharacter) -> int:
    var base_behavior = summon.summon_data.get("behavior", SummonBehavior.AGGRESSIVE)
    var summoner = combat_manager.summons[summon]
    
    # Prioritize protecting dying summoner
    if summoner and summoner.current_hp < summoner.max_hp * 0.3:
        return SummonBehavior.PROTECTIVE
    
    # Switch to support if allies need healing/buffs
    if _allies_need_support(summon) and summon.has_support_skills():
        return SummonBehavior.SUPPORTIVE
        
    return base_behavior

func _get_aggressive_action(summon: BaseCharacter) -> Dictionary:
    var enemies = combat_manager.get_enemies_of(summon)
    if enemies.is_empty():
        return {}
        
    # Prioritize targets
    enemies.sort_custom(func(a, b): 
        return calculator.calculate_basic_damage(summon, a) > calculator.calculate_basic_damage(summon, b)
    )
    
    # Use skills if available
    if summon.learned_skills.size() > 0 and summon.current_mp > 0:
        var best_skill = _get_best_offensive_skill(summon, enemies[0])
        if best_skill:
            return {
                "type": "skill",
                "skill": best_skill,
                "target": enemies[0]
            }
    
    # Default to basic attack
    return {
        "type": "attack",
        "target": enemies[0]
    }

func _get_protective_action(summon: BaseCharacter, protect_target: BaseCharacter) -> Dictionary:
    # Check for defensive skills first
    if summon.has_defensive_skills():
        var best_defensive_skill = _get_best_defensive_skill(summon)
        if best_defensive_skill:
            return {
                "type": "skill",
                "skill": best_defensive_skill,
                "target": protect_target
            }
    
    # If no defensive skills, attack the biggest threat
    var threats = _get_threats_to_target(protect_target)
    if not threats.is_empty():
        return {
            "type": "attack",
            "target": threats[0]
        }
    
    return _get_aggressive_action(summon)

func _get_threats_to_target(target: BaseCharacter) -> Array:
    var enemies = combat_manager.get_enemies_of(target)
    enemies.sort_custom(func(a, b): 
        return calculator.calculate_threat_level(a, target) > calculator.calculate_threat_level(b, target)
    )
    return enemies

func _get_supportive_action(summon: BaseCharacter) -> Dictionary:
    var allies = combat_manager.get_allies_of(summon)
    
    # Check for healing abilities
    if summon.has_healing_skills():
        var wounded_ally = _find_most_wounded_ally(allies)
        if wounded_ally:
            var heal_skill = _get_best_healing_skill(summon)
            return {
                "type": "skill",
                "skill": heal_skill,
                "target": wounded_ally
            }
    
    # Check for buff abilities
    if summon.has_buff_skills():
        var buff_target = _find_best_buff_target(allies)
        if buff_target:
            var buff_skill = _get_best_buff_skill(summon)
            return {
                "type": "skill",
                "skill": buff_skill,
                "target": buff_target
            }
    
    # Default to aggressive behavior if no support needed
    return _get_aggressive_action(summon)

# Helper functions
func _allies_need_support(summon: BaseCharacter) -> bool:
    var allies = combat_manager.get_allies_of(summon)
    return allies.any(func(ally): return ally.current_hp < ally.max_hp * 0.5)

func _find_most_threatening_enemy(enemies: Array, protect_target: BaseCharacter) -> BaseCharacter:
    var max_threat = 0
    var most_threatening = enemies[0] if enemies.size() > 0 else null
    
    for enemy in enemies:
        var threat = calculator.calculate_basic_damage(enemy, protect_target)
        if threat > max_threat:
            max_threat = threat
            most_threatening = enemy
    
    return most_threatening

func _get_best_offensive_skill(summon: BaseCharacter, target: BaseCharacter) -> Skill:
    var usable_skills = summon.learned_skills.filter(func(s): 
        return s.is_offensive and s.mp_cost <= summon.current_mp and !summon.is_skill_on_cooldown(s)
    )
    
    if usable_skills.is_empty():
        return null
        
    # Sort by estimated damage
    usable_skills.sort_custom(func(a, b):
        return calculator.calculate_skill_damage(a, summon, target) > calculator.calculate_skill_damage(b, summon, target)
    )
    
    return usable_skills[0]

func _is_in_range(unit1: BaseCharacter, unit2: BaseCharacter) -> bool:
    return unit1.global_position.distance_to(unit2.global_position) < 150.0

func has_support_skills() -> bool:
    return not get_support_skills().is_empty()

func get_support_skills() -> Array:
    return learned_skills.filter(func(skill): 
        return skill.is_support or skill.is_healing
    ) 