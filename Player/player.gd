class_name Player
extends CharacterBody3D

@export var health: PlayerHealth

@export var speed: float = 5.0
@export var acceleration: float = 25.0
@export var deceleration: float = 30.0
@export var turn_speed: float = 12.0
@export var model_forward_offset_degrees: float = 0.0

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var minimum_pitch_degrees: float = -65.0
@export var maximum_pitch_degrees: float = 35.0

@export_group("Animation")
@export var animation_blend_speed: float = 8.0

@onready var visual: Node3D = $PumpkinVisual
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var hit_particles: Node3D = $HitParticles
@onready var step: AudioStreamPlayer = $Step
@onready var boing: AudioStreamPlayer = $Boing

var move_blend: float = 0.0

func _ready() -> void:
	spring_arm.add_excluded_object(get_rid())
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		var gpu_particles := hit_particles as GPUParticles3D
		var cpu_particles := CPUParticles3D.new()
		cpu_particles.convert_from_particles(gpu_particles)
		cpu_particles.transform = gpu_particles.transform
		cpu_particles.emitting = false
		cpu_particles.cast_shadow = gpu_particles.cast_shadow
		gpu_particles.replace_by(cpu_particles)
		gpu_particles.queue_free()
		hit_particles = cpu_particles
	# camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	health.damaged.connect(_on_damaged)

	health.died.connect(func(): $PlayerDeath.play())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(minimum_pitch_degrees),
			deg_to_rad(maximum_pitch_degrees)
		)


func _physics_process(delta: float) -> void:
	var move_input: Vector2 = Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_back"
	)

	var direction: Vector3 = camera_pivot.global_basis * Vector3(move_input.x, 0.0, move_input.y)
	direction.y = 0.0
	direction = direction.normalized() * move_input.length()

	var target_velocity: Vector3 = direction * speed
	var change_rate: float = acceleration if not move_input.is_zero_approx() else deceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, change_rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, change_rate * delta)

	if not direction.is_zero_approx():
		var target_angle: float = atan2(direction.x, direction.z)
		target_angle += deg_to_rad(model_forward_offset_degrees)
		visual.global_rotation.y = lerp_angle(
			visual.global_rotation.y, target_angle, 1.0 - exp(-turn_speed * delta)
		)

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	if velocity == Vector3.ZERO:
		boing.stop()
		step.stop()

	move_and_slide()

	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var target_blend: float = clampf(horizontal_speed / maxf(speed, 0.001), 0.0, 1.0)

	move_blend = lerpf(
		move_blend,
		target_blend,
		1.0 - exp(-animation_blend_speed * delta)
	)

	animation_tree.set("parameters/MoveBlend/blend_amount", move_blend)

func _on_damaged(_amount: int):
	_restart_hit_particles()
	$HitPlayer.play()



func _restart_hit_particles() -> void:
	if hit_particles is GPUParticles3D:
		(hit_particles as GPUParticles3D).restart()
	else:
		(hit_particles as CPUParticles3D).restart()


func warm_up_hit_particles(view_camera: Camera3D) -> void:
	var original_transform := hit_particles.transform
	var original_process_mode := hit_particles.process_mode
	hit_particles.process_mode = Node.PROCESS_MODE_ALWAYS
	hit_particles.global_position = view_camera.to_global(Vector3(0.0, 0.0, -2.5))
	_restart_hit_particles()
	# Wait for a complete burst before moving the emitter back to the player.
	var duration := float(hit_particles.get("lifetime")) * 2.0 + 0.1
	await get_tree().create_timer(duration).timeout
	hit_particles.transform = original_transform
	hit_particles.process_mode = original_process_mode
