extends HBoxContainer

var turn_icon_scene = preload("res://Scenes/Combat/TurnIcon.tscn")
var current_icons: Array[Control] = []

func update_turn_order(units: Array):
    clear_icons()
    
    for i in range(units.size()):
        var unit = units[i]
        var icon = turn_icon_scene.instantiate()
        add_child(icon)
        icon.setup(unit)
        current_icons.append(icon)
        
        if i == 0:  # Current unit's turn
            icon.set_highlighted(true)

func highlight_active_unit(index: int):
    for i in range(current_icons.size()):
        current_icons[i].set_highlighted(i == index)

func clear_icons():
    for icon in current_icons:
        icon.queue_free()
    current_icons.clear() 