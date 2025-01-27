extends Control

signal character_created(character: PlayerCharacter)

@onready var race_list: ItemList = $MarginContainer/VBoxContainer/HBoxContainer/RaceSelection/RaceList
@onready var race_description: RichTextLabel = $MarginContainer/VBoxContainer/HBoxContainer/RaceSelection/RaceDescription
@onready var class_list: ItemList = $MarginContainer/VBoxContainer/HBoxContainer/ClassSelection/ClassList
@onready var class_description: RichTextLabel = $MarginContainer/VBoxContainer/HBoxContainer/ClassSelection/ClassDescription
@onready var name_input: LineEdit = $MarginContainer/VBoxContainer/NameInput
@onready var create_button: Button = $MarginContainer/VBoxContainer/CreateButton
@onready var error_label: Label = $MarginContainer/VBoxContainer/ErrorLabel

var selected_race: String = ""
var selected_class: String = ""

func _ready():
	_populate_lists()
	_connect_signals()
	error_label.hide()
	create_button.disabled = true

func _populate_lists():
	# Populate race list
	for race in GameDatabase.races.keys():
		race_list.add_item(race)
	
	# Populate class list
	for class_title in GameDatabase.classes.keys():
		class_list.add_item(class_title)

func _connect_signals():
	race_list.item_selected.connect(_on_race_selected)
	class_list.item_selected.connect(_on_class_selected)
	name_input.text_changed.connect(_on_name_changed)
	create_button.pressed.connect(_on_create_pressed)

func _on_race_selected(index: int):
	selected_race = race_list.get_item_text(index)
	var race_data = GameDatabase.races[selected_race]
	race_description.text = race_data.description
	_validate_creation()

func _on_class_selected(index: int):
	selected_class = class_list.get_item_text(index)
	var class_data = GameDatabase.classes[selected_class]
	class_description.text = class_data.description
	_validate_creation()

func _on_name_changed(new_text: String):
	_validate_creation()

func _validate_creation() -> bool:
	var valid = selected_race != "" and selected_class != "" and name_input.text.strip_edges() != ""
	create_button.disabled = !valid
	return valid

func _on_create_pressed():
	if !_validate_creation():
		error_label.text = "Please fill in all fields"
		error_label.show()
		return
	
	var character = PlayerCharacter.new()
	character.initialize(
		name_input.text.strip_edges(),
		selected_race,
		selected_class
	)
	
	character_created.emit(character)
