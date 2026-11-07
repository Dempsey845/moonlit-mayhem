extends Node

const SAVE_PATH = "user://moonlit_settings.cfg"
var values: Dictionary = {"fullscreen": false, "vsync": true, "fps": 0, "scale": 1.0, "msaa": 0, "Master": 1.0, "SFX": 1.0, "Music": 1.0}
var menu: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for bus_name in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in values:
			var stored: Variant = config.get_value("settings", key, values[key])
			if typeof(stored) == typeof(values[key]):
				values[key] = stored

	values["scale"] = clampf(float(values["scale"]), 0.5, 1.0)
	values["msaa"] = clampi(int(values["msaa"]), 0, 3)
	values["fps"] = maxi(int(values["fps"]), 0)

	for bus_name in ["Master", "SFX", "Music"]:
		values[bus_name] = clampf(float(values[bus_name]), 0.0, 1.0)
		
	apply_all()

func set_setting(key: String, value: Variant) -> void:
	if not values.has(key):
		return
	values[key] = value
	apply_all()

func apply_all() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values["vsync"] else DisplayServer.VSYNC_DISABLED)
	
	Engine.max_fps = int(values["fps"])
	get_tree().root.scaling_3d_scale = float(values["scale"])
	get_tree().root.msaa_3d = int(values["msaa"])

	for bus_name in ["Master", "SFX", "Music"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var volume := float(values[bus_name])
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
			AudioServer.set_bus_mute(index, volume <= 0.0)

func save() -> Error:
	var config := ConfigFile.new()
	for key in values:
		config.set_value("settings", key, values[key])
	return config.save(SAVE_PATH)

func open_settings() -> CanvasLayer:
	if is_instance_valid(menu):
		return menu

	menu = preload("res://Settings/settings_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	return menu
