extends Camera3D

@export var player: Player
@export var transition_duration: float = 1.5

@export var ui_controls: Array[Control]
@export var ui_fade_duration: float = 0.5

func _ready() -> void:
	for control in ui_controls:
		if is_instance_valid(control):
			control.modulate.a = 0.0
	make_current()
	await get_tree().create_timer(2.0, false).timeout

	if not is_instance_valid(player) or not is_instance_valid(player.camera):
		return

	var target_camera: Camera3D = player.camera
	var start_transform: Transform3D = global_transform
	var start_fov: float = fov

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(weight: float) -> void:
			if is_instance_valid(target_camera):
				global_transform = start_transform.interpolate_with(
					target_camera.global_transform, weight
				)
				fov = lerpf(start_fov, target_camera.fov, weight),
		0.0,
		1.0,
		transition_duration
	)

	await tween.finished

	if not is_instance_valid(target_camera):
		return

	target_camera.make_current()

	if ui_controls.is_empty():
		return

	var ui_tween: Tween = create_tween().set_parallel()
	ui_tween.set_trans(Tween.TRANS_SINE)
	ui_tween.set_ease(Tween.EASE_OUT)

	for control in ui_controls:
		if is_instance_valid(control):
			ui_tween.tween_property(control, "modulate:a", 1.0, ui_fade_duration)