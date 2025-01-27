extends Node

signal action_resolved(result: Dictionary)

enum ActionResult {
    SUCCESS,
    FAILED,
    MISSED,
    BLOCKED,
    CRITICAL
}

func resolve_action(action: Dictionary) -> Dictionary:
    var result = {}
    
    match action.type:
        "attack":
            result = _resolve_attack(action)
        "skill":
            result = _resolve_skill(action)
        "item":
            result = _resolve_item(action)
        "defend":
            result = _resolve_defend(action)
    
    action_resolved.emit(result)
    return result

func _resolve_attack(action: Dictionary) -> Dictionary:
    var attacker = action.source
    var target = action.target
    var combat_calc = get_node("../CombatCalculator")
    
    # Check if attack hits
    if !combat_calc.roll_hit_chance(attacker, target):
        return {
            "type": "damage",
            "amount": 0,
            "result": ActionResult.MISSED,
            "source": attacker,
            "target": target
        }
    
    # Calculate damage
    var damage = combat_calc.calculate_damage(attacker, target)
    var is_critical = combat_calc.was_critical
    
    return {
        "type": "damage",
        "amount": damage,
        "result": ActionResult.CRITICAL if is_critical else ActionResult.SUCCESS,
        "source": attacker,
        "target": target,
        "is_critical": is_critical
    }

func _resolve_skill(action: Dictionary) -> Dictionary:
    var user = action.source
    var target = action.target
    var skill = action.skill
    
    # Check MP cost
    if user.current_mp < skill.mp_cost:
        return {
            "type": "skill",
            "result": ActionResult.FAILED,
            "source": user,
            "target": target,
            "skill_name": skill.name,
            "reason": "Not enough MP"
        }
    
    # Spend MP
    user.spend_mp(skill.mp_cost)
    
    # Apply skill effects
    var effect_results = skill.apply_effects(user, target)
    
    return {
        "type": "skill",
        "result": ActionResult.SUCCESS,
        "source": user,
        "target": target,
        "skill_name": skill.name,
        "effects": effect_results
    }

func _resolve_item(action: Dictionary) -> Dictionary:
    var user = action.source
    var target = action.target
    var item = action.item
    
    if !item.can_be_used(user, target):
        return {
            "type": "item",
            "result": ActionResult.FAILED,
            "source": user,
            "target": target,
            "item_name": item.name,
            "reason": "Cannot use item"
        }
    
    var effect_results = item.apply_effects(target)
    item.consume()
    
    return {
        "type": "item",
        "result": ActionResult.SUCCESS,
        "source": user,
        "target": target,
        "item_name": item.name,
        "effects": effect_results
    }

func _resolve_defend(action: Dictionary) -> Dictionary:
    var unit = action.source
    unit.defend()
    
    return {
        "type": "defend",
        "result": ActionResult.SUCCESS,
        "source": unit,
        "target": unit
    }

func resolve_summon(action: Dictionary) -> Dictionary:
    var result = {}
    var summoner = action.source
    var skill = action.skill
    
    # Check if summoner can still summon
    if not summoner.is_alive():
        return {
            "success": false,
            "message": "Summoner is defeated"
        }
    
    # Check summon limit
    var side = combat_manager.get_unit_side(summoner)
    if not combat_manager.can_add_summon(side):
        return {
            "success": false,
            "message": "Maximum number of units reached"
        }
    
    for effect in skill.effects:
        if effect.type == "summon":
            var summon_data = GameDatabase.get_summon_data(effect.summon_type)
            if not summon_data:
                return {
                    "success": false,
                    "message": "Invalid summon type"
                }
            
            # Apply any modifiers from summoner
            _apply_summoner_modifiers(summoner, summon_data)
            
            var summon = combat_manager.add_summon(summoner, summon_data)
            if summon:
                # Handle any on-summon effects
                _process_on_summon_effects(summoner, summon, effect)
                
                return {
                    "success": true,
                    "summon": summon,
                    "message": "%s summoned %s!" % [summoner.character_name, summon.character_name]
                }
    
    return {
        "success": false,
        "message": "No valid summon effect found"
    }

func _apply_summoner_modifiers(summoner: BaseCharacter, summon_data: Dictionary):
    # Apply any summoner traits or effects that modify summons
    if summoner.has_trait("Improved Summons"):
        summon_data.stats.hp *= 1.2
        summon_data.stats.attack *= 1.1
    
    # Apply any active effects that boost summons
    for effect in summoner.get_active_effects():
        if effect.affects_summons:
            _apply_effect_to_summon(effect, summon_data)

func _process_on_summon_effects(summoner: BaseCharacter, summon: BaseCharacter, effect: Dictionary):
    # Handle any additional effects that trigger on summon
    if effect.has("on_summon_effects"):
        for sub_effect in effect.on_summon_effects:
            match sub_effect.type:
                "buff":
                    apply_buff(summon, sub_effect)
                "link":
                    create_summon_link(summoner, summon, sub_effect)
                # Add other effect types as needed 