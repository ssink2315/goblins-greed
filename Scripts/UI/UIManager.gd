extends Node

signal ui_shown(ui_name: String)
signal ui_hidden(ui_name: String)

const TRANSITION_TIME = 0.2
const UI_THEME = preload("res://Resources/Themes/default_theme.tres")

# Track active UIs
var active_uis: Dictionary = {}

@onready var theme_manager = $ThemeManager

func _ready():
    theme_manager.apply_theme_to_root()

func show_ui(ui_scene: PackedScene, data: Dictionary = {}) -> Control:
    var ui = ui_scene.instantiate()
    get_tree().root.add_child(ui)
    
    # Ensure theme is applied
    if !ui.theme:
        ui.theme = theme_manager.DEFAULT_THEME
    
    if ui.has_method("initialize"):
        ui.initialize(data)
    
    active_uis[ui.name] = ui
    show_with_transition(ui)
    ui_shown.emit(ui.name)
    return ui

func hide_ui(ui: Control):
    if !is_instance_valid(ui):
        return
        
    hide_with_transition(ui, func():
        active_uis.erase(ui.name)
        ui.queue_free()
        ui_hidden.emit(ui.name)
    )

func show_with_transition(ui: Control):
    ui.modulate = Color.TRANSPARENT
    ui.show()
    create_tween().tween_property(ui, "modulate", Color.WHITE, TRANSITION_TIME)

func hide_with_transition(ui: Control, on_complete: Callable = Callable()):
    var tween = create_tween()
    tween.tween_property(ui, "modulate", Color.TRANSPARENT, TRANSITION_TIME)
    if !on_complete.is_null():
        tween.tween_callback(on_complete) 