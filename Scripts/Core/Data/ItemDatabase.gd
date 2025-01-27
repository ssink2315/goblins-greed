extends Node

# Item type enums (matching ItemData.gd)
enum ItemType { CONSUMABLE, WEAPON, ARMOR, ACCESSORY }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# Starting equipment sets
const STARTER_SETS = {
    "MAGIC_KNIGHT": {
        "weapon": "apprentice_sword",
        "armor": "light_chainmail",
        "accessory": "magic_ring"
    },
    "ADVENTURER": {
        "weapon": "short_sword",
        "armor": "leather_armor",
        "accessory": "adventurer_charm"
    },
    "DEATH_KNIGHT": {
        "weapon": "dark_blade",
        "armor": "dark_plate",
        "accessory": "death_sigil"
    },
    "WIZARD": {
        "weapon": "apprentice_staff",
        "armor": "apprentice_robes",
        "accessory": "mana_crystal"
    }
}

# Starting consumables
const STARTER_CONSUMABLES = {
    "MAGIC_KNIGHT": [
        {"id": "minor_healing_potion", "quantity": 2},
        {"id": "mana_potion", "quantity": 2}
    ],
    "ADVENTURER": [
        {"id": "minor_healing_potion", "quantity": 3},
        {"id": "antidote", "quantity": 1}
    ],
    "DEATH_KNIGHT": [
        {"id": "minor_healing_potion", "quantity": 2},
        {"id": "dark_essence", "quantity": 2}
    ],
    "WIZARD": [
        {"id": "minor_healing_potion", "quantity": 1},
        {"id": "mana_potion", "quantity": 3}
    ]
}

# Shop inventory tiers
const SHOP_TIERS = {
    "TIER_1": {
        "consumables": [
            "minor_healing_potion",
            "mana_potion",
            "antidote",
            "dark_essence"
        ],
        "equipment": [
            "apprentice_sword",
            "apprentice_staff",
            "light_chainmail",
            "leather_armor",
            "dark_plate",
            "apprentice_robes",
            "magic_ring",
            "adventurer_charm",
            "death_sigil",
            "mana_crystal"
        ]
    },
    "TIER_2": {
        "consumables": [
            "greater_healing_potion",
            "greater_mana_potion",
            "elixir_of_might",
            "dark_crystal"
        ],
        "equipment": [
            "runic_blade",
            "sage_staff",
            "enchanted_chainmail",
            "reinforced_adventurer_armor",
            "cursed_plate",
            "sage_robes",
            "arcane_ring",
            "pathfinder_charm",
            "soul_sigil",
            "arcane_crystal"
        ]
    }
}

# Expanded loot tables
const LOOT_TABLES = {
    "COMMON_DROPS": {
        "consumables": [
            {"id": "minor_healing_potion", "weight": 60},
            {"id": "mana_potion", "weight": 30},
            {"id": "dark_essence", "weight": 10}
        ],
        "equipment": [
            {"id": "apprentice_sword", "weight": 15},
            {"id": "apprentice_staff", "weight": 15},
            {"id": "light_chainmail", "weight": 15},
            {"id": "leather_armor", "weight": 15},
            {"id": "dark_plate", "weight": 15},
            {"id": "apprentice_robes", "weight": 15},
            {"id": "magic_ring", "weight": 10},
            {"id": "adventurer_charm", "weight": 10},
            {"id": "death_sigil", "weight": 10},
            {"id": "mana_crystal", "weight": 10}
        ]
    },
    "BOSS_DROPS": {
        "guaranteed": [
            {"id": "greater_healing_potion", "quantity": 2},
            {"id": "mana_potion", "quantity": 2}
        ],
        "equipment_pool": [
            {"id": "guardian_idol", "weight": 25},
            {"id": "sage_idol", "weight": 25},
            {"id": "steel_plate_armor", "weight": 25},
            {"id": "embroidered_robes", "weight": 25}
        ]
    }
}

func get_starter_equipment(class_type: String) -> Dictionary:
    if not STARTER_SETS.has(class_type):
        return {}
    return STARTER_SETS[class_type]

func get_starter_consumables(class_type: String) -> Array:
    if not STARTER_CONSUMABLES.has(class_type):
        return []
    return STARTER_CONSUMABLES[class_type]

func get_shop_inventory(tier: String) -> Dictionary:
    if not SHOP_TIERS.has(tier):
        return {}
    return SHOP_TIERS[tier]

func generate_loot(table_name: String, num_items: int = 1) -> Array:
    if not LOOT_TABLES.has(table_name):
        return []
        
    var loot = []
    var table = LOOT_TABLES[table_name]
    
    # Handle guaranteed drops for boss tables
    if table.has("guaranteed"):
        for item in table.guaranteed:
            loot.append({
                "id": item.id,
                "quantity": item.quantity
            })
    
    # Generate random drops
    for _i in range(num_items):
        var item_data = _generate_random_item(table)
        if item_data:
            loot.append(item_data)
    
    return loot

func _generate_random_item(table: Dictionary) -> Dictionary:
    # 70% chance for consumable, 30% for equipment
    var category = "consumables" if randf() < 0.7 else "equipment"
    var items = table[category]
    
    # Calculate total weight
    var total_weight = 0
    for item in items:
        total_weight += item.weight
    
    # Select random item based on weight
    var roll = randf() * total_weight
    var current_weight = 0
    var selected_item = null
    
    for item in items:
        current_weight += item.weight
        if roll <= current_weight:
            selected_item = item
            break
    
    if not selected_item:
        return {}
    
    return selected_item 