extends Node

signal transition_started(from_scene: String, to_scene: String)
signal transition_completed(new_scene: String)

const TRANSITION_DURATION := 0.5

@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_transitioning: bool = false
var queued_scene: String = ""

func _ready():
    _setup_animations()
    transition_overlay.visible = false

func _setup_animations():
    # Create animation library
    var library = AnimationLibrary.new()
    
    # Fade animations
    library.add_animation("fade_out", _create_fade_out_animation())
    library.add_animation("fade_in", _create_fade_in_animation())
    
    # Slide animations
    library.add_animation("slide_out", _create_slide_out_animation())
    library.add_animation("slide_in", _create_slide_in_animation())
    
    # Add library to animation player
    animation_player.add_animation_library("transitions", library)

func _create_fade_out_animation() -> Animation:
    var animation = Animation.new()
    var track_index = animation.add_track(Animation.TYPE_VALUE)
    
    animation.track_set_path(track_index, "TransitionOverlay:modulate:a")
    animation.track_insert_key(track_index, 0.0, 0.0)
    animation.track_insert_key(track_index, TRANSITION_DURATION, 1.0)
    animation.length = TRANSITION_DURATION
    
    return animation

func _create_fade_in_animation() -> Animation:
    var animation = Animation.new()
    var track_index = animation.add_track(Animation.TYPE_VALUE)
    
    animation.track_set_path(track_index, "TransitionOverlay:modulate:a")
    animation.track_insert_key(track_index, 0.0, 1.0)
    animation.track_insert_key(track_index, TRANSITION_DURATION, 0.0)
    animation.length = TRANSITION_DURATION
    
    return animation

func _create_slide_out_animation() -> Animation:
    var animation = Animation.new()
    var track_index = animation.add_track(Animation.TYPE_VALUE)
    
    animation.track_set_path(track_index, "TransitionOverlay:position:x")
    animation.track_insert_key(track_index, 0.0, -get_viewport().size.x)
    animation.track_insert_key(track_index, TRANSITION_DURATION, 0.0)
    animation.length = TRANSITION_DURATION
    
    return animation

func _create_slide_in_animation() -> Animation:
    var animation = Animation.new()
    var track_index = animation.add_track(Animation.TYPE_VALUE)
    
    animation.track_set_path(track_index, "TransitionOverlay:position:x")
    animation.track_insert_key(track_index, 0.0, 0.0)
    animation.track_insert_key(track_index, TRANSITION_DURATION, get_viewport().size.x)
    animation.length = TRANSITION_DURATION
    
    return animation

func transition_to_scene(scene_path: String, transition_type: String = "fade"):
    if is_transitioning:
        return
        
    is_transitioning = true
    queued_scene = scene_path
    
    match transition_type:
        "fade":
            _fade_transition()
        "slide":
            _slide_transition()
        "dissolve":
            _dissolve_transition()
        _:
            push_error("Unknown transition type: %s" % transition_type)

func _fade_transition():
    animation_player.play("fade_out")
    await animation_player.animation_finished
    _change_scene()
    animation_player.play("fade_in")
    await animation_player.animation_finished
    _finish_transition()

func _slide_transition():
    animation_player.play("slide_out")
    await animation_player.animation_finished
    _change_scene()
    animation_player.play("slide_in")
    await animation_player.animation_finished
    _finish_transition()

func _dissolve_transition():
    animation_player.play("dissolve_out")
    await animation_player.animation_finished
    _change_scene()
    animation_player.play("dissolve_in")
    await animation_player.animation_finished
    _finish_transition()

func _change_scene():
    var game_manager = get_node("/root/GameManager")
    var current_scene = game_manager.current_scene
    
    if current_scene:
        if current_scene.has_method("cleanup"):
            current_scene.cleanup()
        current_scene.queue_free()
    
    var new_scene = load(queued_scene).instantiate()
    game_manager.add_child(new_scene)
    game_manager.current_scene = new_scene
    
    transition_completed.emit(queued_scene)

func _finish_transition():
    is_transitioning = false
    queued_scene = ""

# Add helper function for scene-specific transitions
func get_transition_type_for_scene(from_scene: String, to_scene: String) -> String:
    # Combat transitions
    if to_scene.contains("CombatScene"):
        return "slide"
    # Menu transitions
    elif to_scene.contains("Menu"):
        return "fade"
    # Default transition
    return "fade" 