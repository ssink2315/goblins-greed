extends StatusEffect

func _init():
    effect_name = "Poison"
    description = "Taking poison damage each turn"
    effect_type = EffectType.DAMAGE
    duration = 4
    can_stack = true
    max_stacks = 5
    
    damage_per_turn = 3

func process_turn():
    if affected_unit:
        var poison_damage = damage_per_turn * stack_count
        # Poison ignores defense but is reduced by magic resistance
        var final_damage = poison_damage * (1.0 - (affected_unit.magic_res / 100.0))
        affected_unit.take_damage(int(final_damage), "magical", "nature")
    super.process_turn() 