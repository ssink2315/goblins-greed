extends StatusEffect

func _init():
    effect_name = "Stun"
    description = "Unable to act for one turn"
    effect_type = EffectType.CONTROL
    duration = 1
    can_stack = false
    prevents_actions = true

func can_be_applied_to(unit: BaseCharacter) -> bool:
    # Check stun immunity or resistance
    if unit.debuff_res >= 75:  # 75% or higher debuff resistance prevents stun
        return false
    return super.can_be_applied_to(unit) 