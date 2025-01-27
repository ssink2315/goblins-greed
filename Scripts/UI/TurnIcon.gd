extends Control

@onready var icon = $Icon
@onready var highlight = $Highlight

var unit: BaseCharacter

func setup(unit_ref: BaseCharacter):
    unit = unit_ref
    icon.texture = unit.portrait
    highlight.hide()

func set_highlighted(is_highlighted: bool):
    highlight.visible = is_highlighted 