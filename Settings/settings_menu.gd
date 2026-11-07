extends CanvasLayer

signal closed

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

func _bind_controls() -> void:
	_bind_toggle(content.get_node("FullscreenRow/Control"), "fullscreen")
	_bind_toggle(content.get_node("VSyncRow/Control"), "vsync")
	_bind_option(content.get_node("FPSRow/Control"), "fps", [0, 30, 60, 120, 144])
	_bind_option(content.get_node("ScaleRow/Control"), "scale", [0.5, 0.75, 1.0])
	_bind_option(content.get_node("MSAARow/Control"), "msaa", [0, 1, 2, 3])

	for bus_name in ["Master", "SFX", "Music"]:
		var row := content.get_node(bus_name + "Row")
		_bind_volume(row.get_node("Control"), row.get_node("Amount"), bus_name)

	content.get_node("Back").pressed.connect(_close)
	content.get_node("FullscreenRow/Control").grab_focus()

func _bind_toggle(toggle: CheckButton, key: String) -> void:
	toggle.set_pressed_no_signal(bool(settings.values[key]))
	toggle.toggled.connect(func(value: bool): settings.set_setting(key, value))

func _bind_option(option: OptionButton, key: String, choices: Array) -> void:
	option.select(maxi(choices.find(settings.values[key]), 0))
	option.item_selected.connect(func(index: int): settings.set_setting(key, choices[index]))

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
