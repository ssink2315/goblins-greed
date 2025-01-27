extends Control

signal confirmed
signal cancelled

@export var title: String = "Dialog"
@export var message: String = ""
@export var confirm_text: String = "OK"
@export var cancel_text: String = "Cancel"

func show_dialog():
    UIManager.show_ui(self)

func hide_dialog():
    UIManager.hide_ui(self) 