extends StatusEffect

func _init():
    effect_name = "Burn"
    description = "Taking fire damage each turn and dealing less physical damage"
    effect_type = EffectType.DEBUFF
    duration = 3
    can_stack = true
    max_stacks = 3
    
    damage_per_turn = 5
    stat_modifiers = {
        "phys_dmg_mod": -10.0  # -10% physical damage
    }

func process_turn() -> void:
    if affected_unit:
        var burn_damage = damage_per_turn * stack_count
        affected_unit.take_damage(burn_damage, "magical", "fire")
    super.process_turn() 