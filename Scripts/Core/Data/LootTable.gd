extends Resource
class_name LootTable

@export var items: Array[Dictionary] = []
# Format: { "item_id": "potion", "weight": 70, "quantity": [1, 3] }
# weight is chance out of 1000 (so 70 = 7%)
# quantity is [min, max] range for how many drop

@export var guaranteed_items: Array[Dictionary] = []
# Format: { "item_id": "quest_item", "quantity": 1 }

# Constants for configurable values
const DROP_ROLL_MAX = 1000  # Maximum value for drop roll calculations

func generate_drops() -> Array[Dictionary]:
    var drops: Array[Dictionary] = []
    
    # Add guaranteed drops
    for item in guaranteed_items:
        drops.append({
            "item_id": item.item_id,
            "quantity": item.quantity
        })
    
    # Roll for random drops
    for item in items:
        var roll = randi() % DROP_ROLL_MAX  # Use constant for roll calculation
        if roll < item.weight:
            var quantity = 1
            if "quantity" in item:
                quantity = randi() % (item.quantity[1] - item.quantity[0] + 1) + item.quantity[0]
            
            drops.append({
                "item_id": item.item_id,
                "quantity": quantity
            })
    
    return drops 

# Documentation:
# The LootTable class manages item drops for the game.
# - `items`: An array of dictionaries representing possible random drops.
#   Each dictionary should contain:
#   - `item_id`: The identifier for the item.
#   - `weight`: The chance of the item dropping, expressed as a value out of 1000.
#   - `quantity`: An optional array defining the minimum and maximum quantity that can drop.
#
# - `guaranteed_items`: An array of dictionaries representing items that are guaranteed to drop.
#   Each dictionary should contain:
#   - `item_id`: The identifier for the guaranteed item.
#   - `quantity`: The fixed quantity of the item that will drop. 