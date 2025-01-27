extends Node
class_name InventoryManager

signal inventory_changed
signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal equipment_changed(slot: String, item: ItemData)

const MAX_STACK_SIZE: int = 99
const DEFAULT_INVENTORY_SIZE: int = 20

var items: Array[ItemData] = []
var equipment_slots: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null,
	"trinket": null,
	"idol": null
}

var owner: BaseCharacter = null
var current_size: int = DEFAULT_INVENTORY_SIZE

func _init(character: BaseCharacter) -> void:
	owner = character

# Inventory Management
func add_item(item: ItemData) -> bool:
	if items.size() >= current_size:
		push_warning("Inventory is full!")
		return false
	
	items.append(item)
	emit_signal("inventory_changed")
	emit_signal("item_added", item)
	return true

func remove_item(item: ItemData) -> bool:
	var index = items.find(item)
	if index != -1:
		items.remove_at(index)
		emit_signal("inventory_changed")
		emit_signal("item_removed", item)
		return true
	return false

# Equipment Management
func equip_item(item: ItemData) -> bool:
	if not item.is_equippable():
		push_warning("Item cannot be equipped!")
		return false
	
	if not item.can_be_equipped_by(owner):
		push_warning("Character cannot equip this item!")
		return false
	
	var slot = _get_slot_for_item(item)
	if slot.is_empty():
		push_warning("No valid slot for this item!")
		return false
	
	# Unequip existing item if any
	var current_item = equipment_slots[slot]
	if current_item:
		unequip_item(slot)
	
	# Remove from inventory and equip
	remove_item(item)
	equipment_slots[slot] = item
	_apply_item_stats(item)
	
	emit_signal("equipment_changed", slot, item)
	return true

func unequip_item(slot: String) -> bool:
	var item = equipment_slots[slot]
	if not item:
		return false
	
	if add_item(item):
		_remove_item_stats(item)
		equipment_slots[slot] = null
		emit_signal("equipment_changed", slot, null)
		return true
	
	push_warning("Cannot unequip - inventory full!")
	return false

func get_equipped_item(slot: String) -> ItemData:
	return equipment_slots.get(slot)

# Helper Methods
func _get_slot_for_item(item: ItemData) -> String:
	match item.item_type:
		ItemData.ItemType.WEAPON:
			return "weapon"
		ItemData.ItemType.ARMOR:
			return "armor"
		ItemData.ItemType.ACCESSORY:
			return "accessory"
		ItemData.ItemType.TRINKET:
			return "trinket"
		ItemData.ItemType.IDOL:
			return "idol"
	return ""

func _apply_item_stats(item: ItemData) -> void:
	match item.item_type:
		ItemData.ItemType.WEAPON:
			_apply_weapon_stats(item as WeaponData)
		ItemData.ItemType.ARMOR:
			_apply_armor_stats(item as ArmorData)
		ItemData.ItemType.ACCESSORY:
			_apply_accessory_stats(item as AccessoryData)
		ItemData.ItemType.IDOL:
			_apply_idol_stats(item as IdolData)

func _remove_item_stats(item: ItemData) -> void:
	match item.item_type:
		ItemData.ItemType.WEAPON:
			_remove_weapon_stats(item as WeaponData)
		ItemData.ItemType.ARMOR:
			_remove_armor_stats(item as ArmorData)
		ItemData.ItemType.ACCESSORY:
			_remove_accessory_stats(item as AccessoryData)
		ItemData.ItemType.IDOL:
			_remove_idol_stats(item as IdolData)

# Stat Application Methods
func _apply_weapon_stats(weapon: WeaponData) -> void:
	owner.phys_dmg_mod += weapon.calculate_average_damage()
	owner.crit_chance += weapon.crit_chance
	owner.calculate_secondary_stats()

func _remove_weapon_stats(weapon: WeaponData) -> void:
	owner.phys_dmg_mod -= weapon.calculate_average_damage()
	owner.crit_chance -= weapon.crit_chance
	owner.calculate_secondary_stats()

func _apply_armor_stats(armor: ArmorData) -> void:
	owner.phys_def += armor.defense
	owner.magic_def += armor.magic_defense
	owner.evasion += armor.evasion
	owner.calculate_secondary_stats()

func _remove_armor_stats(armor: ArmorData) -> void:
	owner.phys_def -= armor.defense
	owner.magic_def -= armor.magic_defense
	owner.evasion -= armor.evasion
	owner.calculate_secondary_stats()

func _apply_accessory_stats(accessory: AccessoryData) -> void:
	for stat in accessory.stat_bonuses:
		if owner.get(stat) != null:
			owner.set(stat, owner.get(stat) + accessory.stat_bonuses[stat])
	owner.calculate_secondary_stats()

func _remove_accessory_stats(accessory: AccessoryData) -> void:
	for stat in accessory.stat_bonuses:
		if owner.get(stat) != null:
			owner.set(stat, owner.get(stat) - accessory.stat_bonuses[stat])
	owner.calculate_secondary_stats()

func _apply_idol_stats(idol: IdolData) -> void:
	for stat in idol.effect_stats:
		if owner.get(stat) != null:
			owner.set(stat, owner.get(stat) + idol.effect_stats[stat])
	owner.calculate_secondary_stats()

func _remove_idol_stats(idol: IdolData) -> void:
	for stat in idol.effect_stats:
		if owner.get(stat) != null:
			owner.set(stat, owner.get(stat) - idol.effect_stats[stat])
	owner.calculate_secondary_stats()
