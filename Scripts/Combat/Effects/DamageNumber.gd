extends Control

var value: int = 0
var color: Color = Color.WHITE
var duration: float = 1.0
var rise_height: float = -50.0
var spread: float = 20.0

func _ready():
    modulate.a = 0.0

func play():
    $Label.text = str(value)
    $Label.modulate = color
    
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Fade in
    tween.tween_property(self, "modulate:a", 1.0, 0.1)
    
    # Rise up and spread
    var rand_x = randf_range(-spread, spread)
    tween.tween_property(self, "position:y", position.y + rise_height, duration).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "position:x", position.x + rand_x, duration).set_ease(Tween.EASE_OUT)
    
    # Fade out
    tween.tween_property(self, "modulate:a", 0.0, 0.2).set_delay(duration - 0.2)
    
    await tween.finished
    queue_free() 