extends Control

signal inventory_requested
signal character_sheet_requested
signal quest_log_requested
signal menu_requested

@onready var party_container = $Layout/Content/HBoxContainer/LeftPanel/PartyStatus/PartyStatusContainer
@onready var resource_display = $Layout/Content/HBoxContainer/LeftPanel/ResourceDisplay/VBoxContainer
@onready var quest_list = $Layout/Content/HBoxContainer/RightPanel/QuestTracker/MarginContainer/VBoxContainer/QuestList

var character_slots: Array[CharacterSlot] = []

func _ready():
	_setup_party_display()
	_connect_signals()

func _setup_party_display():
	var slot_scene = preload("res://Scenes/UI/Components/CharacterSlot.tscn")
	
	for i in range(4):  # Maximum party size
		var slot = slot_scene.instantiate()
		party_container.add_child(slot)
		character_slots.append(slot)
		
		slot.character_clicked.connect(_on_character_clicked)
		slot.character_right_clicked.connect(_on_character_right_clicked)
		slot.character_hovered.connect(_on_character_hovered)
		slot.character_hover_ended.connect(_on_character_hover_ended)

func update_party(party_members: Array[BaseCharacter]):
	for i in range(character_slots.size()):
		if i < party_members.size():
			character_slots[i].set_character(party_members[i])
		else:
			character_slots[i].set_character(null)

func update_resources(gold: int, other_resources: Dictionary = {}):
	# Clear existing resource displays
	for child in resource_display.get_children():
		if child.name != "GoldDisplay":  # Keep gold display
			child.queue_free()
	
	# Update gold
	var gold_display = resource_display.get_node("GoldDisplay")
	gold_display.get_node("Amount").text = str(gold)
	
	# Add other resources
	for resource_name in other_resources:
		var resource_display = _create_resource_display(
			resource_name,
			other_resources[resource_name]
		)
		resource_display.add_child(resource_display)

func update_quests(active_quests: Array):
	# Clear existing quests
	for child in quest_list.get_children():
		if child.name != "Label":  # Keep header
			child.queue_free()
	
	# Add active quests
	for quest in active_quests:
		var quest_entry = _create_quest_entry(quest)
		quest_list.add_child(quest_entry)

func _create_resource_display(name: String, amount: int) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = UITheme.SIZES.icon
	icon.expand_mode = TextureRect.EXPAND_KEEP_ASPECT
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(icon)
	
	var label = Label.new()
	label.text = str(amount)
	container.add_child(label)
	
	return container

func _create_quest_entry(quest: Dictionary) -> PanelContainer:
	var container = PanelContainer.new()
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACING.margin_inner)
	margin.add_theme_constant_override("margin_right", UITheme.SPACING.margin_inner)
	margin.add_theme_constant_override("margin_top", UITheme.SPACING.padding_button_v)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACING.padding_button_v)
	container.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = quest.title
	title.add_theme_font_size_override("font_size", UITheme.FONTS.normal)
	vbox.add_child(title)
	
	var objective = Label.new()
	objective.text = quest.current_objective
	objective.add_theme_font_size_override("font_size", UITheme.FONTS.small)
	objective.add_theme_color_override("font_color", UITheme.COLORS.text.darkened(0.2))
	vbox.add_child(objective)
	
	return container

func _on_character_clicked(character: BaseCharacter):
	character_sheet_requested.emit(character)

func _on_character_right_clicked(character: BaseCharacter):
	# Show context menu
	pass

func _on_character_hovered(character: BaseCharacter):
	# Show tooltip
	pass

func _on_character_hover_ended():
	# Hide tooltip
	pass

func _connect_signals():
	if party_manager:
		party_manager.party_updated.connect(refresh_hud)
		party_manager.gold_changed.connect(_update_gold)

func refresh_hud():
	_clear_party_slots()
	_create_party_slots()
	_update_gold()

func _clear_party_slots():
	for slot in character_slots:
		slot.queue_free()
	character_slots.clear()

func _create_party_slots():
	for character in party_manager.get_party_members():
		var slot = preload("res://Scenes/UI/Components/CharacterSlot.tscn").instantiate()
		party_container.add_child(slot)
		character_slots.append(slot)
		slot.initialize(character)

func _update_gold():
	if party_manager:
		gold_label.text = str(party_manager.get_gold())
