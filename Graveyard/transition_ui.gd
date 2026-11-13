class_name TransitionUI
extends Control

@onready var transition_rect: ColorRect = $ColorRect
@onready var material_override: ShaderMaterial = transition_rect.material

var _tween: Tween


func _ready() -> void:
	material_override.set_shader_parameter("progress", 0.0)
	await get_tree().create_timer(1.0, false).timeout
	if _tween == null:
		reveal()


func reveal() -> void:
	_animate_to(1.0).tween_callback(transition_rect.hide)


func transition() -> void:
	await _animate_to(0.0).finished


func _animate_to(progress: float) -> Tween:
	if _tween != null:
		_tween.kill()
	transition_rect.show()
	_tween = create_tween()
	_tween.tween_property(material_override, "shader_parameter/progress", progress, 0.55)
	return _tween
