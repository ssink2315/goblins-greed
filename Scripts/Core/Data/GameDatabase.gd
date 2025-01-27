extends Node

# Singleton instance
var races: Dictionary = {}
var classes: Dictionary = {}
var skills: Dictionary = {}
var items: Dictionary = {}

# Constants for stat calculations
const BASE_HP_MULTIPLIER = 2
const BASE_MANA_MULTIPLIER = 1.5
const CRIT_BASE_MULTIPLIER = 1.5

func _ready():
	load_game_data()

func load_game_data():
	load_races()
	load_classes()
	load_skills()
	load_items()

func load_races():
	var dir = Directory.new()
	if dir.open("res://Resources/Database/Races/") == OK:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".tres") and file != "." and file != "..":
				var race_data = load("res://Resources/Database/Races/" + file) as RaceData
				races[race_data.race_name] = race_data
			file = dir.get_next()
		dir.close()

func load_classes():
	var class_files = DirAccess.get_files_at("res://Resources/Database/Classes/")
	for file in class_files:
		if file.ends_with(".tres"):
			var class_data = load("res://Resources/Database/Classes/" + file) as ClassData
			classes[class_data.class_name] = class_data

func load_skills():
	var skill_files = DirAccess.get_files_at("res://Resources/Database/Skills/")
	for file in skill_files:
		if file.ends_with(".tres"):
			var skill_data = load("res://Resources/Database/Skills/" + file) as SkillData
			skills[skill_data.skill_name] = skill_data

func load_items():
	var item_files = DirAccess.get_files_at("res://Resources/Database/Items/")
	for file in item_files:
		if file.ends_with(".tres"):
			var item_data = load("res://Resources/Database/Items/" + file) as ItemData
			items[item_data.item_name] = item_data

# Utility functions for stat calculations
func calculate_base_hp(vit: int) -> int:
	return vit * BASE_HP_MULTIPLIER

func calculate_base_mana(int: int, wis: int) -> int:
	return int + (wis * BASE_MANA_MULTIPLIER)

func get_race_data(race_name: String) -> RaceData:
	return races.get(race_name)

func get_class_data(class_name: String) -> ClassData:
	return classes.get(class_name)
