extends Control

signal action_selected(action: String, target: BaseCharacter)
signal skill_selected(skill: Skill)
signal summon_action_completed(result: Dictionary)
signal summon_result_received(result: Dictionary)
signal summon_expired(summon: BaseCharacter)
signal summon_failed(summoner: BaseCharacter, message: String)

@onready var turn_order = $Layout/TopBar/MarginContainer/HBoxContainer/TurnOrderDisplay
@onready var action_buttons = $Layout/Content/BattleLayout/ActionPanel/MarginContainer/VBoxContainer/ActionButtons
@onready var sub_action_panel = $Layout/Content/BattleLayout/ActionPanel/MarginContainer/VBoxContainer/SubActionPanel
@onready var sub_actions_grid = $Layout/Content/BattleLayout/ActionPanel/MarginContainer/VBoxContainer/SubActionPanel/ScrollContainer/GridContainer
@onready var target_selector = $Layout/Content/BattleLayout/BattlefieldView/TargetSelector
@onready var combat_log = $"../CombatLog"
@onready var rewards_panel = $Layout/RewardsPanel
@onready var level_up_panel = $Layout/LevelUpPanel
@onready var effects_container = $Layout/EffectsContainer

var current_character: BaseCharacter
var selected_action: String
var targeting_active: bool = false
var selected_skill: Skill
var selected_item: Item

# Add animation constants
const FADE_DURATION := 0.3
const SLIDE_DURATION := 0.2
const BOUNCE_STRENGTH := 1.2
const SHAKE_STRENGTH := 5.0

# Add UI effect nodes
@onready var tween_manager: Node = $TweenManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var transition_overlay: ColorRect = $TransitionOverlay

# Add particle system constants
const PARTICLE_SCENES = {
	"hit": preload("res://Scenes/Effects/HitParticles.tscn"),
	"heal": preload("res://Scenes/Effects/HealParticles.tscn"),
	"status": preload("res://Scenes/Effects/StatusParticles.tscn"),
	"critical": preload("res://Scenes/Effects/CriticalParticles.tscn"),
	"level_up": preload("res://Scenes/Effects/LevelUpParticles.tscn")
}

const PARTICLE_COLORS = {
	"physical": Color(1.0, 0.3, 0.3),  # Red
	"magical": Color(0.3, 0.3, 1.0),   # Blue
	"heal": Color(0.3, 1.0, 0.3),      # Green
	"critical": Color(1.0, 0.8, 0.0),  # Gold
	"buff": Color(0.0, 1.0, 1.0),      # Cyan
	"debuff": Color(0.8, 0.0, 0.8)     # Purple
}

# Add UI enhancement constants
const MESSAGE_FADE_DURATION := 0.5
const ACTION_BUTTON_HOVER_SCALE := 1.1
const TURN_INDICATOR_SIZE := Vector2(48, 48)

func _ready():
	_setup_action_buttons()
	hide_target_selector()
	sub_action_panel.hide()
	rewards_panel.hide()
	level_up_panel.hide()
	
	# Initialize UI effects
	flash_overlay.modulate.a = 0
	transition_overlay.modulate.a = 0
	
	# Setup initial animations
	_setup_ui_animations()
	
	# Connect to CombatManager signals
	var combat_manager = get_node("../CombatManager")
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.combat_state_changed.connect(_on_combat_state_changed)
	combat_manager.action_performed.connect(_on_action_performed)
	combat_manager.damage_dealt.connect(_on_damage_dealt)
	combat_manager.status_effect_applied.connect(_on_status_effect_applied)
	combat_manager.status_effect_removed.connect(_on_status_effect_removed)
	combat_manager.row_changed.connect(_on_row_changed)
	combat_manager.rewards_ready.connect(_on_rewards_ready)
	combat_manager.level_up.connect(_on_level_up)

func _setup_action_buttons():
	var action_button = preload("res://Scenes/UI/Components/ActionButton.tscn")
	
	for action in ["Attack", "Skills", "Items", "Defend"]:
		var button = action_button.instantiate()
		action_buttons.add_child(button)
		button.setup({
			"name": action,
			"keybind": _get_action_keybind(action)
		})
		button.pressed.connect(_on_action_button_pressed.bind(action))

func update_turn_order(characters: Array[BaseCharacter]):
	turn_order.update_turn_order(characters)

func set_active_character(character: BaseCharacter):
	current_character = character
	_update_available_actions()
	sub_action_panel.hide()
	hide_target_selector()

