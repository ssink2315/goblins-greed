extends Resource
class_name StatusEffect

enum EffectType {
    BUFF,      # Positive effects
    DEBUFF,    # Negative effects
    DAMAGE,    # Damage over time
    HEALING,   # Healing over time
    CONTROL    # Effects that limit actions
}

# Core Properties
@export var effect_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var effect_type: EffectType
@export var duration: int = 1
@export var can_stack: bool = false
@export var max_stacks: int = 1

# Effect Values
@export var stat_modifiers: Dictionary = {}  # Stat name -> value
@export var damage_per_turn: int = 0
@export var healing_per_turn: int = 0
@export var prevents_actions: bool = false

# New properties for percentage-based effects
@export var damage_percent: float = 0.0  # For % based damage
@export var damage_type: String = "magical"
@export var damage_element: int = 0

# Internal tracking
var current_duration: int
var stack_count: int = 1
var affected_unit: BaseCharacter

signal effect_applied(unit: BaseCharacter)
signal effect_removed(unit: BaseCharacter)
signal effect_tick(unit: BaseCharacter)

func _init():
    current_duration = duration

func apply(unit: BaseCharacter):
    affected_unit = unit
    
    # Apply stat modifiers
    for stat in stat_modifiers:
        if unit.get(stat) != null:
            unit.set(stat, unit.get(stat) + stat_modifiers[stat])
    
    unit.calculate_secondary_stats()
    effect_applied.emit(unit)

func remove(unit: BaseCharacter):
    # Remove stat modifiers
    for stat in stat_modifiers:
        if unit.get(stat) != null:
            unit.set(stat, unit.get(stat) - stat_modifiers[stat])
    
    unit.calculate_secondary_stats()
    effect_removed.emit(unit)

func process_turn():
    if not affected_unit:
        return
        
    if damage_per_turn > 0:
        affected_unit.take_damage(damage_per_turn, damage_type, "effect")
    
    if damage_percent > 0:
        var percent_damage = ceil(affected_unit.max_hp * (damage_percent / 100.0))
        affected_unit.take_damage(percent_damage, damage_type, "effect", damage_element)
    
    if healing_per_turn > 0:
        affected_unit.heal(healing_per_turn)
    
    current_duration -= 1
    effect_tick.emit(affected_unit)

func is_finished() -> bool:
    return current_duration <= 0

func get_remaining_duration() -> int:
    return current_duration

func can_be_applied_to(unit: BaseCharacter) -> bool:
    # Check if unit already has this effect
    var existing_effect = unit.statuses.get(effect_name)
    if existing_effect:
        return can_stack and existing_effect.stack_count < max_stacks
    return true

func add_stack() -> void:
    if can_stack and stack_count < max_stacks:
        stack_count += 1
        # Reapply stat modifiers for the new stack
        for stat in stat_modifiers:
            if affected_unit.get(stat) != null:
                affected_unit.set(stat, affected_unit.get(stat) + stat_modifiers[stat])
        affected_unit.calculate_secondary_stats()

func remove_stack() -> void:
    if stack_count > 1:
        stack_count -= 1
        # Remove stat modifiers for one stack
        for stat in stat_modifiers:
            if affected_unit.get(stat) != null:
                affected_unit.set(stat, affected_unit.get(stat) - stat_modifiers[stat])
        affected_unit.calculate_secondary_stats()

func get_display_text() -> String:
    var text = "[b]%s[/b]\n%s" % [effect_name, description]
    if current_duration > 0:
        text += "\nDuration: %d turns" % current_duration
    if stack_count > 1:
        text += "\nStacks: %d/%d" % [stack_count, max_stacks]
    return text

func duplicate() -> StatusEffect:
    var new_effect = super.duplicate()
    new_effect.current_duration = duration
    new_effect.stack_count = 1
    new_effect.affected_unit = null
    return new_effect

func should_tick_this_turn() -> bool:
    return damage_per_turn > 0

func is_expired() -> bool:
    return duration <= 0

func can_be_applied_to(target: BaseCharacter) -> bool:
    return true  # Override in specific effects 