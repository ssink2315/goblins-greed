extends Control

@onready var inventory_list = $InventoryPanel/VBoxContainer/InventoryList
@onready var equipment_slots = {
	"weapon": $EquipmentPanel/GridContainer/WeaponSlot,
	"armor": $EquipmentPanel/GridContainer/ArmorSlot,
	"accessory": $EquipmentPanel/GridContainer/AccessorySlot
}
@onready var item_info = $InfoPanel/MarginContainer/ItemInfo
@onready var character_stats = $StatsPanel/MarginContainer/CharacterStats
@onready var use_button = $ActionPanel/UseButton
@onready var equip_button = $ActionPanel/EquipButton

signal item_used(item: ItemData, character: BaseCharacter)
signal item_equipped(item: ItemData, slot: String)
signal item_unequipped(item: ItemData, slot: String)

var current_character: BaseCharacter
var selected_item: ItemData
var selected_slot: String

func initialize(character: BaseCharacter):
	current_character = character
	_connect_signals()
	refresh_ui()

func _connect_signals():
	inventory_list.item_selected.connect(_on_inventory_item_selected)
	use_button.pressed.connect(_on_use_pressed)
	equip_button.pressed.connect(_on_equip_pressed)
	
	for slot_name in equipment_slots:
		var slot = equipment_slots[slot_name]
		slot.gui_input.connect(func(event): _on_slot_input(event, slot_name))

func refresh_ui():
	_update_inventory_list()
	_update_equipment_slots()
	_update_character_stats()
	_update_buttons()
	item_info.text = ""

func _update_inventory_list():
	inventory_list.clear()
	for item in current_character.inventory.items:
		inventory_list.add_item(item.get_display_name())
		var idx = inventory_list.get_item_count() - 1
		inventory_list.set_item_metadata(idx, item)

func _update_equipment_slots():
	for slot_name in equipment_slots:
		var slot = equipment_slots[slot_name]
		var equipped_item = current_character.get_equipped_item(slot_name)
		_update_slot(slot, equipped_item)

func _update_slot(slot: TextureRect, item: ItemData):
	if item:
		slot.texture = item.icon
		slot.tooltip_text = item.get_display_name()
		slot.set_meta("item", item)
	else:
		slot.texture = load("res://Assets/UI/empty_slot.png")
		slot.tooltip_text = "Empty Slot"
		slot.set_meta("item", null)

func _update_character_stats():
	var stats = current_character.get_all_stats()
	var text = "[center][b]Character Stats[/b][/center]\n"
	for stat_name in stats:
		text += "%s: %d\n" % [stat_name, stats[stat_name]]
	character_stats.text = text

func _update_buttons():
	if !selected_item:
		use_button.disabled = true
		equip_button.disabled = true
		return
	
	use_button.disabled = !selected_item.is_usable()
	equip_button.disabled = !selected_item.is_equipment()

func _on_inventory_item_selected(index: int):
	selected_item = inventory_list.get_item_metadata(index)
	_show_item_info(selected_item)
	_update_buttons()

func _show_item_info(item: ItemData):
	var text = "[center][b]%s[/b][/center]\n" % item.get_display_name()
	text += item.description + "\n\n"
	
	match item.item_type:
		ItemData.ItemType.WEAPON:
			text += "[b]Damage:[/b] %d-%d\n" % [item.min_damage, item.max_damage]
		ItemData.ItemType.ARMOR:
			text += "[b]Defense:[/b] %d\n" % item.defense
		ItemData.ItemType.ACCESSORY:
			text += "[b]Effects:[/b]\n"
			for effect in item.effects:
				text += "• %s\n" % effect
	
	item_info.text = text

func _on_slot_input(event: InputEvent, slot_name: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_slot = slot_name
		var equipped_item = current_character.get_equipped_item(slot_name)
		if equipped_item:
			selected_item = equipped_item
			_show_item_info(equipped_item)
			_update_buttons()

func _on_use_pressed():
	if selected_item and selected_item.is_usable():
		item_used.emit(selected_item, current_character)
		refresh_ui()

func _on_equip_pressed():
	if selected_item and selected_item.is_equipment():
		var slot = selected_item.get_equipment_slot()
		item_equipped.emit(selected_item, slot)
		refresh_ui()
