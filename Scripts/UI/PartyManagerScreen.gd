extends Control

signal member_moved(character: BaseCharacter, new_row: int)
signal member_removed(character: BaseCharacter)
signal member_selected(character: BaseCharacter)

@onready var front_row = $Layout/Content/MainContainer/RowsContainer/FrontRow/Slots
@onready var back_row = $Layout/Content/MainContainer/RowsContainer/BackRow/Slots
@onready var reserve_panel = $Layout/Content/SidePanel/ReserveList
@onready var character_info = $Layout/Content/SidePanel/CharacterInfo
@onready var gold_display = $Layout/TopBar/MarginContainer/HBoxContainer/GoldDisplay

const MAX_ROW_SIZE = 3
var party_manager: PartyManager
var selected_character: BaseCharacter
var character_slots: Dictionary = {
	"front": [],
	"back": []
}

func _ready():
	_setup_row_slots()
	_connect_signals()

func initialize(manager: PartyManager) -> void:
	party_manager = manager
	party_manager.party_updated.connect(refresh_ui)
	party_manager.member_added.connect(refresh_ui)
	party_manager.member_removed.connect(refresh_ui)
	party_manager.row_changed.connect(refresh_ui)
	party_manager.gold_changed.connect(_update_gold)
	refresh_ui()

func _setup_row_slots():
	var slot_scene = preload("res://Scenes/UI/Components/CharacterSlot.tscn")
	
	# Setup front row
	for i in range(MAX_ROW_SIZE):
		var slot = slot_scene.instantiate()
		front_row.add_child(slot)
		character_slots.front.append(slot)
		_connect_slot_signals(slot)
	
	# Setup back row
	for i in range(MAX_ROW_SIZE):
		var slot = slot_scene.instantiate()
		back_row.add_child(slot)
		character_slots.back.append(slot)
		_connect_slot_signals(slot)

func _connect_slot_signals(slot: CharacterSlot):
	slot.character_clicked.connect(_on_character_clicked)
	slot.character_right_clicked.connect(_on_character_right_clicked)
	slot.character_hovered.connect(_show_character_info)
	slot.character_hover_ended.connect(_clear_character_info)

func refresh_ui() -> void:
	_update_rows()
	_update_reserve_list()
	_update_gold()

func _update_rows() -> void:
	# Clear all slots
	for slot in character_slots.front:
		slot.set_character(null)
	for slot in character_slots.back:
		slot.set_character(null)
	
	# Update with current party members
	var front_members = party_manager.get_row_members(PartyManager.ROW.FRONT)
	var back_members = party_manager.get_row_members(PartyManager.ROW.BACK)
	
	for i in range(front_members.size()):
		if i < character_slots.front.size():
			character_slots.front[i].set_character(front_members[i])
	
	for i in range(back_members.size()):
		if i < character_slots.back.size():
			character_slots.back[i].set_character(back_members[i])

func _update_reserve_list() -> void:
	reserve_panel.clear()
	
	for character in party_manager.get_reserve_members():
		var slot = preload("res://Scenes/UI/Components/CharacterSlot.tscn").instantiate()
		reserve_panel.add_child(slot)
		slot.set_character(character)
		_connect_slot_signals(slot)

func _update_gold(amount: int = -1):
	if amount < 0:
		amount = party_manager.get_gold()
	gold_display.text = str(amount) + " Gold"

func _show_character_info(character: BaseCharacter):
	if !character:
		return
	
	var text = "[center][b]%s[/b][/center]\n" % character.character_name
	text += "Level %d %s\n" % [character.level, character.class_name]
	text += "\nStats:\n"
	text += "HP: %d/%d\n" % [character.current_hp, character.max_hp]
	text += "MP: %d/%d\n" % [character.current_mp, character.max_mp]
	text += "Attack: %d\n" % character.attack
	text += "Defense: %d\n" % character.defense
	text += "\nEquipment:\n"
	
	for slot in character.equipment:
		var item = character.equipment[slot]
		text += "%s: %s\n" % [slot, item.item_name if item else "None"]
	
	character_info.text = text

func _clear_character_info():
	character_info.text = ""

func _on_character_clicked(character: BaseCharacter):
	selected_character = character
	member_selected.emit(character)

func _on_character_right_clicked(character: BaseCharacter):
	var menu = PopupMenu.new()
	add_child(menu)
	
	menu.add_item("Move to Front Row", 0)
	menu.add_item("Move to Back Row", 1)
	menu.add_item("Move to Reserve", 2)
	menu.add_separator()
	menu.add_item("View Details", 3)
	
	menu.id_pressed.connect(func(id): _handle_context_menu(id, character))
	menu.popup(get_global_mouse_position())

func _handle_context_menu(id: int, character: BaseCharacter):
	match id:
		0: # Move to Front Row
			member_moved.emit(character, PartyManager.ROW.FRONT)
		1: # Move to Back Row
			member_moved.emit(character, PartyManager.ROW.BACK)
		2: # Move to Reserve
			member_removed.emit(character)
		3: # View Details
			selected_character = character
			member_selected.emit(character)
