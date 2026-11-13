class_name Ghost
extends CharacterBody3D

enum State { CHASE, FLEE, DEAD }

@export var player: Node3D
@export var player_health: PlayerHealth
@export var chase_speed: float = 3.0
@export var flee_speed: float = 4.0
@export var repath_interval: float = 0.25
@export var scatter_interval_min: float = 0.7
@export var scatter_interval_max: float = 1.5
@export var attack_cooldown: float = 1.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var ghost_visual: GhostVisual = $Ghost
@onready var attack_area: Area3D = $AttackArea
@onready var dissolve_player: AudioStreamPlayer3D = $DissolvePlayer

var state: State = State.DEAD
var repath_timer: float = 0.0

var original_collision_layer: int
var original_collision_mask: int

var start_position: Vector3

var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0


func _ready() -> void:
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask

	start_position = global_position

	navigation_agent.velocity_computed.connect(_on_velocity_computed)

	animation_player.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_instance_valid(player):
		velocity = Vector3.ZERO
		navigation_agent.velocity = Vector3.ZERO
		return

	attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)

	if (
		state == State.CHASE
		and not is_attacking
		and attack_cooldown_timer <= 0.0
		and animation_player.current_animation != &"revive"
		and attack_area.overlaps_body(player)
	):
		_start_attack()

	if is_attacking:
		navigation_agent.velocity = Vector3.ZERO
		velocity.x = 0.0
		velocity.z = 0.0

		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		return

	if NavigationServer3D.map_get_iteration_id(
		navigation_agent.get_navigation_map()
	) == 0:
		return

	repath_timer -= delta

	var needs_target: bool = repath_timer <= 0.0

	if state == State.FLEE:
		var offset: Vector3 = navigation_agent.target_position - global_position
		offset.y = 0.0

		if offset.length_squared() < 0.25:
			needs_target = true

	if needs_target:
		update_target()

		if state == State.FLEE:
			repath_timer = randf_range(
				scatter_interval_min,
				scatter_interval_max
			)
		else:
			repath_timer = repath_interval

	var direction: Vector3 = Vector3.ZERO

	if not navigation_agent.is_navigation_finished():
		var next_position: Vector3 = navigation_agent.get_next_path_position()
		direction = next_position - global_position
		direction.y = 0.0
		direction = direction.normalized()

	var speed: float = chase_speed if state == State.CHASE else flee_speed
	var desired_velocity: Vector3 = direction * speed

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	navigation_agent.velocity = desired_velocity


func update_target() -> void:
	match state:
		State.CHASE:
			navigation_agent.target_position = player.global_position

		State.FLEE:
			var scatter_target: Vector3 = global_position

			for attempt in range(8):
				scatter_target = NavigationServer3D.map_get_random_point(
					navigation_agent.get_navigation_map(),
					navigation_agent.navigation_layers,
					true
				)

				var offset: Vector3 = scatter_target - global_position
				offset.y = 0.0

				if offset.length_squared() >= 4.0:
					break

			navigation_agent.target_position = scatter_target


func set_fleeing(fleeing: bool) -> void:
	if state == State.DEAD:
		return

	var new_state: State = State.FLEE if fleeing else State.CHASE

	if state == new_state:
		return

	state = new_state

	if is_attacking:
		is_attacking = false
		attack_cooldown_timer = attack_cooldown
		animation_player.play("bob")

	repath_timer = 0.0


func die() -> void:
	if state == State.DEAD:
		return

	if !is_node_ready():
		await ready

	state = State.DEAD
	velocity = Vector3.ZERO
	set_physics_process(false)

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	dissolve_player.play()

	ghost_visual.play_death_effect()


func revive(start_state: State) -> void:
	global_position = start_position
	velocity = Vector3.ZERO
	repath_timer = 0.0

	is_attacking = false
	attack_cooldown_timer = 0.0

	state = start_state

	ghost_visual.reset_death_effect()

	navigation_agent.target_position = start_position

	set_deferred("collision_layer", original_collision_layer)
	set_deferred("collision_mask", original_collision_mask)

	animation_player.play("revive")

	set_physics_process(true)

	await animation_player.animation_finished

	animation_player.play("bob")
	
func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if (
		state == State.DEAD
		or is_attacking
		or not is_instance_valid(player)
	):
		return

	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

	if Vector2(velocity.x, velocity.z).length_squared() > 0.001:
		var target_angle: float = atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(
			rotation.y,
			target_angle,
			1.0 - exp(-10.0 * get_physics_process_delta_time())
		)

	move_and_slide()

func _start_attack() -> void:
	is_attacking = true

	velocity.x = 0.0
	velocity.z = 0.0
	navigation_agent.velocity = Vector3.ZERO

	var direction: Vector3 = player.global_position - global_position
	direction.y = 0.0

	if direction.length_squared() > 0.001:
		rotation.y = atan2(-direction.x, -direction.z)

	ghost_visual.play_attack_animation()


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != &"attack" or not is_attacking:
		return

	is_attacking = false
	attack_cooldown_timer = attack_cooldown
	repath_timer = 0.0

	if state != State.DEAD:
		animation_player.play("bob")

func attack():
	var overlapping_bodies = attack_area.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body is Player:
			player_health.take_damage(1)
			return
