extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 25.0
@export var deceleration: float = 30.0

func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_back"
	)

	var direction: Vector3 = Vector3(input.x, 0.0, input.y)
	var target_velocity: Vector3 = direction * speed
	var change_rate: float = acceleration if direction != Vector3.ZERO else deceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, change_rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, change_rate * delta)

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	move_and_slide()