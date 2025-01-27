extends Node2D

signal target_selected(target: Node)
signal selection_cancelled

var valid_targets: Array = []
var current_target: Node = null
var selector_sprite: Sprite2D

func _ready():
	selector_sprite = $SelectorSprite
	selector_sprite.hide()

func start_selection(targets: Array):
	valid_targets = targets
	if valid_targets.size() > 0:
		current_target = valid_targets[0]
		selector_sprite.show()
		update_selector_position()

func _input(event):
	if valid_targets.is_empty():
		return
		
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left"):
		cycle_target(1 if event.is_action_pressed("ui_right") else -1)
	
	elif event.is_action_pressed("ui_accept"):
		confirm_selection()
	
	elif event.is_action_pressed("ui_cancel"):
		cancel_selection()

func cycle_target(direction: int):
	var current_index = valid_targets.find(current_target)
	var new_index = (current_index + direction) % valid_targets.size()
	current_target = valid_targets[new_index]
	update_selector_position()

func update_selector_position():
	if current_target:
		selector_sprite.global_position = current_target.global_position + Vector2(0, -30)

func confirm_selection():
	selector_sprite.hide()
	target_selected.emit(current_target)
	valid_targets.clear()

func cancel_selection():
	selector_sprite.hide()
	selection_cancelled.emit()
	valid_targets.clear()
