extends Node

enum CombatState { 
    INITIALIZING, 
    PLAYER_TURN, 
    ALLY_TURN, 
    ENEMY_TURN, 
    ANIMATING, 
    FINISHED 
}

enum ActionType { 
    NONE, 
    ATTACK, 
    SKILL, 
    MOVE, 
    ITEM, 
    DEFEND 
}

enum CombatType { 
    STORY, 
    RANDOM_ENCOUNTER 
}

enum Row { 
    FRONT, 
    BACK 
}

# Combat modifiers
const BACK_ROW_DAMAGE_MOD = 0.85
const BACK_ROW_DEFENSE_MOD = 1.15
