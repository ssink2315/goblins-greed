extends Node2D

@onready var label = $Label

func display(text: String, color: Color = Color.WHITE):
	label.text = text
	label.modulate = color
	
	# Create tween for floating animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "position:y", position.y - 50, 1.0)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
