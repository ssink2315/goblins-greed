extends Control

@onready var character_name = $Layout/TopBar/MarginContainer/HBoxContainer/CharacterName
@onready var level_label = $Layout/TopBar/MarginContainer/HBoxContainer/LevelLabel
@onready var exp_bar = $Layout/TopBar/MarginContainer/HBoxContainer/ExpBar

# Left Panel
@onready var stats_panel = $Layout/Content/HSplitContainer/LeftPanel/StatsPanel
@onready var attribute_points = $Layout/Content/HSplitContainer/LeftPanel/AttributePoints

# Right Panel
@onready var skill_points = $Layout/Content/HSplitContainer/RightPanel/SkillPoints/MarginContainer/VBoxContainer/Header/Label
@onready var skill_paths = $Layout/Content/HSplitContainer/RightPanel/SkillPoints/MarginContainer/VBoxContainer/SkillPaths
@onready var learned_skills = $Layout/Content/HSplitContainer/RightPanel/LearnedSkills
@onready var status_effects = $Layout/Content/HSplitContainer/RightPanel/StatusEffects
@onready var resistances = $Layout/Content/HSplitContainer/RightPanel/Resistances
@onready var open_skill_tree_button = $Layout/Content/HSplitContainer/RightPanel/SkillPoints/MarginContainer/VBoxContainer/Header/OpenSkillTreeButton

var current_character: BaseCharacter

func _ready():
    hide()
    _connect_signals()

func _connect_signals():
    for stat_button in stats_panel.get_node("MarginContainer/VBoxContainer/GridContainer/AttributeButtons").get_children():
        stat_button.pressed.connect(_on_stat_button_pressed.bind(stat_button.name))
    
    open_skill_tree_button.pressed.connect(_on_open_skill_tree_pressed)

func show_character_sheet(character: BaseCharacter):
    current_character = character
    # Add fade in animation
    modulate = Color.TRANSPARENT
    refresh_display()
    show()
    create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)

func refresh_display():
    if !current_character:
        return
    
    _update_basic_info()
    _update_stats()
    _update_skill_points()
    _update_status_effects()
    _update_resistances()
    _update_learned_skills()

func _update_basic_info():
    character_name.text = current_character.character_name
    level_label.text = "Level %d" % current_character.level
    
    exp_bar.max_value = current_character.experience_to_next_level
    exp_bar.value = current_character.experience
    exp_bar.tooltip_text = "EXP: %d / %d" % [
        current_character.experience,
        current_character.experience_to_next_level
    ]

func _update_stats():
    var base_stats = current_character.get_base_stats()
    var total_stats = current_character.get_total_stats()
    
    for stat in ["STR", "AGI", "INT", "VIT", "TEC", "WIS"]:
        var label = stats_panel.get_node("MarginContainer/VBoxContainer/GridContainer/Labels/%sLabel" % stat)
        var value = stats_panel.get_node("MarginContainer/VBoxContainer/GridContainer/Values/%sValue" % stat)
        var button = stats_panel.get_node("MarginContainer/VBoxContainer/GridContainer/AttributeButtons/%sButton" % stat)
        
        label.text = stat
        value.text = "%d (+%d)" % [base_stats[stat], total_stats[stat] - base_stats[stat]]
        button.visible = current_character.attribute_points > 0
    
    attribute_points.text = "Available Points: %d" % current_character.attribute_points
    
    # Update derived stats
    var derived_stats = """
    [b]Combat Stats[/b]
    HP: %d/%d
    Mana: %d/%d
    Physical Attack: %d
    Magic Attack: %d
    Physical Defense: %d
    Magic Defense: %d
    
    [b]Secondary Stats[/b]
    Critical Rate: %d%%
    Critical Damage: %d%%
    Evasion: %d%%
    Initiative: %d
    """ % [
        current_character.current_hp, current_character.max_hp,
        current_character.current_mana, current_character.max_mana,
        total_stats.phys_atk, total_stats.magic_atk,
        total_stats.phys_def, total_stats.magic_def,
        total_stats.crit_chance, total_stats.crit_dmg_bonus,
        total_stats.evasion, total_stats.initiative
    ]
    
    stats_panel.get_node("DerivedStats").text = derived_stats

