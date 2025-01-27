extends Node
class_name BaseCharacter

# Primary Stats
var STR: int = 0
var AGI: int = 0
var INT: int = 0
var VIT: int = 0
var TEC: int = 0
var WIS: int = 0
var level: int = 1

# Secondary Stats
var max_hp: int = 0
var current_hp: int = 0
var max_mana: int = 0
var current_mana: int = 0
var rest_benefit: float = 0.0
var phys_dmg_mod: float = 1.0
var magic_dmg_mod: float = 1.0
var crit_chance: float = 0.0
var initiative: float = 0.0
var evasion: float = 0.0
var accuracy: float = 100.0
var phys_def: float = 0.0
var magic_def: float = 0.0
var phys_res: float = 0.0
var magic_res: float = 0.0
var debuff_res: float = 0.0
var crit_dmg_bonus: float = 1.5
var crit_mana_restore: float = 0.0  # New: MP restored on crit
var healing_done: float = 0.0       # New: % Healing Done
var healing_received: float = 0.0    # New: % Healing Received
var exp_gain: float = 0.0           # New: % Experience Gained
var mana_cost_reduction: float = 0.0 # New: % Mana Cost Reduction

# Character Info
var character_name: String = ""
var race: String = ""
var class_title: String = ""
var skills: Array[Resource] = []
var weapon_proficiencies: Array[String] = []
var armor_proficiencies: Array[String] = []
var skill_modifiers: Dictionary = {}
var resource_modifiers: Dictionary = {}
var inventory: InventoryManager

# Combat State
var is_defending: bool = false
var has_acted: bool = false
var current_row: int = CombatEnums.Row.FRONT
var statuses: Dictionary = {}
var resistances: Dictionary = {}
var status_immunities: Array = []   # New: Status immunities

# Signals
signal hp_changed(new_value: int, max_value: int)
signal mana_changed(new_value: int, max_value: int)
signal status_changed(status: String)
signal died
signal stats_updated

# Add to existing properties
var granted_skills: Array[String] = []
var granted_passives: Array[String] = []

# Add to equipment handling
var equipment: Dictionary = {}

# Add to existing properties
var path_manager: PathManager
var skill_points: int = 0

# Add to initialization
func _init():
	initialize_resistances()
	path_manager = PathManager.new()

func initialize_resistances():
	resistances = {
		"Holy": 0.0,
		"Dark": 0.0,
		"Fire": 0.0,
		"Ice": 0.0,
		"Nature": 0.0,
		"Arcane": 0.0
	}

func initialize(name: String, race_name: String, class_title: String):
	character_name = name
	
	# Apply race data
	var race_data = GameDatabase.get_race_data(race_name)
	if race_data:
		race = race_name
		race_data.apply_racial_bonuses(self)
	
	# Apply class data
	var class_data = GameDatabase.get_class_data(class_title)
	if class_data:
		class_title = class_title
		class_data.apply_class_bonuses(self)
	
	calculate_secondary_stats()
	current_hp = max_hp
	current_mana = max_mana

func calculate_secondary_stats():
	max_hp = GameDatabase.calculate_base_hp(VIT)
	max_mana = GameDatabase.calculate_base_mana(INT, WIS)
	rest_benefit = WIS / 4.0
	phys_dmg_mod = 100 + (STR / 4.0)
	magic_dmg_mod = 100 + (INT / 4.0)
	crit_chance = TEC / 2.0
	initiative = AGI / 2.0
	evasion = AGI / 2.0
	accuracy = 100 + (TEC * 0.5)
	phys_def = (VIT * 0.5) + (STR * 0.25)
	magic_def = (WIS * 0.5) + (INT * 0.25)
	phys_res = (VIT * 0.25) + (STR * 0.15) + (TEC * 0.1)
	magic_res = (WIS * 0.25) + (INT * 0.15) + (TEC * 0.1)
	debuff_res = (WIS * 0.2) + (TEC * 0.3)
	emit_signal("stats_updated")

func take_damage(damage: int, damage_type: String = "physical", element: String = "none") -> int:
	var final_damage = damage
	
	# Apply resistances
	if element in resistances:
		final_damage *= (1.0 - (resistances[element] / 100.0))
	
	# Apply defense and resistance
	match damage_type:
		"physical":
			final_damage = max(1, final_damage - phys_def)
			final_damage *= (1.0 - (phys_res / 100.0))
		"magical":
			final_damage = max(1, final_damage - magic_def)
			final_damage *= (1.0 - (magic_res / 100.0))
		"pure":
			final_damage = damage  # Pure damage ignores defenses
	
	current_hp -= final_damage
	emit_signal("hp_changed", current_hp, max_hp)
	
	if current_hp <= 0:
		die()
	
	return final_damage

