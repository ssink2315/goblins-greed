extends Node

@onready var companion_generator: CompanionGenerator = $CompanionGenerator
# Managers
@onready var combat_manager: Node = $CombatManager
@onready var party_manager: Node = $PartyManager
@onready var ui_manager: Node = $UIManager

@onready var hud = $HUD
@onready var menu_layer = $MenuLayer

var current_menu: Control

# Game state
var current_day: int = 1
var current_phase: String = "day"

# Scene management
var current_scene: Node = null
var main_menu_scene: PackedScene = preload("res://Scenes/UI/MainMenu/MainMenu.tscn")
var combat_scene: PackedScene = preload("res://Scenes/Combat/CombatScene.tscn")
var character_creation_scene: PackedScene = preload("res://Scenes/UI/CharacterCreation/CharacterCreationUI.tscn")
var town_scene: PackedScene = preload("res://Scenes/Towns/Palda.tscn")
var skill_tree_scene: PackedScene = preload("res://Scenes/UI/SkillTree/SkillTreeUI.tscn")

func _ready():
	_connect_signals()
	show_main_menu()
	setup_test_scene()

func _connect_signals():
	# Connect any global signals here
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel") and current_scene != main_menu_scene:
		toggle_game_menu()

func generate_new_companion(level: int = 1):
	var companion = companion_generator.generate_companion(level)
	if party_manager.add_companion(companion):
		return companion
	return null

func change_scene(new_scene: PackedScene):
	if current_scene:
		current_scene.queue_free()
	
	current_scene = new_scene.instantiate()
	add_child(current_scene)
	return current_scene

func show_main_menu():
	var menu = change_scene(main_menu_scene)
	menu.new_game_pressed.connect(start_character_creation)

func start_new_game(player_character: PlayerCharacter):
	party_manager.clear_party()
	party_manager.add_player(player_character)
	party_manager.set_gold(100)  # Starting gold
	
	# Initialize path system
	var class_paths = load("res://Resources/Classes/" + player_character.character_class + "Paths.tres")
	var race_path = load("res://Resources/Paths/Races/" + player_character.race + "Path.tres")
	player_character.path_manager.initialize(class_paths, race_path)
	
	var equipment_manager = StartingEquipmentManager.new()
	equipment_manager.generate_starting_equipment(player_character)
	
	enter_town()

func toggle_game_menu():
	if current_menu:
		current_menu.queue_free()
		current_menu = null
	else:
		show_game_menu()

func show_game_menu():
	var game_menu = preload("res://Scenes/UI/GameMenu/GameMenu.tscn").instantiate()
	menu_layer.add_child(game_menu)
	current_menu = game_menu
	
	game_menu.inventory_selected.connect(show_inventory)
	game_menu.party_selected.connect(show_party_management)
	game_menu.skills_selected.connect(show_skill_tree)
	game_menu.quit_selected.connect(return_to_main_menu)

func show_inventory():
	if current_menu:
		current_menu.queue_free()
	
	var inventory_screen = preload("res://Scenes/UI/InventoryUI/InventoryScreen.tscn").instantiate()
	menu_layer.add_child(inventory_screen)
	current_menu = inventory_screen
	inventory_screen.initialize(party_manager.get_player())

func show_party_management():
	if current_menu:
		current_menu.queue_free()
	
	var party_screen = preload("res://Scenes/UI/PartyUI/PartyManagementScreen.tscn").instantiate()
	menu_layer.add_child(party_screen)
	current_menu = party_screen
	party_screen.initialize(party_manager)

func show_skill_tree():
	if current_menu:
		current_menu.queue_free()
	
	var skill_tree = skill_tree_scene.instantiate()
	menu_layer.add_child(skill_tree)
	current_menu = skill_tree
	skill_tree.initialize(party_manager.get_player())

func return_to_main_menu():
	show_main_menu()

func start_character_creation():
	var creation_scene = change_scene(character_creation_scene)
	creation_scene.character_created.connect(_on_character_created)

func _on_character_created(player_character: PlayerCharacter):
	start_new_game(player_character)

func start_combat(enemies: Array):
	change_scene(combat_scene)
	combat_manager.start_combat(CombatManager.CombatType.RANDOM_ENCOUNTER, 
							  party_manager.get_party(), 
							  enemies)

func enter_town():
	change_scene(town_scene)

func setup_test_scene():
	# Create test party with Adventurer and Wizard
	var adventurer = PlayerCharacter.new()
	adventurer.initialize("Human", "Adventurer")  # Basic adventurer with sword skills
	var wizard = PlayerCharacter.new()
	wizard.initialize("Human", "Wizard")  # Spellcaster with magic abilities
	
	# Add to party
	party_manager.clear_party()
	party_manager.add_player(adventurer)
	party_manager.add_companion(wizard)
	
	# Give them starting equipment
	var equipment_manager = StartingEquipmentManager.new()
	equipment_manager.generate_starting_equipment(adventurer)
	equipment_manager.generate_starting_equipment(wizard)
	
	# Create test enemies (using existing goblin templates)
	var enemies = [
		EnemyCharacter.new("Goblin Warrior"),
		EnemyCharacter.new("Goblin Shaman")
	]
	
	# Start test combat
	start_combat(enemies)
