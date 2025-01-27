# TrinketData.gd
extends ItemData
class_name TrinketData

@export var active_spell: Resource  # A Spell resource defining the spell logic
@export var cooldown: int = 0  # Number of turns between uses

# Methods
func cast_spell(caster: BaseCharacter, target: BaseCharacter):
	if active_spell:
		print("%s casts %s on %s!" % [caster.character_name, active_spell.resource_name, target.character_name])
		active_spell.cast(caster, target)  # Assume `cast()` is a method of the Spell resource.
	else:
		print("%s has no active spell assigned!" % [item_name])
