class_name TransitionUI
extends Control

@onready var transition_rect: ColorRect = $ColorRect

func _ready() -> void:
	var mat: ShaderMaterial = transition_rect.material as ShaderMaterial
	mat.set_shader_parameter("progress", 0.0)

	await get_tree().create_timer(1.0).timeout

	var reveal: Tween = create_tween()
	reveal.tween_property(mat, "shader_parameter/progress", 1.0, 0.55)

func transition():
	var mat: ShaderMaterial = transition_rect.material as ShaderMaterial
	var reveal: Tween = create_tween()
	reveal.tween_property(mat, "shader_parameter/progress", 0.0, 0.55)
	await reveal.finished