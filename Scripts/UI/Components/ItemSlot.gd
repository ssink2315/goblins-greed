extends PanelContainer

signal item_clicked(item: ItemData)
signal item_right_clicked(item: ItemData)
signal item_hovered(item: ItemData)
signal item_hover_ended

@onready var icon = $MarginContainer/Icon
@onready var quantity_label = $QuantityLabel
@onready var highlight = $Highlight

var current_item: ItemData

func _ready():
    custom_minimum_size = UITheme.SIZES.item_slot
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func set_item(item: ItemData, quantity: int = 1):
    current_item = item
    if item:
        icon.texture = item.icon
        quantity_label.text = str(quantity) if quantity > 1 else ""
        quantity_label.show()
    else:
        icon.texture = null
        quantity_label.hide()

func _gui_input(event: InputEvent):
    if !current_item:
        return
        
    if event is InputEventMouseButton and event.pressed:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                item_clicked.emit(current_item)
            MOUSE_BUTTON_RIGHT:
                item_right_clicked.emit(current_item)

func _on_mouse_entered():
    if current_item:
        highlight.show()
        item_hovered.emit(current_item)

func _on_mouse_exited():
    highlight.hide()
    item_hover_ended.emit() 