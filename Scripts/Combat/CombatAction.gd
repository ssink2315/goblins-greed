extends Resource
class_name CombatAction

enum ActionResult { HIT, MISS, CRITICAL }

signal action_executed(user: BaseCharacter, target: BaseCharacter, result: ActionResult)

static func execute_attack(attacker: BaseCharacter, target: BaseCharacter):
	var damage = calculate_damage(attacker, target)
	var result = calculate_hit(attacker, target)
	
	match result:
		ActionResult.CRITICAL:
			damage *= 2
		ActionResult.MISS:
			damage = 0
	
	if damage > 0:
		target.take_damage(damage)
	
	return {
		"result": result,
		"damage": damage
	}

static func execute_defend(character: BaseCharacter):
	character.defending = true
	character.defense_bonus = 1.5
	return {
		"result": ActionResult.HIT,
		"effect": "defending"
	}

static func calculate_damage(attacker: BaseCharacter, target: BaseCharacter):
	var base_damage = attacker.attack
	var defense = target.defense
	
	if target.defending:
		defense *= target.defense_bonus
	
	var damage = base_damage - defense
	damage = max(1, damage) # Minimum 1 damage
	
	# Apply row modifiers
	if attacker.current_row == CombatState.Row.BACK:
		damage = int(damage * CombatState.BACK_ROW_DAMAGE_MOD)
	
	return damage

static func calculate_hit(attacker: BaseCharacter, target: BaseCharacter):
	var hit_chance = 90 + (attacker.accuracy - target.evasion)
	var roll = randi() % 100
	
	if roll < 10:
		return ActionResult.CRITICAL
	elif roll < hit_chance:
		return ActionResult.HIT
	else:
		return ActionResult.MISS
