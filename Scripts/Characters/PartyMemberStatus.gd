extends PanelContainer

@onready var name_label = $VBoxContainer/NameLabel
@onready var hp_bar = $VBoxContainer/HPBar
@onready var mp_bar = $VBoxContainer/MPBar
@onready var status_icons = $VBoxContainer/StatusIcons

var character: BaseCharacter

func initialize(char: BaseCharacter):
	character = char
	_connect_signals()
	refresh_display()

func _connect_signals():
	character.hp_changed.connect(_update_hp)
	character.mp_changed.connect(_update_mp)
	character.status_changed.connect(_update_status)

func refresh_display():
	name_label.text = character.character_name
	_update_hp()
	_update_mp()
	_update_status()

func _update_hp():
	hp_bar.value = (float(character.current_hp) / character.max_hp) * 100
	hp_bar.tooltip_text = "%d/%d HP" % [character.current_hp, character.max_hp]

func _update_mp():
	mp_bar.value = (float(character.current_mana) / character.max_mana) * 100
	mp_bar.tooltip_text = "%d/%d MP" % [character.current_mana, character.max_mana]

func _update_status():
	# Clear existing status icons
	for child in status_icons.get_children():
		child.queue_free()
	
	# Add icons for each active status effect
	for status in character.get_active_status_effects():
		var icon = TextureRect.new()
		icon.texture = load("res://Assets/UI/StatusIcons/" + status.icon_path)
		icon.custom_minimum_size = Vector2(24, 24)
		icon.tooltip_text = status.name
		status_icons.add_child(icon)
