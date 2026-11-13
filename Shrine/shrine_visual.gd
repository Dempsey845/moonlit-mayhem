class_name ShrineVisual
extends Node3D

@onready var shrine_mesh: MeshInstance3D = $Shrine

@onready var heart_mesh: MeshInstance3D = $Heart
@onready var speed_mesh: MeshInstance3D = $Shoe
@onready var duration_mesh: MeshInstance3D = $MoonDuration
@onready var angle_mesh: MeshInstance3D = $MoonAngle
@onready var ghost_icon: MeshInstance3D = $GhostIcon
@onready var ghost_amount_label: Label3D = $GhostAmountLabel
@onready var shrine_light: OmniLight3D = $OmniLight3D
@onready var bowl_fill: MeshInstance3D = $BowlFill

var outline_material: ShaderMaterial

var current_uses: int = 0
var max_uses: int

var outline_tween: Tween

var amount_tween: Tween
var icon_tween: Tween

var start_fill_y: float = 0.014
var fill_max_y: float = 0.1

var _shrine_light_tween: Tween

func _ready() -> void:
	outline_material = shrine_mesh.material_overlay.duplicate() as ShaderMaterial
	shrine_mesh.material_overlay = null
	ghost_amount_label.visible = false
	ghost_icon.visible = false

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
	if target == 0.0 and shrine_mesh.material_overlay == null:
		return

	if outline_tween:
		outline_tween.kill()

	shrine_mesh.material_overlay = outline_material
	outline_tween = create_tween()
	outline_tween.set_trans(Tween.TRANS_SINE)
	outline_tween.set_ease(Tween.EASE_IN_OUT)
	outline_tween.tween_property(outline_material, "shader_parameter/outline_strength", target, duration)
	if target == 0.0:
		outline_tween.tween_callback(func(): shrine_mesh.material_overlay = null)


func _set_amount_transparency(target: float, duration: float) -> void:
	if amount_tween:
		amount_tween.kill()

	ghost_amount_label.visible = true

	amount_tween = create_tween()
	amount_tween.set_trans(Tween.TRANS_SINE)
	amount_tween.set_ease(Tween.EASE_IN_OUT)

	amount_tween.tween_method(
		func(value: float):
			ghost_amount_label.transparency = value,
		ghost_amount_label.transparency,
		target,
		duration
	).finished.connect(func():
		if ghost_amount_label.transparency <= 0:
			ghost_amount_label.visible = true
		else:
			ghost_amount_label.visible = false
	)

func _set_icon_transparency(target: float, duration: float) -> void:
	if icon_tween:
		icon_tween.kill()

	ghost_icon.visible = true

	icon_tween = create_tween()
	icon_tween.set_trans(Tween.TRANS_SINE)
	icon_tween.set_ease(Tween.EASE_IN_OUT)

	icon_tween.tween_method(
		func(value: float):
			ghost_icon.transparency = value,
		ghost_icon.transparency,
		target,
		duration
	).finished.connect(func():
		if ghost_icon.transparency <= 0:
			ghost_icon.visible = true
		else:
			ghost_icon.visible = false
	)

func set_ghost_amount_label(cost: int):
	ghost_amount_label.text = "x" + str(cost)

func hide_shrine_light(duration: float = 0.5) -> void:
	if _shrine_light_tween and _shrine_light_tween.is_running():
		_shrine_light_tween.kill()

	_shrine_light_tween = create_tween()
	_shrine_light_tween.tween_property(
		shrine_light, "light_energy", 0.0, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shrine_light_tween.tween_callback(shrine_light.hide)

func fill():
	if current_uses >= max_uses:
		return

	var fill_increment_y: float = (fill_max_y - start_fill_y) / max_uses

	bowl_fill.position.y += fill_increment_y

	current_uses += 1
