extends Node
class_name CombatRewards

const BASE_GOLD_MODIFIER = 1.0
const LEVEL_ADVANTAGE_PENALTY = -0.10  # -10% per level above
const LEVEL_DISADVANTAGE_BONUS = 0.25  # +25% per level below

var party: Array[BaseCharacter]
var enemies: Array[BaseCharacter]
var total_exp: int = 0
var total_gold: int = 0
var drops: Array[Dictionary] = []

signal rewards_calculated(exp: int, gold: int, drops: Array)
signal level_up(character: BaseCharacter, new_level: int, stat_increases: Dictionary)

func calculate_rewards(party_members: Array[BaseCharacter], defeated_enemies: Array[BaseCharacter]):
    party = party_members
    enemies = defeated_enemies
    
    for enemy in enemies:
        var enemy_data = enemy as EnemyCharacter
        if not enemy_data:
            continue
            
        # Calculate base rewards
        var base_exp = enemy_data.base_exp
        var base_gold = enemy_data.base_gold
        
        # Calculate level difference modifier
        var avg_party_level = get_average_party_level()
        var level_diff = enemy_data.challenge_level - avg_party_level
        var level_modifier = 1.0
        
        if level_diff > 0:
            # Enemy is higher level
            level_modifier += (LEVEL_DISADVANTAGE_BONUS * level_diff)
        else:
            # Party is higher level
            level_modifier += (LEVEL_ADVANTAGE_PENALTY * abs(level_diff))
        
        # Apply modifiers
        total_exp += int(base_exp * level_modifier)
        total_gold += int(base_gold * level_modifier)
        
        # Generate drops
        if enemy_data.loot_table:
            var enemy_drops = enemy_data.loot_table.generate_drops()
            drops.append_array(enemy_drops)
    
    # Apply party's exp gain modifiers
    for member in party:
        var exp_modifier = 1.0 + (member.exp_gain / 100.0)
        var member_exp = int(total_exp * exp_modifier)
        
        # Add experience and check for level up
        member.level_manager.add_experience(member_exp)
        
        # Connect to level up signal if not already connected
        if not member.level_manager.is_connected("gain_level", _on_character_level_up):
            member.level_manager.connect("gain_level", _on_character_level_up)
    
    emit_signal("rewards_calculated", total_exp, total_gold, drops)

func get_average_party_level() -> int:
    var total_level = 0
    for member in party:
        total_level += member.level_manager.current_level
    return total_level / party.size()

func _on_character_level_up(character: BaseCharacter, new_level: int, stat_increases: Dictionary):
    emit_signal("level_up", character, new_level, stat_increases)

func distribute_rewards():
    # Add gold to party's shared inventory
    GameManager.add_party_gold(total_gold)
    
    # Add items to party's shared inventory
    for drop in drops:
        GameManager.add_party_item(drop.item_id, drop.quantity)

func get_rewards_text() -> String:
    var text = "Combat Rewards:\n"
    text += "EXP: %d\n" % total_exp
    text += "Gold: %d\n" % total_gold
    
    if drops.size() > 0:
        text += "\nItems obtained:\n"
        for drop in drops:
            var item_name = GameDatabase.get_item_name(drop.item_id)
            text += "- %s x%d\n" % [item_name, drop.quantity]
    
    return text 