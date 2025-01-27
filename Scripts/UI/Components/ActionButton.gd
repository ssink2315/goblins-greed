extends Button

signal action_hovered(action_data: Dictionary)
signal action_hover_ended

@export var icon: Texture2D
@export var cooldown_enabled: bool = false
@export var show_keybind: bool = true

@onready var icon_texture = $HBoxContainer/Icon
@onready var label = $HBoxContainer/Label
@onready var keybind = $KeybindLabel
@onready var cooldown_overlay = $CooldownOverlay
@onready var cooldown_label = $CooldownOverlay/Label

var action_data: Dictionary

func _ready():
    custom_minimum_size.y = UITheme.SIZES.button_height
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    
    if icon:
        icon_texture.texture = icon
    
    if !show_keybind:
        keybind.hide()

func setup(data: Dictionary):
    action_data = data
    text = data.name
    if data.has("icon"):
        icon_texture.texture = data.icon
    if data.has("keybind") and show_keybind:
        keybind.text = data.keybind

func set_cooldown(time_left: float):
    if !cooldown_enabled:
        return
        
    if time_left > 0:
        cooldown_overlay.show()
        cooldown_label.text = str(ceil(time_left))
        cooldown_overlay.material.set_shader_parameter("progress", time_left)
    else:
        cooldown_overlay.hide()

func _on_mouse_entered():
    action_hovered.emit(action_data)

func _on_mouse_exited():
    action_hover_ended.emit() 