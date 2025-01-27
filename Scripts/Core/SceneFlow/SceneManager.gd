extends Node

signal scene_changed(new_scene_name: String)

const SCENES = {
	"main_menu": "res://Scenes/UI/MainMenu/MainMenu.tscn",
	"character_creation": "res://Scenes/UI/CharacterCreation/CharacterCreationUI.tscn",
	"party_management": "res://Scenes/UI/PartyUI/PartyManagementScreen.tscn",
	"inventory": "res://Scenes/UI/InventoryUI/InventoryScreen.tscn",
	"game": "res://Scenes/Game/GameMain.tscn"
}

var current_scene: Node
var game_state: GameState

func _ready():
	game_state = GameState.new()
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(scene_name: String):
	if not scene_name in SCENES:
		push_error("Scene %s not found in SCENES dictionary" % scene_name)
		return
		
	call_deferred("_deferred_goto_scene", SCENES[scene_name])

func _deferred_goto_scene(path: String):
	if current_scene:
		current_scene.free()  # Free the current scene only if it exists

	var new_scene = load(path).instantiate()
	if new_scene:
		get_tree().root.add_child(new_scene)
		get_tree().current_scene = new_scene
		current_scene = new_scene
		emit_signal("scene_changed", path.get_file().get_basename())
	else:
		push_error("Failed to instantiate new scene from path: %s" % path)

func start_new_game():
	goto_scene("character_creation")

func enter_game():
	goto_scene("game")

func return_to_main_menu():
	goto_scene("main_menu")
