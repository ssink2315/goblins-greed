extends Control

signal transaction_completed(item: ItemData, price: int, is_buying: bool)
signal shop_closed

@onready var item_list = $ShopContainer/BuyPanel/VBoxContainer/ItemList
@onready var item_info = $ShopContainer/InfoPanel/VBoxContainer/ItemInfo
@onready var buy_button = $ShopContainer/InfoPanel/VBoxContainer/BuyButton
@onready var gold_label = $ShopContainer/InfoPanel/VBoxContainer/GoldLabel
@onready var close_button = $ShopContainer/InfoPanel/VBoxContainer/CloseButton

var shop_inventory: Array = []
var selected_item: ItemData
var party_manager: PartyManager

func initialize(manager: PartyManager):
	party_manager = manager
	_populate_shop()
	_update_gold()
	_connect_signals()

func _connect_signals():
	item_list.item_selected.connect(_on_item_selected)
	buy_button.pressed.connect(_on_buy_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	if party_manager:
		party_manager.gold_changed.connect(_update_gold)

func _populate_shop():
	item_list.clear()
	shop_inventory = GameDatabase.get_shop_inventory()
	
	for item in shop_inventory:
		item_list.add_item(item.get_display_name())
		var idx = item_list.get_item_count() - 1
		item_list.set_item_metadata(idx, item)

func _update_gold():
	gold_label.text = "Gold: %d" % party_manager.get_gold()

func _on_item_selected(index: int):
	selected_item = item_list.get_item_metadata(index)
	_show_item_info(selected_item)
	buy_button.disabled = selected_item.price > party_manager.get_gold()

func _show_item_info(item: ItemData):
	var text = "[center][b]%s[/b][/center]\n" % item.get_display_name()
	text += item.description + "\n\n"
	text += "[b]Price:[/b] %d gold\n" % item.price
	
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

func _on_buy_pressed():
	if selected_item and party_manager.get_gold() >= selected_item.price:
		transaction_completed.emit(selected_item, selected_item.price, true)
		_update_gold()
		buy_button.disabled = true

func _on_close_pressed():
	shop_closed.emit()
	queue_free()
