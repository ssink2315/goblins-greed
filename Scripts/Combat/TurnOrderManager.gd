extends Node

signal turn_order_updated(new_order: Array)

var current_order: Array = []
var current_index: int = 0
var speed_variance: float = 0.1  # 10% random variance in speed

func initialize_turn_order(units: Array):
    current_order.clear()
    current_order = units.duplicate()
    _sort_by_speed()
    current_index = 0
    turn_order_updated.emit(current_order)

func add_unit(unit: BaseCharacter):
    current_order.append(unit)
    _sort_by_speed()
    turn_order_updated.emit(current_order)

func remove_unit(unit: BaseCharacter):
    var unit_index = current_order.find(unit)
    if unit_index != -1:
        current_order.erase(unit)
        if unit_index < current_index:
            current_index -= 1
        turn_order_updated.emit(current_order)

func get_next_unit() -> BaseCharacter:
    if current_order.is_empty():
        return null
        
    var next_unit = current_order[current_index]
    current_index = (current_index + 1) % current_order.size()
    
    # If we're back at the start, recalculate order
    if current_index == 0:
        _sort_by_speed()
        turn_order_updated.emit(current_order)
    
    return next_unit

func _sort_by_speed():
    # Add variance to prevent same-speed units always going in the same order
    var speed_scores = {}
    for unit in current_order:
        var variance = randf_range(-speed_variance, speed_variance)
        speed_scores[unit] = unit.stats.speed * (1.0 + variance)
    
    current_order.sort_custom(func(a, b): 
        return speed_scores[a] > speed_scores[b]
    )

# Special handling for summons
func _adjust_summon_priority(summoner: BaseCharacter, summon: BaseCharacter):
    var summoner_index = current_order.find(summoner)
    if summoner_index == -1:
        return
        
    # Ensure summon acts immediately after its summoner
    current_order.erase(summon)
    current_order.insert(summoner_index + 1, summon)
    turn_order_updated.emit(current_order) 