func show_action_result(result: Dictionary):
	var source = result.source
	var target = result.target
	var action_result = result.result
	
	match action_result.type:
		"damage":
			combat_log.add_damage_message(
				source.character_name,
				target.character_name,
				action_result.amount,
				action_result.is_critical
			)
			_show_damage_number(target, action_result.amount, "critical" if action_result.is_critical else "")
			_spawn_particles("hit", target.global_position, {
				"color": PARTICLE_COLORS.physical if source.is_physical else PARTICLE_COLORS.magical,
				"amount": 10,
				"lifetime": 0.5
			})
			if action_result.is_critical:
				_spawn_particles("critical", target.global_position, {
					"color": PARTICLE_COLORS.critical,
					"amount": 15,
					"lifetime": 0.7
				})
			
		"heal":
			combat_log.add_heal_message(
				source.character_name,
				target.character_name,
				action_result.amount
			)
			_show_damage_number(target, action_result.amount, "heal")
			_spawn_particles("heal", target.global_position, {
				"color": PARTICLE_COLORS.heal,
				"amount": 8,
				"lifetime": 0.6
			})
			
		"status":
			combat_log.add_status_message(
				target.character_name,
				action_result.status_name,
				action_result.is_applied
			)
			var color = PARTICLE_COLORS.buff if action_result.is_buff else PARTICLE_COLORS.debuff
			_spawn_particles("status", target.global_position, {
				"color": color,
				"amount": 6,
				"lifetime": 0.4
			})
			
		"skill":
			combat_log.add_skill_message(
				source.character_name,
				action_result.skill_name,
				target.character_name
			)
			
		"summon":
			if action_result.success:
				combat_log.add_summon_message(
					source.character_name,
					action_result.summon.character_name,
					true,
					""
				)
				_show_summon_effect(action_result.summon)
			else:
				combat_log.add_summon_message(
					source.character_name,
					"",
					false,
					action_result.message
				)

func _show_damage_number(target: BaseCharacter, amount: int, type: String = ""):
	var damage_text = preload("res://Scenes/Combat/DamageText.tscn").instantiate()
	add_child(damage_text)
	damage_text.global_position = target.global_position + Vector2(0, -50)
	
	var color = Color.WHITE
	match type:
		"critical": color = Color.YELLOW
		"heal": color = Color.GREEN
		"miss": color = Color.GRAY
	
	damage_text.display(str(amount), color)

func show_skill_selection(skills: Array):
	sub_action_panel.show()
	for skill in skills:
		var button = skill_button_scene.instantiate()
		sub_actions_grid.add_child(button)
		button.setup(skill)
		button.pressed.connect(_on_skill_button_pressed.bind(skill))

func show_target_selector(valid_targets: Array[BaseCharacter]):
	targeting_active = true
	target_selector.start_selection(valid_targets)

func hide_target_selector():
	targeting_active = false
	target_selector.hide()

func _on_action_button_pressed(action: String):
	selected_action = action
	
	match action:
		"Attack":
			show_target_selector(get_node("../CombatManager").get_valid_targets(
				current_character, 
				CombatEnums.ActionType.ATTACK
			))
		"Skills":
			show_skill_selection(current_character.learned_skills)
		"Items":
			show_item_selection()
		"Defend":
			var action_data = {
				"type": "defend",
				"source": current_character,
				"target": current_character
			}
			get_node("../CombatManager").handle_action(action_data)

func _on_skill_button_pressed(skill: Skill):
	sub_action_panel.hide()
	skill_selected.emit(skill)

func _on_target_selected(target: BaseCharacter):
	var action_data = {
		"source": current_character,
		"target": target
	}
	
	match selected_action:
		"Attack":
			action_data["type"] = "attack"
		"skill":
			action_data["type"] = "skill"
			action_data["skill"] = selected_skill
		"item":
			action_data["type"] = "item"
			action_data["item"] = selected_item
	
	get_node("../CombatManager").handle_action(action_data)
	hide_target_selector()
	sub_action_panel.hide()

func _update_available_actions():
	for button in action_buttons.get_children():
		button.disabled = !_is_action_available(button.action_data.name)

func _is_action_available(action: String) -> bool:
	match action:
		"Attack": return true
		"Skills": return current_character.has_usable_skills()
		"Items": return current_character.has_usable_items()
		"Defend": return true
	return false

func _get_action_keybind(action: String) -> String:
	return "F" + str(action_buttons.get_child_count() + 1)

func _clear_sub_actions():
	for child in sub_actions_grid.get_children():
		child.queue_free()

func _on_turn_started(unit: BaseCharacter):
	combat_log.add_turn_message(unit)
	set_active_character(unit)

func _on_combat_state_changed(new_state: int):
	match new_state:
		CombatEnums.CombatState.PLAYER_TURN:
			enable_action_buttons()
		CombatEnums.CombatState.ENEMY_TURN, CombatEnums.CombatState.ANIMATING:
			disable_action_buttons()

func _on_action_performed(action: String, target: BaseCharacter):
	action_selected.emit(action, target)
	hide_target_selector()
	sub_action_panel.hide()

