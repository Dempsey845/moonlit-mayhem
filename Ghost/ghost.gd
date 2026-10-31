extends CharacterBody3D

enum State { CHASE, FLEE }

@export var player: Node3D
@export var chase_speed: float = 3.0
@export var flee_speed: float = 4.0
@export var flee_distance: float = 8.0
@export var repath_interval: float = 0.25

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var state: State = State.CHASE
var repath_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if NavigationServer3D.map_get_iteration_id(
		navigation_agent.get_navigation_map()
	) == 0:
		return

	repath_timer -= delta

	if repath_timer <= 0.0:
		update_target()
		repath_timer = repath_interval

	var direction: Vector3 = Vector3.ZERO

	if not navigation_agent.is_navigation_finished():
		var next_position: Vector3 = navigation_agent.get_next_path_position()
		direction = next_position - global_position
		direction.y = 0.0
		direction = direction.normalized()

	var speed: float = chase_speed if state == State.CHASE else flee_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func update_target() -> void:
	match state:
		State.CHASE:
			navigation_agent.target_position = player.global_position

		State.FLEE:
			var away: Vector3 = global_position - player.global_position
			away.y = 0.0

			if away.length_squared() < 0.01:
				away = Vector3.RIGHT

			var flee_target: Vector3 = global_position + away.normalized() * flee_distance

			navigation_agent.target_position = NavigationServer3D.map_get_closest_point(
				navigation_agent.get_navigation_map(),
				flee_target
			)


func set_fleeing(fleeing: bool) -> void:
	state = State.FLEE if fleeing else State.CHASE
	repath_timer = 0.0