func _update_skill_points():
    skill_points.text = "Skill Points: %d" % current_character.skill_points
    
    var skill_paths_text = "[b]Skill Paths[/b]\n"
    
    # Show Race Path
    var race_path = current_character.path_manager.race_path
    var race_progress = current_character.path_manager.get_path_progress(race_path.path_id)
    skill_paths_text += "\n[u]Race Path[/u]\n"
    skill_paths_text += "%s: Level %d\n" % [race_path.path_name, race_progress]
    
    # Show Class Paths
    skill_paths_text += "\n[u]Class Paths[/u]\n"
    var class_paths = current_character.path_manager.class_paths
    var path1_progress = current_character.path_manager.get_path_progress(class_paths.path_1.path_id)
    var path2_progress = current_character.path_manager.get_path_progress(class_paths.path_2.path_id)
    
    skill_paths_text += "%s: Level %d\n" % [class_paths.path_1.path_name, path1_progress]
    skill_paths_text += "%s: Level %d\n" % [class_paths.path_2.path_name, path2_progress]
    
    # Show next rewards
    skill_paths_text += "\n[u]Next Rewards[/u]\n"
    for path in [race_path, class_paths.path_1, class_paths.path_2]:
        var next_reward = current_character.path_manager.get_next_reward_at(path.path_id)
        skill_paths_text += "%s: %s at level %d\n" % [
            path.path_name,
            _format_reward_type(next_reward.type),
            next_reward.points
        ]
    
    skill_paths.text = skill_paths_text

func _format_reward_type(type: String) -> String:
    match type:
        "major_skill": return "Major Talent Skill"
        "minor_skill": return "Minor Talent Skill"
        "stats": return "Stat Boost"
        _: return "Unknown"

func _update_status_effects():
    var effects_text = "[b]Status Effects[/b]\n"
    
    if current_character.status_effects.is_empty():
        effects_text += "None"
    else:
        for effect in current_character.status_effects:
            effects_text += "%s (%d turns)\n" % [effect.effect_name, effect.duration]
    
    status_effects.text = effects_text

func _update_resistances():
    var res_text = "[b]Resistances[/b]\n"
    
    for element in current_character.resistances:
        var value = current_character.resistances[element]
        if value != 0:
            res_text += "%s: %d%%\n" % [element, value]
    
    resistances.text = res_text

func _update_learned_skills():
    var skills_text = "[b]Learned Skills[/b]\n"
    
    # Group skills by path
    var skills_by_path = {}
    for path in [
        current_character.path_manager.race_path,
        current_character.path_manager.class_paths.path_1,
        current_character.path_manager.class_paths.path_2
    ]:
        skills_by_path[path.path_name] = []
        skills_by_path[path.path_name].append_array(
            current_character.path_manager.learned_major_skills.get(path.path_id, [])
        )
        skills_by_path[path.path_name].append_array(
            current_character.path_manager.learned_minor_skills.get(path.path_id, [])
        )
    
    # Display skills grouped by path
    for path_name in skills_by_path:
        if skills_by_path[path_name].size() > 0:
            skills_text += "\n[u]%s[/u]\n" % path_name
            for skill_id in skills_by_path[path_name]:
                var skill = GameDatabase.get_skill(skill_id)
                if skill:
                    skills_text += "- %s\n" % skill.skill_name
    
    learned_skills.text = skills_text

func _on_stat_button_pressed(stat: String):
    if current_character and current_character.attribute_points > 0:
        if current_character.spend_attribute_point(stat):
            refresh_display()

func _on_open_skill_tree_pressed():
    if current_character:
        # Add fade out animation
        var tween = create_tween()
        tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
        tween.tween_callback(func():
            hide()
            var skill_tree = preload("res://Scenes/UI/SkillTreeUI.tscn").instantiate()
            get_parent().add_child(skill_tree)
            skill_tree.show_skill_tree(current_character)
            skill_tree.tree_exited.connect(func():
                modulate = Color.TRANSPARENT
                show()
                create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
            )
        ) 