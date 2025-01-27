extends Node

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(error: String)
signal load_failed(error: String)

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"
const MAX_SAVE_SLOTS = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

func save_game(slot: int) -> bool:
	var save_data = {
		"timestamp": Time.get_unix_time_from_system(),
		"version": ProjectSettings.get_setting("application/config/version"),
		"combat_state": _get_combat_state(),
		"party_state": _get_party_state(),
		"game_progress": _get_game_progress()
	}
	
	var save_path = _get_save_path(slot)
	var result = _write_save_file(save_path, save_data)
	
	if result:
		save_completed.emit(slot)
	else:
		save_failed.emit("Failed to write save file")
	
	return result

func load_game(slot: int) -> bool:
	var save_path = _get_save_path(slot)
	if not FileAccess.file_exists(save_path):
		load_failed.emit("Save file does not exist")
		return false
	
	var save_data = _read_save_file(save_path)
	if not save_data:
		load_failed.emit("Failed to read save file")
		return false
	
	if not _validate_save_data(save_data):
		load_failed.emit("Invalid save data")
		return false
	
	_restore_game_state(save_data)
	load_completed.emit(slot)
	return true

func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION

func _write_save_file(path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	
	var json_string = JSON.stringify(data)
	file.store_string(json_string)
	return true

func _read_save_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	return json.get_data()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _get_combat_state() -> Dictionary:
	var combat_manager = get_node("/root/GameManager/CombatManager")
	if not combat_manager or not combat_manager.combat_active:
		return {}
	
	return {
		"active_unit": _serialize_unit(combat_manager.active_unit),
		"round_number": combat_manager.round_number,
		"turn_order": combat_manager.turn_manager.get_serialized_turn_order(),
		"action_queue": combat_manager.action_queue.duplicate(),
		"front_row": _serialize_unit_list(combat_manager.front_row),
		"back_row": _serialize_unit_list(combat_manager.back_row),
		"combat_type": combat_manager.combat_type,
		"current_state": combat_manager.current_state,
		"current_flow_state": combat_manager.current_flow_state
	}

func _get_party_state() -> Dictionary:
	var party_manager = get_node("/root/GameManager/PartyManager")
	if not party_manager:
		return {}
	
	return {
		"player_party": _serialize_unit_list(party_manager.player_party),
		"inventory": _serialize_inventory(party_manager.inventory),
		"equipment": _serialize_equipment(party_manager.equipment),
		"resources": party_manager.resources.duplicate(),
		"unlocked_skills": party_manager.unlocked_skills.duplicate()
	}

func _get_game_progress() -> Dictionary:
	var game_manager = get_node("/root/GameManager")
	return {
		"completed_events": game_manager.completed_events.duplicate(),
		"current_chapter": game_manager.current_chapter,
		"discovered_locations": game_manager.discovered_locations.duplicate(),
		"quest_progress": game_manager.quest_progress.duplicate(),
		"play_time": game_manager.play_time
	}

func _serialize_unit(unit: BaseCharacter) -> Dictionary:
	if not unit:
		return {}
	
	return {
		"id": unit.id,
		"character_name": unit.character_name,
		"level": unit.level,
		"current_hp": unit.current_hp,
		"current_mp": unit.current_mp,
		"experience": unit.experience,
		"stats": unit.stats.duplicate(),
		"equipment": _serialize_unit_equipment(unit),
		"learned_skills": unit.learned_skills.map(func(skill): return skill.id),
		"status_effects": unit.get_active_status_effects(),
		"position": {
			"x": unit.position.x,
			"y": unit.position.y
		}
	}

func _serialize_unit_list(units: Array) -> Array:
	return units.map(_serialize_unit)

func _serialize_inventory(inventory: Dictionary) -> Dictionary:
	var serialized = {}
	for item_id in inventory:
		serialized[item_id] = {
			"quantity": inventory[item_id].quantity,
			"data": inventory[item_id].data.duplicate()
		}
	return serialized

func _serialize_equipment(equipment: Dictionary) -> Dictionary:
	var serialized = {}
	for unit_id in equipment:
		serialized[unit_id] = {}
		for slot in equipment[unit_id]:
			if equipment[unit_id][slot]:
				serialized[unit_id][slot] = equipment[unit_id][slot].id
	return serialized

func _serialize_unit_equipment(unit: BaseCharacter) -> Dictionary:
	var equipment = {}
	for slot in unit.equipment:
		if unit.equipment[slot]:
			equipment[slot] = unit.equipment[slot].id
	return equipment

func _validate_save_data(data: Dictionary) -> bool:
	# Check required keys
	var required_keys = ["timestamp", "version", "party_state", "game_progress"]
	for key in required_keys:
		if not data.has(key):
			return false
	
	# Version compatibility check
	var current_version = ProjectSettings.get_setting("application/config/version")
	if data.version != current_version:
		push_warning("Save file version mismatch: %s vs %s" % [data.version, current_version])
	
	return true

func _restore_game_state(data: Dictionary):
	var game_manager = get_node("/root/GameManager")
	var party_manager = game_manager.get_node("PartyManager")
	var combat_manager = game_manager.get_node("CombatManager")
	
	# Restore party state
	if data.has("party_state"):
		party_manager.restore_party_state(data.party_state)
	
	# Restore combat if active
	if data.has("combat_state") and not data.combat_state.is_empty():
		combat_manager.restore_combat_state(data.combat_state)
	
	# Restore game progress
	if data.has("game_progress"):
		game_manager.restore_progress(data.game_progress)
