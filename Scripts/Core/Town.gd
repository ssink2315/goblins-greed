extends Node2D

signal explore_selected
signal shop_opened
signal tavern_opened
signal guild_opened

func _ready():
	_connect_signals()

func _connect_signals():
	$LocationButtons/ExploreButton.pressed.connect(_on_explore_pressed)
	$LocationButtons/ShopButton.pressed.connect(_on_shop_pressed)
	$LocationButtons/TavernButton.pressed.connect(_on_tavern_pressed)
	$LocationButtons/GuildButton.pressed.connect(_on_guild_pressed)

func _on_explore_pressed():
	emit_signal("explore_selected")

func _on_shop_pressed():
	emit_signal("shop_opened")

func _on_tavern_pressed():
	emit_signal("tavern_opened")

func _on_guild_pressed():
	emit_signal("guild_opened")
