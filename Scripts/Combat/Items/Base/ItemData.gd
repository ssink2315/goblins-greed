extends Resource
class_name ItemData

# Signals
signal item_used(target: BaseCharacter)
signal item_equipped(character: BaseCharacter)
signal item_unequipped(character: BaseCharacter)

# Enums
enum ItemType { WEAPON, ARMOR, ACCESSORY, TRINKET, IDOL, CONSUMABLE }
enum Rarity { COMMON, RARE, EPIC, HEROIC }

# Core properties
@export var item_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType
@export var rarity: Rarity = Rarity.COMMON
@export var value: int = 0
@export var required_level: int = 1

# Combat properties
@export var usable_in_combat: bool = false
@export var combat_target_type: String = "single"  # single, all, self
@export var combat_effects: Array[Dictionary] = []

# Methods
func is_equippable() -> bool:
	return item_type in [ItemType.WEAPON, ItemType.ARMOR, ItemType.ACCESSORY, ItemType.TRINKET, ItemType.IDOL]

func can_be_equipped_by(character: BaseCharacter) -> bool:
	if not character:
		return false
	return character.level >= required_level

func use(user: BaseCharacter, target: BaseCharacter) -> Dictionary:
	var result = {
		"success": false,
		"effects": [],
		"message": ""
	}
	
	if not usable_in_combat:
		result.message = "Item cannot be used in combat"
		return result
	
	for effect in combat_effects:
		var effect_result = _apply_effect(target, effect)
		result.effects.append(effect_result)
	
	result.success = true
	item_used.emit(target)
	return result

func _apply_effect(target: BaseCharacter, effect: Dictionary) -> Dictionary:
	var result = {
		"type": effect.type,
		"target": target,
		"value": effect.value
	}
	
	match effect.type:
		"heal":
			target.heal(effect.value)
		"restore_mana":
			target.restore_mana(effect.value)
		"status":
			if effect.has("status_effect"):
				target.add_status_effect(effect.status_effect.duplicate())
		"remove_status":
			if effect.has("status_name"):
				target.remove_status_effect(effect.status_name)
	
	return result

func get_display_name() -> String:
	var rarity_prefix = Rarity.keys()[rarity].capitalize()
	return "%s %s" % [rarity_prefix, item_name]

func get_tooltip() -> String:
	var text = "[b]%s[/b]\n%s" % [get_display_name(), description]
	text += "\nValue: %d gold" % value
	if required_level > 1:
		text += "\nRequired Level: %d" % required_level
	if usable_in_combat:
		text += "\n[i]Usable in combat[/i]"
	return text

func get_combat_info() -> Dictionary:
	return {
		"usable": usable_in_combat,
		"target_type": combat_target_type,
		"effects": combat_effects
	}

func duplicate() -> ItemData:
	var new_item = super.duplicate()
	new_item.combat_effects = combat_effects.duplicate(true)
	return new_item
