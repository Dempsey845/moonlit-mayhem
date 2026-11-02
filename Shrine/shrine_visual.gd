class_name ShrineVisual
extends Node3D

@onready var shrine_mesh: MeshInstance3D = $Shrine

@onready var heart_mesh: MeshInstance3D = $Heart
@onready var speed_mesh: MeshInstance3D = $Shoe
@onready var duration_mesh: MeshInstance3D = $MoonDuration
@onready var angle_mesh: MeshInstance3D = $MoonAngle

var outline_tween: Tween

func show_outline(duration: float = 0.2) -> void:
	_set_outline_strength(1.0, duration)


func hide_outline(duration: float = 0.2) -> void:
	_set_outline_strength(0.0, duration)


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