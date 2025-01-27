extends Control

@onready var front_row = $HBoxContainer/PartyContainer/RowContainer/FrontRow/Members
@onready var back_row = $HBoxContainer/PartyContainer/RowContainer/BackRow/Members
@onready var character_info = $CharacterInfo/Info

var party_manager: PartyManager
var selected_character: BaseCharacter

func initialize(manager: PartyManager):
	party_manager = manager
	refresh_ui()
	_connect_signals()

func _connect_signals():
	if party_manager:
		party_manager.party_updated.connect(refresh_ui)
		party_manager.row_changed.connect(_on_row_changed)

func refresh_ui():
	_update_rows()
	_update_gold()
	if selected_character:
		_show_character_info(selected_character)

func _update_rows():
	# Clear existing members
	for child in front_row.get_children():
		child.queue_free()
	for child in back_row.get_children():
		child.queue_free()
	
	# Add current party members to their rows
	for character in party_manager.get_party_members():
		var member_slot = _create_member_slot(character)
		if party_manager.get_character_row(character) == PartyManager.ROW.FRONT:
			front_row.add_child(member_slot)
		else:
			back_row.add_child(member_slot)

func _create_member_slot(character: BaseCharacter) -> Control:
	var slot = preload("res://Scenes/UI/Party/PartyMemberSlot.tscn").instantiate()
	slot.initialize(character)
	slot.pressed.connect(func(): _on_member_selected(character))
	return slot

func _on_member_selected(character: BaseCharacter):
	selected_character = character
	_show_character_info(character)

func _show_character_info(character: BaseCharacter):
	var info_text = "[center][b]%s[/b][/center]\n" % character.character_name
	info_text += "Level: %d\n" % character.level
	info_text += "Class: %s\n" % character.character_class
	info_text += "Race: %s\n\n" % character.race
	info_text += "HP: %d/%d\n" % [character.current_hp, character.max_hp]
	info_text += "MP: %d/%d\n" % [character.current_mana, character.max_mana]
	character_info.text = info_text

func _on_row_changed(_character: BaseCharacter, _new_row: int):
	refresh_ui()
