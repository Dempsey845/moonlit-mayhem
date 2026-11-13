extends Node

const SAVE_PATH = "user://moonlit_settings.cfg"
const PRESETS := {
	"performance": {"fps": 30, "scale": 0.65, "msaa": 0, "shadows": false},
	"balanced": {"fps": 60, "scale": 0.85, "msaa": 0, "shadows": true},
	"quality": {"fps": 60, "scale": 1.0, "msaa": 1, "shadows": true},
}
const EFFECT_DEFAULTS := {"shadows": true}
const ORIGINAL_SHADOWS := &"_moonlit_original_shadows"

var values: Dictionary = {"fullscreen": false, "vsync": true, "fps": 0, "scale": 1.0, "msaa": 0, "Master": 1.0, "SFX": 1.0, "Music": 0.2}
var menu: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for bus_name in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")

	values.merge(EFFECT_DEFAULTS)
	if OS.has_feature("web"):
		values.merge(PRESETS["balanced"], true)

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
	get_tree().scene_changed.connect(_apply_scene_graphics)
	_apply_scene_graphics.call_deferred()

func set_graphics_preset(preset: String) -> void:
	if PRESETS.has(preset):
		values.merge(PRESETS[preset], true)
		_apply_graphics()

func get_graphics_preset() -> String:
	for preset: String in PRESETS:
		var matches := true
		for key: String in PRESETS[preset]:
			if values[key] != PRESETS[preset][key]:
				matches = false
				break
		if matches:
			return preset
	return "custom"

func set_setting(key: String, value: Variant) -> void:
	if not values.has(key):
		return
	values[key] = value
	if key == "fullscreen" or key == "vsync":
		_apply_display(true)
	elif key in ["Master", "SFX", "Music"]:
		_apply_audio()
	else:
		_apply_graphics()

func apply_all() -> void:
	_apply_display()
	_apply_graphics()
	_apply_audio()

func _apply_display(from_menu: bool = false) -> void:
	if DisplayServer.get_name() == "headless":
		return

	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if (from_menu or not OS.has_feature("web")) and DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	if not OS.has_feature("web"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values["vsync"] else DisplayServer.VSYNC_DISABLED)

func _apply_graphics() -> void:
	Engine.max_fps = int(values["fps"])
	var viewport := get_tree().root
	if OS.has_feature("web"):
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = float(values["scale"])
	viewport.msaa_3d = int(values["msaa"])
	_apply_scene_graphics()

func _apply_scene_graphics() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	for node in scene.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if not light.has_meta(ORIGINAL_SHADOWS):
			light.set_meta(ORIGINAL_SHADOWS, light.shadow_enabled)
		light.shadow_enabled = bool(values["shadows"]) and bool(light.get_meta(ORIGINAL_SHADOWS))

func _apply_audio() -> void:
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
