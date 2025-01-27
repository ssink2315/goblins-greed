extends PanelContainer

const MAX_MESSAGES = 8
const MESSAGE_FADE_TIME = 3.0
const DEFAULT_COLOR = Color.WHITE
const SYSTEM_COLOR = Color.YELLOW
const DAMAGE_COLOR = Color.RED
const HEAL_COLOR = Color.GREEN
const BUFF_COLOR = Color.AQUA
const DEBUFF_COLOR = Color.PURPLE

@onready var message_container = $MarginContainer/MessageContainer
@onready var scroll_container = $MarginContainer/ScrollContainer

var message_scene = preload("res://Scenes/UI/Components/CombatLogMessage.tscn")
var messages: Array[Node] = []
var auto_scroll: bool = true

func _ready():
	clear()

func add_message(text: String, color: Color = DEFAULT_COLOR, persist: bool = false):
	var message = message_scene.instantiate()
	message_container.add_child(message)
	message.text = text
	message.modulate = color
	messages.append(message)
	
	if !persist:
		_start_fade_timer(message)
	
	# Remove old messages if we exceed the limit
	while messages.size() > MAX_MESSAGES:
		var old_message = messages.pop_front()
		old_message.queue_free()
	
	if auto_scroll:
		await get_tree().process_frame
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func add_damage_message(attacker: String, target: String, damage: int, is_critical: bool = false):
	var text = "%s dealt %d damage to %s" % [attacker, damage, target]
	if is_critical:
		text += " (Critical Hit!)"
	add_message(text, DAMAGE_COLOR)

func add_heal_message(source: String, target: String, amount: int):
	var text = "%s restored %d HP to %s" % [source, amount, target]
	add_message(text, HEAL_COLOR)

func add_status_message(target: String, status: String, is_applied: bool = true):
	var text = "%s %s %s" % [
		target,
		"gained" if is_applied else "lost",
		status
	]
	add_message(text, BUFF_COLOR if is_applied else DEBUFF_COLOR)

func add_system_message(text: String):
	add_message(text, SYSTEM_COLOR, true)

func add_turn_message(character: BaseCharacter):
	var text = "%s's turn" % character.character_name
	add_message(text, SYSTEM_COLOR)

func add_skill_message(user: String, skill_name: String, target: String):
	var text = "%s used %s on %s" % [user, skill_name, target]
	add_message(text, BUFF_COLOR)

func add_item_message(user: String, item_name: String, target: String):
	var text = "%s used %s on %s" % [user, item_name, target]
	add_message(text, BUFF_COLOR)

func add_status_tick_message(target: String, effect: StatusEffect):
	var text = ""
	match effect.effect_name:
		"Burn":
			text = "%s took %d burn damage" % [target, effect.damage_per_turn * effect.stack_count]
		"Poison":
			text = "%s took %d poison damage" % [target, effect.damage_per_turn * effect.stack_count]
		"Stun":
			text = "%s is stunned!" % target
	
	add_message(text, DAMAGE_COLOR)

func add_status_expired_message(target: String, effect_name: String):
	var text = "%s's %s wore off" % [target, effect_name]
	add_message(text, SYSTEM_COLOR)

func add_combat_start_message(party_size: int, enemy_size: int):
	var text = "Combat started: %d allies vs %d enemies" % [party_size, enemy_size]
	add_message(text, SYSTEM_COLOR, true)

func add_round_start_message(round_number: int):
	var text = "Round %d" % round_number
	add_message(text, SYSTEM_COLOR, true)

func add_combat_end_message(victory: bool):
	var text = "Victory!" if victory else "Defeat..."
	var color = BUFF_COLOR if victory else DAMAGE_COLOR
	add_message(text, color, true)

func add_effect_message(source: String, effect_name: String, target: String):
	var text = "%s applied %s to %s" % [source, effect_name, target]
	add_message(text, BUFF_COLOR)

func clear():
	for message in messages:
		message.queue_free()
	messages.clear()

func _start_fade_timer(message: Node):
	var timer = get_tree().create_timer(MESSAGE_FADE_TIME)
	timer.timeout.connect(func(): _fade_message(message))

func _fade_message(message: Node):
	if !is_instance_valid(message) or !message.is_inside_tree():
		return
		
	var tween = create_tween()
	tween.tween_property(message, "modulate:a", 0.0, 0.5)
	tween.tween_callback(message.queue_free)
	
	var index = messages.find(message)
	if index != -1:
		messages.remove_at(index)

func toggle_auto_scroll(enabled: bool):
	auto_scroll = enabled
