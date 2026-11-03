class_name HealthUI
extends HBoxContainer

@export var player_health: PlayerHealth

var heart_image_rect_scene: PackedScene = preload("uid://bb07qog8o0xqa")

var _hearts: Array[Control] = []
var _heart_tweens: Dictionary = {}


func _ready() -> void:
	if not is_instance_valid(player_health):
		push_warning("HealthUI: Assign a PlayerHealth node.")
		return

	player_health.health_changed.connect(_on_health_changed)

	call_deferred("_initialise_hearts")


func _initialise_hearts() -> void:
	if is_instance_valid(player_health):
		_update_hearts(player_health.current_health, false)


func _on_health_changed(current_health: int, _max_health: int) -> void:
	_update_hearts(current_health)


func _update_hearts(health: int, animate: bool = true) -> void:
	while _hearts.size() > health:
		_remove_heart(animate)

	while _hearts.size() < health:
		_add_heart(animate)


func _add_heart(animate: bool) -> void:
	var heart: Control = heart_image_rect_scene.instantiate() as Control
	add_child(heart)
	_hearts.append(heart)

	move_child(heart, _hearts.size() - 1)

	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart.resized.connect(_centre_pivot.bind(heart))

	if animate:
		heart.modulate.a = 0.0
		_animate_heart_added.call_deferred(heart)


func _centre_pivot(heart: Control) -> void:
	heart.pivot_offset = heart.size * 0.5


func _animate_heart_added(heart: Control) -> void:
	if not is_instance_valid(heart) or not _hearts.has(heart):
		return

	_centre_pivot(heart)
	heart.scale = Vector2.ONE * 0.1

	var tween: Tween = create_tween()
	_heart_tweens[heart] = tween

	tween.set_parallel(true)
	tween.tween_property(heart, "modulate:a", 1.0, 0.15)
	tween.tween_property(
		heart, "scale", Vector2.ONE, 0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.chain().tween_callback(func() -> void:
		_heart_tweens.erase(heart)
	)


func _remove_heart(animate: bool) -> void:
	var heart: Control = _hearts.pop_back()

	if _heart_tweens.has(heart):
		var previous_tween: Tween = _heart_tweens[heart]
		previous_tween.kill()
		_heart_tweens.erase(heart)

	if not animate:
		heart.queue_free()
		return

	_centre_pivot(heart)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(heart, "modulate:a", 0.0, 0.2)
	tween.tween_property(
		heart, "scale", Vector2.ZERO, 0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(heart.queue_free)
