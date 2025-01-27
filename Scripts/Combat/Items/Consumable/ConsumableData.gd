# ConsumableData.gd
extends ItemData
class_name ConsumableData

@export var effect_name: String = ""  # E.g., "Healing Potion"
@export var effect_description: String = ""  # E.g., "Restores 50 HP."
@export var effect_strength: int = 0  # The magnitude of the effect, e.g., HP restored.
@export var effect_duration: int = 0  # If temporary, how long the effect lasts.

# Methods
func use(target: BaseCharacter):
	print("%s uses %s: %s" % [target.character_name, item_name, effect_description])
	# Implement the effect logic (e.g., healing, buffing, etc.)
