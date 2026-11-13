extends Node3D

@export var gameplay_scene: PackedScene
@export var settings_scene: PackedScene
@export var transition_ui: TransitionUI

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$MenuUI/Layout/Menu/Play.grab_focus()

	BackgroundMusic.play_menu()

func _play() -> void:
	if gameplay_scene == null:
		push_warning("Assign Gameplay Scene on MainMenu.")
		return
	await transition_ui.transition()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_packed(gameplay_scene)

func _settings() -> void:
	if settings_scene == null:
		push_warning("Assign Settings Scene on MainMenu.")
		return
	get_tree().change_scene_to_packed(settings_scene)

func _quit() -> void:
	get_tree().quit()
