extends PanelContainer

signal character_clicked(character: BaseCharacter)
signal character_right_clicked(character: BaseCharacter)
signal character_hovered(character: BaseCharacter)
signal character_hover_ended

@onready var portrait = $MarginContainer/Portrait
@onready var name_label = $NameLabel
@onready var level_label = $LevelLabel
@onready var hp_bar = $HPBar
@onready var mp_bar = $MPBar
@onready var status_icons = $StatusIcons
@onready var highlight = $Highlight

var current_character: BaseCharacter

func _ready():
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func set_character(character: BaseCharacter):
    current_character = character
    if character:
        portrait.texture = character.portrait
        name_label.text = character.character_name
        level_label.text = "Lv. " + str(character.level)
        _update_bars()
        _update_status()
    else:
        portrait.texture = null
        name_label.text = ""
        level_label.text = ""
        hp_bar.value = 0
        mp_bar.value = 0

func _update_bars():
    hp_bar.max_value = current_character.max_hp
    hp_bar.value = current_character.current_hp
    mp_bar.max_value = current_character.max_mp
    mp_bar.value = current_character.current_mp

func _update_status():
    for icon in status_icons.get_children():
        icon.queue_free()
    
    for status in current_character.status_effects:
        var icon = TextureRect.new()
        icon.texture = status.icon
        icon.custom_minimum_size = Vector2(16, 16)
        icon.tooltip_text = status.name
        status_icons.add_child(icon)

func _gui_input(event: InputEvent):
    if !current_character:
        return
        
    if event is InputEventMouseButton and event.pressed:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                character_clicked.emit(current_character)
            MOUSE_BUTTON_RIGHT:
                character_right_clicked.emit(current_character)

func _on_mouse_entered():
    if current_character:
        highlight.show()
        character_hovered.emit(current_character)

func _on_mouse_exited():
    highlight.hide()
    character_hover_ended.emit() 