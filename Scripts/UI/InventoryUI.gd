extends Control

signal item_used(item: ItemData, target: Node)
signal item_equipped(item: ItemData)
signal item_unequipped(item: ItemData)

@onready var item_list = $MainContainer/ItemList
@onready var equipment_slots = $MainContainer/EquipmentPanel/Slots
@onready var item_description = $MainContainer/ItemDescription
@onready var character_stats = $MainContainer/CharacterStats
@onready var gold_label = $MainContainer/TopBar/GoldAmount

var current_character: BaseCharacter
var selected_item: ItemData

func _ready():
    _connect_signals()
    hide()

func _connect_signals():
    item_list.item_selected.connect(_on_item_selected)
    for slot in equipment_slots.get_children():
        slot.item_clicked.connect(_on_equipment_clicked)

func show_inventory(character: BaseCharacter):
    current_character = character
    refresh_display()
    show()

func refresh_display():
    if !current_character:
        return
        
    _update_item_list()
    _update_equipment()
    _update_stats()
    _update_gold()

func _update_item_list():
    item_list.clear()
    
    var items = current_character.inventory.get_all_items()
    for item in items:
        var icon = item.icon if item.icon else preload("res://Assets/Icons/default_item.png")
        item_list.add_item(item.item_name, icon)
        
        # Add count for stackable items
        var count = current_character.inventory.get_item_count(item)
        if count > 1:
            var idx = item_list.get_item_count() - 1
            item_list.set_item_text(idx, "%s (%d)" % [item.item_name, count])

func _update_equipment():
    var equipped = current_character.inventory.get_equipped_items()
    
    for slot in equipment_slots.get_children():
        var slot_type = slot.name.to_lower()
        slot.clear()
        
        if equipped.has(slot_type):
            var item = equipped[slot_type]
            slot.set_item(item)

func _update_stats():
    var stats = current_character.get_total_stats()
    character_stats.text = """
    HP: %d/%d
    Mana: %d/%d
    
    STR: %d
    AGI: %d
    INT: %d
    VIT: %d
    TEC: %d
    WIS: %d
    
    Physical Attack: %d
    Magic Attack: %d
    Physical Defense: %d
    Magic Defense: %d
    """ % [
        current_character.current_hp, current_character.max_hp,
        current_character.current_mana, current_character.max_mana,
        stats.STR, stats.AGI, stats.INT, stats.VIT, stats.TEC, stats.WIS,
        stats.phys_atk, stats.magic_atk, stats.phys_def, stats.magic_def
    ]

func _update_gold():
    gold_label.text = str(current_character.inventory.gold)

func _on_item_selected(index: int):
    var item_name = item_list.get_item_text(index).split(" (")[0]  # Remove count from name
    selected_item = current_character.inventory.get_item(item_name)
    
    if selected_item:
        item_description.text = _get_item_description(selected_item)
        _show_item_actions(selected_item)

func _get_item_description(item: ItemData) -> String:
    var desc = "[b]%s[/b]\n%s\n" % [item.item_name, item.description]
    
    if item is EquipmentData:
        desc += "\n[u]Stats:[/u]\n"
        for stat in item.stat_modifiers:
            if item.stat_modifiers[stat] != 0:
                desc += "%s: %d\n" % [stat, item.stat_modifiers[stat]]
    
    return desc

func _show_item_actions(item: ItemData):
    $MainContainer/ActionPanel.show()
    var use_button = $MainContainer/ActionPanel/UseButton
    var equip_button = $MainContainer/ActionPanel/EquipButton
    var drop_button = $MainContainer/ActionPanel/DropButton
    
    use_button.visible = item is ConsumableData
    equip_button.visible = item is EquipmentData
    
    if item is EquipmentData:
        var is_equipped = current_character.inventory.is_item_equipped(item)
        equip_button.text = "Unequip" if is_equipped else "Equip"

func _on_use_pressed():
    if selected_item is ConsumableData:
        item_used.emit(selected_item, current_character)
        refresh_display()

func _on_equip_pressed():
    if selected_item is EquipmentData:
        if current_character.inventory.is_item_equipped(selected_item):
            current_character.inventory.unequip_item(selected_item)
            item_unequipped.emit(selected_item)
        else:
            current_character.inventory.equip_item(selected_item)
            item_equipped.emit(selected_item)
        refresh_display()

func _on_drop_pressed():
    if selected_item:
        current_character.inventory.remove_item(selected_item)
        refresh_display()

func _on_equipment_clicked(slot_name: String):
    var equipped_item = current_character.inventory.get_equipped_item(slot_name)
    if equipped_item:
        selected_item = equipped_item
        item_description.text = _get_item_description(equipped_item)
        _show_item_actions(equipped_item) 