extends CanvasLayer

@export var transition_ui: TransitionUI

@onready var settings_button: Button = %Settings
@onready var menu_button: Button = %Menu
@onready var quit_button: Button = %Quit
@onready var back_button: Button = %Back

var can_open: bool = true

func _ready() -> void:
	UISounds.bind_controls(self)

	settings_button.pressed.connect(func():
		open_settings()
	)

	menu_button.pressed.connect(func():
		can_open = false
		get_tree().paused = false
		visible = false
		await transition_ui.transition()
		get_tree().change_scene_to_file("res://MainMenu/main_menu.tscn")
	)
	
	quit_button.pressed.connect(func():
		get_tree().quit()
	)

	back_button.pressed.connect(func():
		visible = false
		get_tree().paused = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and can_open and not GameLoader.is_loading:
		visible = !visible
		get_tree().paused = visible

func open_settings() -> void:
	var settings := get_node_or_null("/root/GameSettings")

	if settings != null:
		settings.open_settings()
	else:
		push_error("Add res://Settings/game_settings.gd as an Autoload named GameSettings.")