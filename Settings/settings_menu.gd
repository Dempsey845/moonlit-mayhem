extends CanvasLayer

signal closed

const PRESETS := ["custom", "performance", "balanced", "quality"]
const FPS_OPTIONS := [0, 30, 60, 120, 144]
const SCALE_OPTIONS := [0.5, 0.65, 0.75, 0.85, 1.0]
const MSAA_OPTIONS := [0, 1, 2, 3]
const EFFECT_ROWS := {"ShadowsRow": "shadows"}

var settings: Node
var was_paused: bool
var previous_mouse_mode: int
var previous_focus: WeakRef

@onready var status: Label = %Status
@onready var margin = %Margin
@onready var content = %Content

func _ready() -> void:
	settings = get_node_or_null("/root/GameSettings")

	if settings == null:
		push_error("Add Settings/game_settings.gd as the GameSettings Autoload first.")
		queue_free()
		return

	was_paused = get_tree().paused
	previous_mouse_mode = Input.mouse_mode
	previous_focus = weakref(get_viewport().gui_get_focus_owner())

	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_bind_controls()

	UISounds.bind_controls(self)

func _bind_controls() -> void:
	var preset: OptionButton = content.get_node("PresetRow/Control")
	preset.set_item_disabled(0, true)
	preset.item_selected.connect(func(index: int):
		settings.set_graphics_preset(PRESETS[index])
		_refresh_graphics()
	)

	var fullscreen: CheckButton = content.get_node("FullscreenRow/Control")
	_bind_toggle(fullscreen, "fullscreen")
	if OS.has_feature("web"):
		fullscreen.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	content.get_node("VSyncRow").visible = not OS.has_feature("web")
	_bind_toggle(content.get_node("VSyncRow/Control"), "vsync")
	_bind_option(content.get_node("FPSRow/Control"), "fps", FPS_OPTIONS)
	_bind_option(content.get_node("ScaleRow/Control"), "scale", SCALE_OPTIONS)
	_bind_option(content.get_node("MSAARow/Control"), "msaa", MSAA_OPTIONS)
	for row: String in EFFECT_ROWS:
		_bind_toggle(content.get_node(row + "/Control"), EFFECT_ROWS[row])
	_refresh_graphics()

	for bus_name in ["Master", "SFX", "Music"]:
		var row := content.get_node(bus_name + "Row")
		_bind_volume(row.get_node("Control"), row.get_node("Amount"), bus_name)

	content.get_node("Back").pressed.connect(_close)
	preset.grab_focus()

func _bind_toggle(toggle: CheckButton, key: String) -> void:
	toggle.set_pressed_no_signal(bool(settings.values[key]))
	toggle.toggled.connect(func(value: bool):
		settings.set_setting(key, value)
		_refresh_preset()
	)

func _bind_option(option: OptionButton, key: String, choices: Array) -> void:
	option.item_selected.connect(func(index: int):
		settings.set_setting(key, choices[index])
		_refresh_preset()
	)

func _refresh_graphics() -> void:
	content.get_node("FPSRow/Control").select(FPS_OPTIONS.find(settings.values["fps"]))
	content.get_node("ScaleRow/Control").select(SCALE_OPTIONS.find(settings.values["scale"]))
	content.get_node("MSAARow/Control").select(MSAA_OPTIONS.find(settings.values["msaa"]))
	for row: String in EFFECT_ROWS:
		var toggle: CheckButton = content.get_node(row + "/Control")
		toggle.set_pressed_no_signal(settings.values[EFFECT_ROWS[row]])
	_refresh_preset()

func _refresh_preset() -> void:
	content.get_node("PresetRow/Control").select(PRESETS.find(settings.get_graphics_preset()))

func _bind_volume(slider: HSlider, amount: Label, bus_name: String) -> void:
	slider.set_value_no_signal(float(settings.values[bus_name]) * 100.0)

	amount.text = "%d%%" % slider.value
	
	slider.value_changed.connect(func(value: float):
		amount.text = "%d%%" % value
		settings.set_setting(bus_name, value / 100.0)
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	if settings.save() != OK:
		status.text = "Could not save settings. Check the user data folder is writable."
		return

	queue_free()

func _exit_tree() -> void:
	if settings == null:
		return

	get_tree().paused = was_paused
	Input.mouse_mode = previous_mouse_mode

	if previous_focus != null:
		var focus: Control = previous_focus.get_ref()
		if is_instance_valid(focus):
			focus.grab_focus()

	closed.emit()
