extends Control

@onready var new_game_button = $VBoxContainer/NewGameButton
@onready var load_game_button = $VBoxContainer/LoadGameButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var version_label = $VersionLabel
@onready var test_battle_button = $VBoxContainer/TestBattleButton

const VERSION = "0.1.0"

func _ready():
	_connect_signals()
	version_label.text = "v" + VERSION
	# Disable load game for Phase 1
	load_game_button.disabled = true

func _connect_signals():
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	test_battle_button.pressed.connect(_on_test_battle_pressed)

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/CharacterCreation/CharacterCreationUI.tscn")

func _on_load_game_pressed():
	# Placeholder for Phase 2
	pass

func _on_settings_pressed():
	# Placeholder for settings menu
	pass

func _on_exit_pressed():
	get_tree().quit()

func _on_test_battle_pressed():
	get_parent().setup_test_scene()
