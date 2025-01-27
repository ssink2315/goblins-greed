extends Node

signal game_loaded
signal game_saved

var party_manager: PartyManager
var current_player: PlayerCharacter

# Configurable starting conditions
var starting_gold: int = 100  # Starting gold can be adjusted as needed

func _init():
	party_manager = PartyManager.new()

func start_new_game(player: PlayerCharacter):
	if player == null:
		push_error("Cannot start a new game without a valid player character.")
		return

	current_player = player
	party_manager.add_character(player)
	
	# Initialize starting conditions
	party_manager.set_gold(starting_gold)  # Use configurable starting gold
	_setup_starting_equipment()

func _setup_starting_equipment():
	if current_player:
		var equipment_manager = StartingEquipmentManager.new()
		equipment_manager.generate_starting_equipment(current_player)

# Cleanup function to reset game state
func cleanup():
	current_player = null
	party_manager.clear_party()  # Clear the party for a fresh start
	party_manager.set_gold(0)  # Reset gold
