extends Node

const DEFAULT_THEME = preload("res://Resources/Themes/default_theme.tres")
const UI_STYLES = preload("res://Resources/Themes/StyleBoxes/ui_styles.tres")

# Theme constants
const COLORS = {
    "text_default": Color(0.875, 0.875, 0.875, 1.0),
    "text_disabled": Color(0.5, 0.5, 0.5, 1.0),
    "accent": Color(0.4, 0.6, 1.0, 1.0),
    "warning": Color(1.0, 0.7, 0.0, 1.0),
    "error": Color(1.0, 0.3, 0.3, 1.0),
    "success": Color(0.3, 0.8, 0.3, 1.0)
}

const FONT_SIZES = {
    "small": 14,
    "default": 16,
    "large": 20,
    "header": 24
}

func _ready():
    apply_theme_to_root()

func apply_theme_to_root():
    var root = get_tree().root
    root.theme = DEFAULT_THEME
    _apply_styles_to_theme(root.theme)

func _apply_styles_to_theme(theme: Theme):
    # Panels
    theme.set_stylebox("panel", "PanelContainer", UI_STYLES.panel)
    
    # Buttons
    theme.set_stylebox("normal", "Button", UI_STYLES.button_normal)
    theme.set_stylebox("hover", "Button", UI_STYLES.button_hover)
    theme.set_stylebox("pressed", "Button", UI_STYLES.button_pressed)
    
    # Colors
    for control_type in ["Button", "Label", "RichTextLabel"]:
        theme.set_color("font_color", control_type, COLORS.text_default)
        theme.set_color("font_disabled_color", control_type, COLORS.text_disabled)
    
    # Font sizes
    theme.set_font_size("font_size", "Label", FONT_SIZES.default)
    theme.set_font_size("normal_font_size", "RichTextLabel", FONT_SIZES.default)
    theme.set_font_size("header_font_size", "RichTextLabel", FONT_SIZES.header)

func get_color(color_name: String) -> Color:
    return COLORS.get(color_name, COLORS.text_default)

func get_font_size(size_name: String) -> int:
    return FONT_SIZES.get(size_name, FONT_SIZES.default) 