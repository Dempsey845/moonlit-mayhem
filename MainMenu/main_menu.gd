extends Node3D

@export_file("*.tscn") var gameplay_scene_path := "res://Graveyard/graveyard.tscn"
@export var transition_ui: TransitionUI

@onready var menu: VBoxContainer = $MenuUI/Layout/Menu


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$MenuUI/Layout/Menu/Play.grab_focus()
	BackgroundMusic.play_menu()


func _play() -> void:
	if GameLoader.is_loading:
		return

	for child in menu.get_children():
		if child is Button:
			child.disabled = true

	if not await GameLoader.load_gameplay(gameplay_scene_path, transition_ui):
		transition_ui.reveal()
		for child in menu.get_children():
			if child is Button:
				child.disabled = false
		$MenuUI/Layout/Menu/Play.grab_focus()


func _quit() -> void:
	get_tree().quit()
