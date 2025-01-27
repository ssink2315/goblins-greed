extends Control

signal skill_point_spent(path: String)
signal skill_learned(skill_data: SkillData)

# Top section
@onready var available_points = $TopBar/AvailablePoints
@onready var character_name = $TopBar/CharacterName
@onready var path_type_tabs = $TopBar/PathTypeTabs
@onready var back_button = $TopBar/BackButton

# Main visual section
@onready var path_container = $MainContent/PathContainer
@onready var skill_details = $MainContent/DetailsPanel/SkillDetails

var current_character: BaseCharacter
var path_panels: Dictionary = {}
var current_path_type: String = "Race"  # "Race" or "Class"

func _ready():
    hide()
    _connect_signals()

func _connect_signals():
    path_type_tabs.tab_changed.connect(_on_tab_changed)
    back_button.pressed.connect(_on_back_pressed)

func show_skill_tree(character: BaseCharacter):
    current_character = character
    # Fade in animation
    modulate = Color.TRANSPARENT
    refresh_display()
    show()
    create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)

func _on_back_pressed():
    # Fade out animation
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
    tween.tween_callback(queue_free)

func refresh_display():
    if !current_character:
        return
    
    character_name.text = current_character.character_name
    available_points.text = "Available Skill Points: %d" % current_character.skill_points
    
    _clear_path_panels()
    _create_path_panels()

func _clear_path_panels():
    for panel in path_panels.values():
        panel.queue_free()
    path_panels.clear()

func _create_path_panels():
    var paths: Array[PathData]
    if current_path_type == "Race":
        paths = [current_character.path_manager.race_path]
    else:
        paths = [
            current_character.path_manager.class_paths.path_1,
            current_character.path_manager.class_paths.path_2
        ]
    
    for path in paths:
        var panel = _create_path_panel(path)
        path_container.add_child(panel)
        path_panels[path.path_id] = panel

func _create_path_panel(path: PathData) -> PanelContainer:
    var panel = PanelContainer.new()
    var vbox = VBoxContainer.new()
    panel.add_child(vbox)
    
    # Path header with name and level
    var header = HBoxContainer.new()
    var path_label = Label.new()
    path_label.text = path.path_name
    header.add_child(path_label)
    
    var current_level = current_character.path_manager.get_path_progress(path.path_id)
    var level_label = Label.new()
    level_label.text = "Level %d" % current_level
    header.add_child(level_label)
    
    # Next reward info
    var next_reward = current_character.path_manager.get_next_reward_at(path.path_id)
    var reward_label = Label.new()
    reward_label.text = "Next reward at level %d: %s" % [
        next_reward.points,
        _format_reward_type(next_reward.type)
    ]
    
    # Progress bars
    var progress_container = VBoxContainer.new()
    
    var major_progress = _create_milestone_bar(
        "Major Talent", 
        current_level % 5,
        5
    )
    
    var minor_progress = _create_milestone_bar(
        "Minor Talent", 
        current_level % 8,
        8
    )
    
    var stat_progress = _create_milestone_bar(
        "Stat Boost", 
        current_level % 4,
        4
    )
    
    progress_container.add_child(major_progress)
    progress_container.add_child(minor_progress)
    progress_container.add_child(stat_progress)
    
    # Invest button
    var invest_button = Button.new()
    invest_button.text = "Invest Point"
    invest_button.disabled = current_character.skill_points <= 0
    invest_button.pressed.connect(_on_invest_pressed.bind(path.path_id))
    
    # Add all elements to the panel
    vbox.add_child(header)
    vbox.add_child(reward_label)
    vbox.add_child(progress_container)
    vbox.add_child(invest_button)
    
    # Add unlocked skills grid
    var skills_container = GridContainer.new()
    skills_container.columns = 4
    
    var learned_skills = []
    learned_skills.append_array(current_character.path_manager.learned_major_skills.get(path.path_id, []))
    learned_skills.append_array(current_character.path_manager.learned_minor_skills.get(path.path_id, []))
    
    for skill_id in learned_skills:
        var skill = GameDatabase.get_skill(skill_id)
        if skill:
            var skill_button = TextureButton.new()
            skill_button.custom_minimum_size = Vector2(48, 48)
            skill_button.texture_normal = skill.icon
            skill_button.tooltip_text = skill.skill_name
            skill_button.mouse_entered.connect(_on_skill_hover.bind(skill))
            skills_container.add_child(skill_button)
    
    vbox.add_child(skills_container)
    
    return panel

func _create_milestone_bar(label_text: String, current: int, max_value: int) -> HBoxContainer:
    var container = HBoxContainer.new()
    
    var label = Label.new()
    label.text = label_text
    container.add_child(label)
    
    var progress = ProgressBar.new()
    progress.max_value = max_value
    progress.value = current
    progress.custom_minimum_size.x = 100
    container.add_child(progress)
    
    return container

func _format_reward_type(type: String) -> String:
    match type: 
        "major_skill": return "Major Talent Skill"
        "minor_skill": return "Minor Talent Skill"
        "stats": return "Stat Boost"
        _: return "Unknown"

func _on_tab_changed(tab: int):
    current_path_type = "Race" if tab == 0 else "Class"
    refresh_display()

func _on_invest_pressed(path_id: String):
    if current_character.spend_skill_point(path_id):
        skill_point_spent.emit(path_id)
        refresh_display()

func _on_skill_hover(skill: SkillData):
    var info = skill.get_skill_info()
    skill_details.text = """
    [b]%s[/b]
    Type: %s
    Path: %s
    Mana Cost: %d
    
    %s
    """ % [
        info.name,
        info.type,
        info.path,
        info.mana_cost,
        skill.description
    ] 