extends Node

func open_settings() -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if settings != null:
		settings.open_settings()
	else:
		push_error("Add res://Settings/game_settings.gd as an Autoload named GameSettings.")
