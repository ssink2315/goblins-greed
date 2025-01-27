extends Resource

const COLORS = {
    "background": Color("202020"),  # RGB: 32, 32, 32
    "panel": Color("2A2A2A"),      # RGB: 42, 42, 42
    "text": Color("E6E6E6"),       # RGB: 230, 230, 230
    "accent": Color("4A90E2"),     # RGB: 74, 144, 226
    
    # State colors
    "hover": Color("333333"),      # Lighten base by 10%
    "pressed": Color("1A1A1A"),    # Darken base by 10%
    "disabled": Color("202020", 0.5)  # 50% opacity
}

const SPACING = {
    "margin_outer": 20,
    "margin_inner": 10,
    "padding_button_h": 5,
    "padding_button_v": 3,
    "component_spacing": 10
}

const SIZES = {
    "button_height": 32,
    "icon": Vector2(32, 32),
    "item_slot": Vector2(48, 48),
    "minimum_touch": Vector2(44, 44)  # Minimum touch target size
}

const FONTS = {
    "header": 24,
    "normal": 16,
    "small": 14
}

const CORNERS = {
    "radius": 4  # Standard corner radius
}

static func get_hover_color(base_color: Color) -> Color:
    return base_color.lightened(0.1)

static func get_pressed_color(base_color: Color) -> Color:
    return base_color.darkened(0.1) 