extends Control

@export var start_progress: float = 0.0
@export var transition_progress: float = 1.0

@onready var transition_rect: ColorRect = $ColorRect

func _ready() -> void:
	var mat: ShaderMaterial = transition_rect.material as ShaderMaterial
	mat.set_shader_parameter("progress", start_progress)

	await get_tree().create_timer(1.0).timeout

	var reveal: Tween = create_tween()
	reveal.tween_property(mat, "shader_parameter/progress", transition_progress, 0.55)