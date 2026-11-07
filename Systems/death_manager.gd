extends Node

@export var player_health: PlayerHealth
@export var transition_ui: TransitionUI
@export var death_label: TextAnimation
@export var player: Player

func _ready() -> void:
	player_health.died.connect(_on_player_died)

func _on_player_died():
	await transition_ui.transition()

	await death_label.type_text("You are dead...")

	await get_tree().create_timer(1.5).timeout

	get_tree().change_scene_to_file("res://MainMenu/main_menu.tscn")
