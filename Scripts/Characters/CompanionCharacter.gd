extends BaseCharacter
class_name CompanionCharacter

# Enums
enum RelationshipLevel { HOSTILE, COLD, NEUTRAL, FRIENDLY, DEVOTED }
enum CombatRole { ATTACKER, DEFENDER, SUPPORT, BALANCED }

# Personality and relationship
var personality_traits: Dictionary = {
	"kind": 0,     # -10 to 10
	"brave": 0,    # -10 to 10
	"cunning": 0   # -10 to 10
}

var relationship: Dictionary = {
	"level": 50,           # 0-100 scale
	"trust": 0,           # Affects combat bonuses
	"approval": 0,        # Affects dialogue and choices
	"current_role": CombatRole.BALANCED
}

# Combat preferences by role
const COMBAT_WEIGHTS: Dictionary = {
	CombatRole.ATTACKER: {"attack": 1.5, "defend": 0.3, "skill": 1.0, "support": 0.2},
	CombatRole.DEFENDER: {"attack": 0.3, "defend": 1.5, "skill": 0.7, "support": 0.5},
	CombatRole.SUPPORT:  {"attack": 0.2, "defend": 0.5, "skill": 1.0, "support": 1.5},
	CombatRole.BALANCED: {"attack": 1.0, "defend": 1.0, "skill": 1.0, "support": 1.0}
}

# Quest tracking
var active_quests: Array[Resource] = []
var completed_quests: Array[String] = []

# Signals
signal relationship_changed(old_level: RelationshipLevel, new_level: RelationshipLevel)
signal quest_updated(quest_name: String, status: String)
signal combat_role_changed(new_role: CombatRole)

func _init() -> void:
	super._init()

func initialize(companion_data: Dictionary) -> void:
	super.initialize(
		companion_data.name,
		companion_data.race,
		companion_data.class_name
	)
	
	# Set personality traits
	for trait in companion_data.traits:
		if trait in personality_traits:
			personality_traits[trait] = companion_data.traits[trait]
	
	# Set initial relationship
	relationship.level = companion_data.get("relationship_level", 50)
	set_combat_role(companion_data.get("combat_role", CombatRole.BALANCED))
	
	_update_relationship_effects()

func set_combat_role(new_role: CombatRole) -> void:
	if new_role == relationship.current_role:
		return
		
	relationship.current_role = new_role
	emit_signal("combat_role_changed", new_role)

func get_combat_weights() -> Dictionary:
	return COMBAT_WEIGHTS[relationship.current_role]

func adjust_relationship(amount: int, context: String = "") -> void:
	var old_level = get_relationship_level()
	relationship.level = clamp(relationship.level + amount, 0, 100)
	
	var new_level = get_relationship_level()
	if old_level != new_level:
		emit_signal("relationship_changed", old_level, new_level)
		_update_relationship_effects()

func get_relationship_level() -> RelationshipLevel:
	if relationship.level >= 80:
		return RelationshipLevel.DEVOTED
	elif relationship.level >= 60:
		return RelationshipLevel.FRIENDLY
	elif relationship.level >= 40:
		return RelationshipLevel.NEUTRAL
	elif relationship.level >= 20:
		return RelationshipLevel.COLD
	else:
		return RelationshipLevel.HOSTILE

func _update_relationship_effects() -> void:
	var rel_bonus = relationship.level / 100.0
	
	# Update combat modifiers based on relationship
	phys_dmg_mod += 0.1 * rel_bonus
	magic_dmg_mod += 0.1 * rel_bonus
	phys_def += 2 * rel_bonus
	magic_def += 2 * rel_bonus

func get_dialogue(context: String) -> String:
	var rel_level = get_relationship_level()
	
	# Load dialogue from a resource later
	return "Default dialogue"

func add_quest(quest: Resource) -> void:
	if quest not in active_quests:
		active_quests.append(quest)
		emit_signal("quest_updated", quest.quest_name, "started")

func complete_quest(quest_name: String)--> void:
	for quest in active_quests:
		if quest.quest_name == quest_name:
			active_quests.erase(quest)
			completed_quests.append(quest_name)
			emit_signal("quest_updated", quest_name, "completed")
			break

func level_up() -> void:
	super.level_up()  # Assuming we add this to BaseCharacter
	
	# Companion-specific level up bonuses
	var rel_bonus = relationship.level / 100.0
	WIS += 1 + floor(rel_bonus)
	
	calculate_secondary_stats()