func _on_damage_dealt(source: BaseCharacter, target: BaseCharacter, amount: int, is_critical: bool):
	show_action_result({
		"source": source,
		"target": target,
		"result": {
			"type": "damage",
			"amount": amount,
			"is_critical": is_critical
		}
	})

func _on_status_effect_applied(target: BaseCharacter, status_name: String, is_applied: bool):
	show_action_result({
		"source": current_character,
		"target": target,
		"result": {
			"type": "status",
			"status_name": status_name,
			"is_applied": is_applied
		}
	})

func _on_status_effect_removed(target: BaseCharacter, status_name: String):
	show_action_result({
		"source": current_character,
		"target": target,
		"result": {
			"type": "status",
			"status_name": status_name,
			"is_applied": false
		}
	})

func enable_action_buttons():
	for button in action_buttons.get_children():
		button.disabled = false

func disable_action_buttons():
	for button in action_buttons.get_children():
		button.disabled = true

func _on_row_changed(unit: BaseCharacter, new_row: int):
	# Update any UI elements that show unit positions
	var row_name = "front" if new_row == CombatEnums.Row.FRONT else "back"
	combat_log.add_message("%s moved to %s row" % [unit.character_name, row_name])

func show_item_selection():
	# TODO: Implement item selection logic
	pass

func show_rewards_screen(exp: int, gold: int, drops: Array):
	rewards_panel.show()
	rewards_panel.display_rewards(exp, gold, drops)
	
	# Add to combat log
	combat_log.add_message("Combat Victory!", Color.GREEN, true)
	combat_log.add_message("Gained %d EXP" % exp, Color.YELLOW)
	combat_log.add_message("Found %d Gold" % gold, Color.YELLOW)
	
	if drops.size() > 0:
		combat_log.add_message("Items obtained:", Color.YELLOW)
		for drop in drops:
			var item_name = GameDatabase.get_item_name(drop.item_id)
			combat_log.add_message("- %s x%d" % [item_name, drop.quantity], Color.YELLOW)

func show_level_up(character: BaseCharacter, new_level: int, stat_increases: Dictionary):
	level_up_panel.show()
	level_up_panel.display_level_up(character, new_level, stat_increases)
	
	# Add to combat log
	combat_log.add_message(
		"%s reached level %d!" % [character.character_name, new_level],
		Color.AQUA,
		true
	)
	
	# Show stat increases
	var stat_text = "Stat increases: "
	for stat in stat_increases:
		stat_text += "%s +%d " % [stat, stat_increases[stat]]
	combat_log.add_message(stat_text, Color.AQUA)
	
	# Add level up particles
	_spawn_particles("level_up", character.global_position, {
		"color": PARTICLE_COLORS.buff,
		"amount": 20,
		"lifetime": 1.0
	})

func _on_rewards_ready(exp: int, gold: int, drops: Array):
	show_rewards_screen(exp, gold, drops)

func _on_level_up(character: BaseCharacter, new_level: int, stat_increases: Dictionary):
	show_level_up(character, new_level, stat_increases)

func _on_rewards_confirmed():
	rewards_panel.hide()
	get_node("../CombatManager").distribute_rewards()

func _show_status_effect(target: BaseCharacter, effect: StatusEffect):
	var status_icon = preload("res://Scenes/UI/Components/StatusEffectIcon.tscn").instantiate()
	target.status_container.add_child(status_icon)
	status_icon.setup(effect)
	
	# Optional: Add floating status text
	var status_text = preload("res://Scenes/Combat/DamageText.tscn").instantiate()
	add_child(status_text)
	status_text.global_position = target.global_position + Vector2(0, -30)
	
	var color = Color.RED if effect.effect_type == StatusEffect.EffectType.DEBUFF else Color.GREEN
	status_text.display(effect.effect_name, color)

func update_unit_displays():
	for unit in get_node("../CombatManager").player_party + get_node("../CombatManager").enemy_party:
		if is_instance_valid(unit):
			unit.update_status_icons()
			unit.update_hp_bar()
			unit.update_mp_bar()

func show_summon_result(result: Dictionary):
	if result.success:
		combat_log.add_message("%s summoned %s!" % [
			result.source.character_name,
			result.summon.character_name
		])
		_show_summon_effect(result.summon)
		summon_action_completed.emit(result)
	else:
		combat_log.add_message("Failed to summon: %s" % result.message)
		_show_failure_effect(result.source.global_position)

func _show_summon_effect(summon: BaseCharacter):
	var effect = summon_effect_scene.instantiate()
	effect.global_position = summon.global_position
	effects_container.add_child(effect)
	effect.play()

func _show_failure_effect(position: Vector2):
	var effect = failure_effect_scene.instantiate()
	effect.global_position = position
	effects_container.add_child(effect)
	effect.play()

func _on_summon_result(result: Dictionary):
	show_summon_result(result)
	summon_result_received.emit(result)

