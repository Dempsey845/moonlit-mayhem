class_name ShrineVisual
extends Node3D

@onready var shrine_mesh: MeshInstance3D = $Shrine

@onready var heart_mesh: MeshInstance3D = $Heart
@onready var speed_mesh: MeshInstance3D = $Shoe
@onready var duration_mesh: MeshInstance3D = $MoonDuration
@onready var angle_mesh: MeshInstance3D = $MoonAngle
@onready var ghost_icon: MeshInstance3D = $GhostIcon
@onready var ghost_amount_label: Label3D = $GhostAmountLabel

var outline_tween: Tween

var amount_tween: Tween
var icon_tween: Tween

func show_outline(duration: float = 0.2) -> void:
	_set_outline_strength(1.0, duration)

func hide_outline(duration: float = 0.2) -> void:
	_set_outline_strength(0.0, duration)

func show_amount(duration: float = 0.3) -> void:
	_set_amount_transparency(0.0, duration)
	_set_icon_transparency(0.0, duration)

func hide_amount(duration: float = 0.3) -> void:
	_set_amount_transparency(1.0, duration)
	_set_icon_transparency(1.0, duration)

func _set_outline_strength(target: float, duration: float) -> void:
	var material := shrine_mesh.material_overlay as ShaderMaterial

	if not material:
		return

	if outline_tween:
		outline_tween.kill()

	outline_tween = create_tween()
	outline_tween.set_trans(Tween.TRANS_SINE)
	outline_tween.set_ease(Tween.EASE_IN_OUT)

	outline_tween.tween_method(
		func(value: float):
			shrine_mesh.set_instance_shader_parameter("outline_strength", value),
		float(shrine_mesh.get_instance_shader_parameter("outline_strength")),
		target,
		duration
	)

func _set_amount_transparency(target: float, duration: float) -> void:
	if amount_tween:
		amount_tween.kill()

	amount_tween = create_tween()
	amount_tween.set_trans(Tween.TRANS_SINE)
	amount_tween.set_ease(Tween.EASE_IN_OUT)

	amount_tween.tween_method(
		func(value: float):
			ghost_amount_label.transparency = value,
		ghost_amount_label.transparency,
		target,
		duration
	)

func _set_icon_transparency(target: float, duration: float) -> void:
	if icon_tween:
		icon_tween.kill()

	icon_tween = create_tween()
	icon_tween.set_trans(Tween.TRANS_SINE)
	icon_tween.set_ease(Tween.EASE_IN_OUT)

	icon_tween.tween_method(
		func(value: float):
			ghost_icon.transparency = value,
		ghost_icon.transparency,
		target,
		duration
	)

func set_ghost_amount_label(cost: int):
	ghost_amount_label.text = "x" + str(cost)