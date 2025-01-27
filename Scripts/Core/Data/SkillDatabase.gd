extends Node

# Skill resources organized by class/race and path
var skills: Dictionary = {}
var skill_paths: Dictionary = {}

const MAX_RECURSION_DEPTH = 5  # Limit for directory recursion depth

func _ready():
    _load_all_skills()

func _load_all_skills():
    # Load all skill resources from the Resources/Skills directory
    var dir = DirAccess.open("res://Resources/Skills")
    if dir:
        _scan_skill_directory(dir, "res://Resources/Skills", 0)

func _scan_skill_directory(dir: DirAccess, path: String, depth: int):
    if depth > MAX_RECURSION_DEPTH:
        push_error("Maximum recursion depth reached while scanning directory: " + path)
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if dir.current_is_dir() and file_name != "." and file_name != "..":
            var subdir = DirAccess.open(path + "/" + file_name)
            if subdir:
                _scan_skill_directory(subdir, path + "/" + file_name, depth + 1)
        elif file_name.ends_with(".tres"):
            var skill = load(path + "/" + file_name) as SkillData
            if skill:
                if _validate_skill(skill):
                    _register_skill(skill, path.split("/")[-1])
                else:
                    push_error("Invalid skill data in file: " + file_name)
        file_name = dir.get_next()
    
    dir.list_dir_end()

func _register_skill(skill: SkillData, category: String):
    if !skills.has(category):
        skills[category] = {}
    
    skills[category][skill.skill_name] = skill
    
    # Register the skill to its path
    if !skill_paths.has(skill.path):
        skill_paths[skill.path] = []
    skill_paths[skill.path].append(skill)

# Get a specific skill by name and category
func get_skill(skill_name: String, category: String) -> SkillData:
    if skills.has(category) and skills[category].has(skill_name):
        return skills[category][skill_name]
    return null

# Validate skill data to ensure all required attributes are present
func _validate_skill(skill: SkillData) -> bool:
    if skill.skill_name == "" or skill.description == "":
        return false
    if skill.skill_type not in ["active", "passive", "buff"]:
        return false
    if skill.damage_type == null or skill.element == null:
        return false
    if skill.effects.size() == 0:
        return false
    return true

# Get all skills for a specific path
func get_path_skills(path_name: String) -> Array[SkillData]:
    if skill_paths.has(path_name):
        return skill_paths[path_name]
    return []

# Get random skill from a path's major talents
func get_random_major_talent(path_name: String) -> SkillData:
    var path_skills = get_path_skills(path_name)
    var major_talents = path_skills.filter(func(skill): return skill.is_major_talent())
    
    if major_talents.is_empty():
        return null
    
    return major_talents[randi() % major_talents.size()]

# Get random skill from a path's minor talents
func get_random_minor_talent(path_name: String) -> SkillData:
    var path_skills = get_path_skills(path_name)
    var minor_talents = path_skills.filter(func(skill): return !skill.is_major_talent())
    
    if minor_talents.is_empty():
        return null
    
    return minor_talents[randi() % minor_talents.size()]

# Get all skills for a specific character based on their paths
func get_available_skills_for_character(character: BaseCharacter) -> Array[SkillData]:
    var available_skills: Array[SkillData] = []
    
    # Get racial path skills
    var racial_paths = PathData.get_paths_for_race(character.race)
    for path in racial_paths:
        available_skills.append_array(get_path_skills(path))
    
    # Get class path skills
    var class_paths = PathData.get_paths_for_class(character.class_type)
    for path in class_paths:
        available_skills.append_array(get_path_skills(path))
    
    return available_skills

# Helper function to get all skills that match certain criteria
func get_skills_by_criteria(criteria: Dictionary) -> Array[SkillData]:
    var matching_skills: Array[SkillData] = []
    
    for category in skills.values():
        for skill in category.values():
            var matches = true
            for key in criteria:
                if skill.get(key) != criteria[key]:
                    matches = false
                    break
            if matches:
                matching_skills.append(skill)
    
    return matching_skills

# Get all skills of a specific element
func get_skills_by_element(element: SkillData.Element) -> Array[SkillData]:
    return get_skills_by_criteria({"element": element})

# Get all skills of a specific type
func get_skills_by_type(type: SkillData.SkillType) -> Array[SkillData]:
    return get_skills_by_criteria({"skill_type": type})

# Get all passive skills
func get_passive_skills() -> Array[SkillData]:
    return get_skills_by_type(SkillData.SkillType.PASSIVE)

# Get all buff skills
func get_buff_skills() -> Array[SkillData]:
    return get_skills_by_type(SkillData.SkillType.BUFF)

# Get all active combat skills
func get_active_skills() -> Array[SkillData]:
    return get_skills_by_type(SkillData.SkillType.ACTIVE) 