func heal(amount: int):
	var heal_amount = int(amount * (1.0 + healing_received / 100.0))
	current_hp = min(current_hp + heal_amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

func use_mana(amount: int) -> bool:
	var cost = int(amount * (1.0 - (mana_cost_reduction / 100.0)))
	if current_mana >= cost:
		current_mana -= cost
		emit_signal("mana_changed", current_mana, max_mana)
		return true
	return false

func restore_mana(amount: int):
	current_mana = min(current_mana + amount, max_mana)
	emit_signal("mana_changed", current_mana, max_mana)

func add_skill(skill: Resource):
	if skills.size() < 4:
		skills.append(skill)

func use_skill(skill_index: int, target: Node) -> Dictionary:
	if skill_index >= 0 and skill_index < skills.size():
		var skill = skills[skill_index]
		if use_mana(skill.mana_cost):
			return skill.use_skill(self, target)
	return {"success": false, "reason": "Invalid skill or insufficient mana"}

func apply_status(status: String, duration: int):
	if status in status_immunities:
		return false
		
	if randf() <= (debuff_res / 100.0):
		return false
		
	statuses[status] = duration
	emit_signal("status_changed", status)
	return true

func update_statuses():
	var expired_statuses = []
	for status in statuses:
		statuses[status] -= 1
		if statuses[status] <= 0:
			expired_statuses.append(status)
	
	for status in expired_statuses:
		statuses.erase(status)
		emit_signal("status_changed", status)

func add_status_immunity(status_name: String):
	if not status_name in status_immunities:
		status_immunities.append(status_name)

func is_alive() -> bool:
	return current_hp > 0

func die():
	emit_signal("died")

func defend():
	is_defending = true
	phys_res *= 1.5
	magic_res *= 1.5

func end_turn():
	is_defending = false
	has_acted = true
	update_statuses()

func reset_turn():
	has_acted = false
	if is_defending:
		is_defending = false
		phys_res /= 1.5
		magic_res /= 1.5

func get_stats_display() -> String:
	return """
	Name: %s
	Class: %s
	HP: %d/%d
	MP: %d/%d
	STR: %d  AGI: %d  INT: %d
	VIT: %d  TEC: %d  WIS: %d
	""" % [character_name, class_title, current_hp, max_hp, 
		   current_mana, max_mana, STR, AGI, INT, VIT, TEC, WIS]

func get_initiative_modifier() -> float:
	var mod = initiative
	for status in statuses.keys():
		# Add status effect modifiers if any
		pass
	return mod

func can_act() -> bool:
	return is_alive() and not statuses.has("Stunned")

func has_usable_skills() -> bool:
	return skills.any(func(skill): return current_mana >= skill.mana_cost)

func has_usable_items() -> bool:
	return inventory and inventory.has_usable_items()

func get_row_damage_modifier() -> float:
	return 0.75 if current_row == CombatEnums.Row.BACK else 1.0

func get_row_defense_modifier() -> float:
	return 1.25 if current_row == CombatEnums.Row.BACK else 1.0

func get_effective_damage(base_damage: float, is_physical: bool = true) -> float:
	var row_mod = get_row_damage_modifier()
	var damage_mod = phys_dmg_mod if is_physical else magic_dmg_mod
	return base_damage * damage_mod * row_mod

func get_effective_defense(base_defense: float, is_physical: bool = true) -> float:
	var row_mod = get_row_defense_modifier()
	var defense = phys_def if is_physical else magic_def
	var resistance = phys_res if is_physical else magic_res
	return (base_defense + defense) * (1 + resistance/100.0) * row_mod

func get_status_duration(status: String) -> int:
	return statuses.get(status, 0)

func has_status(status: String) -> bool:
	return statuses.has(status) and statuses[status] > 0

func clear_all_statuses():
	statuses.clear()
	emit_signal("status_changed", "")

func get_resistance(element: String) -> float:
	return resistances.get(element, 0.0)

func get_party() -> Array:
	# Override in specific character classes
	return []

func equip_item(item: ItemData, slot: String) -> bool:
	if !can_equip(item, slot):
		return false
		
	var current_item = equipment[slot]
	if current_item:
		unequip_item(slot)
	
	equipment[slot] = item
	apply_equipment_stats(item)
	
	# Handle granted abilities
	if item.granted_skill:
		granted_skills.append(item.granted_skill)
		
	if item.granted_passive:
		granted_passives.append(item.granted_passive)
		apply_passive(item.granted_passive)
	
	return true

func unequip_item(slot: String) -> bool:
	var item = equipment[slot]
	if !item:
		return false
		
	remove_equipment_stats(item)
	
	# Remove granted abilities
	if item.granted_skill:
		granted_skills.erase(item.granted_skill)
		
	if item.granted_passive:
		granted_passives.erase(item.granted_passive)
		remove_passive(item.granted_passive)
	
	equipment[slot] = null
	return true

func has_skill(skill_id: String) -> bool:
	return skill_id in skills or skill_id in granted_skills

func has_passive(passive_id: String) -> bool:
	return passive_id in passives or passive_id in granted_passives

func level_up():
	level += 1
	# Grant skill points every 2 levels
	if level % 2 == 0:
		skill_points += 3

func learn_skill(skill_id: String):
	if not skill_id in skills:
		skills.append(skill_id)

func spend_skill_point(path_id: String) -> bool:
	if skill_points <= 0:
		return false
	
	if path_manager.invest_point(path_id):
		skill_points -= 1
		return true
	return false

func _on_skill_learned(skill_id: String):
	learn_skill(skill_id)

func _on_stats_increased(stat_increases: Dictionary):
	for stat in stat_increases:
		base_stats[stat] += stat_increases[stat]
	_recalculate_stats()