func update_summon_state(summon: BaseCharacter, state: Dictionary):
	# Update duration display if applicable
	if state.turns_remaining > 0:
		update_summon_duration(summon, state.turns_remaining)
	
	# Update effect icons
	for effect in state.effects:
		_show_status_effect(summon, effect)
	
	# Update link indicator if summoner exists
	if state.summoner:
		_update_summon_link_indicator(summon, state.summoner)

func show_summon_effect_applied(summon: BaseCharacter, effect: Dictionary):
	_show_status_effect(summon, effect)
	combat_log.add_message("%s gained effect: %s" % [
		summon.character_name,
		effect.name
	])

func _update_summon_link_indicator(summon: BaseCharacter, summoner: BaseCharacter):
	if not is_instance_valid(summon) or not is_instance_valid(summoner):
		return
		
	var link_effect = preload("res://Scenes/Effects/SummonLinkEffect.tscn").instantiate()
	summon.add_child(link_effect)
	link_effect.connect_to(summoner)

func _setup_ui_animations():
	# Setup button animations
	for button in action_buttons.get_children():
		_setup_button_effects(button)
	
	# Setup turn order display
	_setup_turn_order_display()
	
	# Setup combat log
	_setup_combat_log()

func _setup_button_effects(button: Button):
	# Add hover effect
	button.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2.ONE * ACTION_BUTTON_HOVER_SCALE, 0.1)
		button.modulate = Color(1.1, 1.1, 1.2)  # Slight glow
	)
	
	# Add unhover effect
	button.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.1)
		button.modulate = Color.WHITE
	)
	
	# Add click effect
	button.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2.ONE * 0.9, 0.05)
	)
	
	button.button_up.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.05)
	)

func _setup_turn_order_display():
	# Add background and border
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_all = 2
	style.border_color = Color(0.5, 0.5, 0.5)
	style.corner_radius_all = 5
	turn_order.add_theme_stylebox_override("panel", style)
	
	# Set fixed size for turn indicators
	for child in turn_order.get_node("TurnOrder").get_children():
		child.custom_minimum_size = TURN_INDICATOR_SIZE

func _setup_combat_log():
	# Add background for better readability
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.border_width_all = 1
	style.border_color = Color(0.3, 0.3, 0.3)
	style.corner_radius_all = 5
	combat_log.add_theme_stylebox_override("panel", style)
	
	# Add message fade effect
	combat_log.message_added.connect(_on_combat_log_message_added)

func _on_combat_log_message_added(message_node: Control):
	message_node.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(message_node, "modulate:a", 1.0, MESSAGE_FADE_DURATION)

func show_combat_transition():
	var tween = create_tween()
	transition_overlay.modulate.a = 1
	tween.tween_property(transition_overlay, "modulate:a", 0, FADE_DURATION)
	await tween.finished

func _animate_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * BOUNCE_STRENGTH, 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)

func _animate_button_normal(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)

func show_damage_number(value: int, position: Vector2, is_critical: bool = false):
	var damage_label = Label.new()
	effects_container.add_child(damage_label)
	damage_label.text = str(value)
	damage_label.position = position
	
	var tween = create_tween()
	if is_critical:
		damage_label.scale = Vector2.ONE * 1.5
		damage_label.modulate = Color.YELLOW
	
	tween.tween_property(damage_label, "position:y", position.y - 50, 0.5)
	tween.parallel().tween_property(damage_label, "modulate:a", 0, 0.5)
	await tween.finished
	damage_label.queue_free()

func shake_screen(duration: float = 0.2):
	var tween = create_tween()
	var initial_pos = self.position
	
	for i in range(5):
		var offset = Vector2(
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH),
			randf_range(-SHAKE_STRENGTH, SHAKE_STRENGTH)
		)
		tween.tween_property(self, "position", initial_pos + offset, duration / 5)
	
	tween.tween_property(self, "position", initial_pos, duration / 5)

func flash_screen(color: Color = Color.WHITE, duration: float = 0.2):
	flash_overlay.modulate = color
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.5, duration / 2)
	tween.tween_property(flash_overlay, "modulate:a", 0, duration / 2)

func _spawn_particles(type: String, position: Vector2, params: Dictionary = {}):
	if not PARTICLE_SCENES.has(type):
		return
		
	var particles = PARTICLE_SCENES[type].instantiate()
	effects_container.add_child(particles)
	particles.global_position = position
	
	# Configure particles based on params
	if params.has("color"):
		particles.modulate = params.color
	if params.has("amount"):
		particles.amount = params.amount
	if params.has("lifetime"):
		particles.lifetime = params.lifetime
	
	# Start particles
	particles.emitting = true
	
	# Clean up after emission
	await get_tree().create_timer(params.get("lifetime", 1.0) + 0.1).timeout
	particles.queue_free()
