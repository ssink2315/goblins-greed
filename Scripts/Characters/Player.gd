extends BaseCharacter
class_name PlayerCharacter

# Progression
var experience: int = 0
var experience_to_next_level: int = 100
var skill_points: int = 0
var attribute_points: int = 0

# Skill Paths
var available_skill_paths: Array[String] = []
var current_path: String = ""
var path_progress: Dictionary = {}
var unlocked_talents: Array[Dictionary] = []

# Equipment
var equipped_items: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory1": null,
	"accessory2": null
}

# Inventory
var inventory: Array[Resource] = []
var max_inventory_size: int = 20

# Signals
signal experience_gained(amount: int, total: int)
signal level_up(new_level: int)
signal skill_point_gained(total: int)
signal talent_unlocked(talent: Dictionary)
signal inventory_changed
signal equipment_changed(slot: String, item: Resource)
signal path_progressed(path_id: String, level: int)

func _init():
	super._init()

func initialize(name: String, race_name: String, class_title: String):
	super.initialize(name, race_name, class_title)
	setup_skill_paths()
	calculate_experience_threshold()

func setup_skill_paths():
	var class_data = GameDatabase.get_class_data(class_title)
	if class_data:
		available_skill_paths = class_data.skill_paths
		for path in available_skill_paths:
			path_progress[path] = 0

func gain_experience(amount: int):
	experience += amount
	emit_signal("experience_gained", amount, experience)
	
	while experience >= experience_to_next_level:
		level_up()

func level_up():
	level += 1
	attribute_points += 2
	skill_points += 1
	
	experience -= experience_to_next_level
	calculate_experience_threshold()
	calculate_secondary_stats()
	
	# Heal on level up
	current_hp = max_hp
	current_mana = max_mana
	
	emit_signal("level_up", level)
	emit_signal("skill_point_gained", skill_points)

func calculate_experience_threshold():
	experience_to_next_level = 100 * pow(1.5, level - 1)

func spend_attribute_point(attribute: String) -> bool:
	if attribute_points <= 0:
		return false
	
	match attribute:
		"STR", "AGI", "INT", "VIT", "TEC", "WIS":
			set(attribute, get(attribute) + 1)
			attribute_points -= 1
			calculate_secondary_stats()
			return true
	
	return false

func spend_skill_point(path: String) -> bool:
	if skill_points <= 0:
		return false
	
	if path_manager.invest_point(path):
		skill_points -= 1
		emit_signal("skill_point_spent", path)
		return true
	return false

func check_for_talent_unlock(path: String) -> Dictionary:
	var progress = path_progress[path]
	# This would check against a talent tree configuration
	# Return format: {"name": "", "type": "", "effect": {}}
	return {}

func equip_item(item: Resource, slot: String) -> bool:
	if not item or not slot in equipped_items:
		return false
	
	if can_equip_item(item):
		var old_item = equipped_items[slot]
		if old_item:
			unequip_item(slot)
		
		equipped_items[slot] = item
		apply_item_stats(item)
		emit_signal("equipment_changed", slot, item)
		return true
	
	return false

func unequip_item(slot: String) -> bool:
	if not slot in equipped_items or not equipped_items[slot]:
		return false
	
	var item = equipped_items[slot]
	remove_item_stats(item)
	equipped_items[slot] = null
	add_to_inventory(item)
	emit_signal("equipment_changed", slot, null)
	return true

func can_equip_item(item: Resource) -> bool:
	if not item:
		return false
	
	match item.type:
		"weapon":
			return item.weapon_type in weapon_proficiencies
		"armor":
			return item.armor_type in armor_proficiencies
		_:
			return true

func apply_item_stats(item: Resource):
	for stat in item.stat_modifiers:
		set(stat, get(stat) + item.stat_modifiers[stat])
	calculate_secondary_stats()

func remove_item_stats(item: Resource):
	for stat in item.stat_modifiers:
		set(stat, get(stat) - item.stat_modifiers[stat])
	calculate_secondary_stats()

func add_to_inventory(item: Resource) -> bool:
	if inventory.size() >= max_inventory_size:
		return false
	
	inventory.append(item)
	emit_signal("inventory_changed")
	return true

func remove_from_inventory(item: Resource) -> bool:
	var index = inventory.find(item)
	if index != -1:
		inventory.remove_at(index)
		emit_signal("inventory_changed")
		return true
	return false

func _ready():
	super()
	# Initialize path manager with class paths and race path
	var class_paths = load("res://Resources/Classes/" + character_class + "Paths.tres")
	var race_path = load("res://Resources/Paths/Races/" + race + "Path.tres")
	path_manager.initialize(class_paths, race_path)
	
	# Connect signals
	path_manager.skill_learned.connect(_on_skill_learned)
	path_manager.stats_increased.connect(_on_stats_increased)
	path_manager.path_level_up.connect(_on_path_level_up)

func _on_path_level_up(path_id: String, level: int):
	emit_signal("path_progressed", path_id, level)
