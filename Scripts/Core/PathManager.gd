extends Node
class_name PathManager

signal path_level_up(path_id: String, level: int)
signal skill_learned(skill_id: String)
signal stats_increased(stat_increases: Dictionary)

var path_progress: Dictionary = {}  # path_id -> points invested
var available_paths: Array[PathData] = []
var class_paths: ClassPathsData
var race_path: PathData

# Track which skills have been learned from each talent pool
var learned_major_skills: Dictionary = {}  # path_id -> Array[String]
var learned_minor_skills: Dictionary = {}  # path_id -> Array[String]

var stat_increase_value: int = 10  # Exposed as a configurable property

func initialize(class_paths_data: ClassPathsData, race_path_data: PathData):
    class_paths = class_paths_data
    race_path = race_path_data
    
    # Initialize available paths
    available_paths = class_paths.paths + [race_path]  # Use the paths array from ClassPathsData
    
    # Initialize progress tracking
    for path in available_paths:
        path_progress[path.path_id] = 0
        learned_major_skills[path.path_id] = []
        learned_minor_skills[path.path_id] = []

func invest_point(path_id: String) -> bool:
    var path = _get_path_by_id(path_id)
    if not path:
        return false
    
    var current_points = path_progress[path_id]
    path_progress[path_id] += 1
    
    # Check for rewards
    _check_rewards(path, current_points + 1)
    
    emit_signal("path_level_up", path_id, current_points + 1)
    return true

func _check_rewards(path: PathData, points: int):
    # Initial major talent skill (2 points)
    if points == 2:
        _grant_random_major_skill(path)
    
    # Stat increases (every 4 points)
    if points % 4 == 0:
        _grant_stat_increase(path)
    
    # Major talent skill (every 5 points)
    if points % 5 == 0:
        _grant_random_major_skill(path)
    
    # Minor talent skill (every 8 points)
    if points % 8 == 0:
        _grant_random_minor_skill(path)

func _grant_random_major_skill(path: PathData):
    var available_skills = []
    for skill_id in path.major_talent_pool:
        if not skill_id in learned_major_skills[path.path_id]:
            available_skills.append(skill_id)
    
    if available_skills.size() > 0:
        var skill_id = available_skills[randi() % available_skills.size()]
        learned_major_skills[path.path_id].append(skill_id)
        emit_signal("skill_learned", skill_id)
    else:
        # If no skills available, grant random stat increase
        _grant_random_stat()

func _grant_random_minor_skill(path: PathData):
    var available_skills = []
    for skill_id in path.minor_talent_pool:
        if not skill_id in learned_minor_skills[path.path_id]:
            available_skills.append(skill_id)
    
    if available_skills.size() > 0:
        var skill_id = available_skills[randi() % available_skills.size()]
        learned_minor_skills[path.path_id].append(skill_id)
        emit_signal("skill_learned", skill_id)
    else:
        # If no skills available, grant random stat increase
        _grant_random_stat()

func _grant_stat_increase(path: PathData):
    var stat_increase = {random_stat: stat_increase_value}
    emit_signal("stats_increased", stat_increase)

func _grant_random_stat():
    var stats = ["STR", "AGI", "VIT", "INT", "WIS", "TEC"]
    var random_stat = stats[randi() % stats.size()]
    var stat_increase = {random_stat: stat_increase_value}
    emit_signal("stats_increased", stat_increase)

func _get_path_by_id(path_id: String) -> PathData:
    for path in available_paths:
        if path.path_id == path_id:
            return path
    return null

func get_path_progress(path_id: String) -> int:
    return path_progress.get(path_id, 0)

func get_next_reward_at(path_id: String) -> Dictionary:
    var current_points = get_path_progress(path_id)
    var next_points = current_points + 1
    
    # Check upcoming milestones
    if next_points == 2:
        return {"type": "major_skill", "points": 2}
    if next_points % 4 == 0:
        return {"type": "stats", "points": next_points}
    if next_points % 5 == 0:
        return {"type": "major_skill", "points": next_points}
    if next_points % 8 == 0:
        return {"type": "minor_skill", "points": next_points}
    
    # Calculate distance to next milestone
    var to_next_major = 5 - (next_points % 5)
    var to_next_minor = 8 - (next_points % 8)
    var to_next_stats = 4 - (next_points % 4)
    
    var closest = min(to_next_major, min(to_next_minor, to_next_stats))
    if closest == to_next_major:
        return {"type": "major_skill", "points": next_points + to_next_major}
    elif closest == to_next_minor:
        return {"type": "minor_skill", "points": next_points + to_next_minor}
    else:
        return {"type": "stats", "points": next_points + to_next_stats}

func save_progress() -> Dictionary:
    return {
        "path_progress": path_progress,
        "learned_major_skills": learned_major_skills,
        "learned_minor_skills": learned_minor_skills
    }

func load_progress(data: Dictionary):
    path_progress = data.get("path_progress", {})
    learned_major_skills = data.get("learned_major_skills", {})
    learned_minor_skills = data.get("learned_minor_skills", {})

# Ensure listeners are connected before emitting signals
func _emit_signal(signal_name: String, *args):
    if is_connected(signal_name, self):
        emit_signal(signal_name, *args)

func _check_rewards_and_emit(path: PathData, points: int):
    _check_rewards(path, points)
    _emit_signal("path_level_up", path.path_id, points)
    _emit_signal("skill_learned", path.path_id)
    _emit_signal("stats_increased", path.stat_distribution) 