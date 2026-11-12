extends Node

const SPAWN_DELAY: float = 2.0

@export var moonlight: Moonlight
@export var player: Player
@export var ghost_spawner: GhostSpawner
@export var ghost_counter: GhostCounter
@export var health_pickup_spawner: HealthPickupSpawner
@export var ghost_difficulty_manager: GhostDifficultyManager
@export_range(0.0, 30.0) var moon_light_follow_speed: float = 12.0

var is_moonlight_following: bool = false

var _wave_size: int = 0
var _spawn_pending: bool = false


func _ready() -> void:
	set_process(false)

	if moonlight == null or player == null or ghost_spawner == null:
		push_error("Assign the moonlight, player and ghost spawner.")
		return

	moonlight.target_entered_light.connect(_on_target_entered_light)
	moonlight.target_exited_light.connect(_on_target_exited_light)
	moonlight.non_target_entered_light.connect(
		_on_moonlight_non_target_entered
	)
	ghost_spawner.all_ghosts_inactive.connect(_on_all_ghosts_inactive)

	moonlight.current_target = player

	if not ghost_spawner.is_node_ready():
		await ghost_spawner.ready

	_wave_size = clampi(
		ghost_spawner.start_ghosts,
		0,
		ghost_spawner.max_ghosts
	)

	await get_tree().create_timer(3.0).timeout

	_spawn_wave_after_delay()


func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(moonlight):
		set_process(false)
		return

	var weight: float = 1.0 - exp(-moon_light_follow_speed * delta)
	var light_position: Vector3 = moonlight.global_position

	light_position.x = lerpf(
		light_position.x, player.global_position.x, weight
	)
	light_position.z = lerpf(
		light_position.z, player.global_position.z, weight
	)

	moonlight.global_position = light_position


func _on_target_entered_light() -> void:
	_set_moonlight_following(true)


func _on_target_exited_light() -> void:
	_set_moonlight_following(false)


func _set_moonlight_following(following: bool) -> void:
	is_moonlight_following = following
	set_process(following)

	for ghost in ghost_spawner.ghosts:
		if is_instance_valid(ghost) and ghost.state != Ghost.State.DEAD:
			ghost.set_fleeing(following)


func _on_moonlight_non_target_entered(body: Node3D) -> void:
	if is_moonlight_following and body is Ghost:
		if ghost_spawner.deactivate_ghost(body):
			ghost_counter.add_ghost()


func _on_all_ghosts_inactive() -> void:
	if _spawn_pending:
		return

	_wave_size = mini(_wave_size + 1, ghost_spawner.max_ghosts)
	_spawn_wave_after_delay()


func _spawn_wave_after_delay() -> void:
	if _spawn_pending or _wave_size <= 0:
		return

	_spawn_pending = true
	await get_tree().create_timer(SPAWN_DELAY).timeout

	if not is_instance_valid(ghost_spawner):
		_spawn_pending = false
		return

	var start_state: Ghost.State = Ghost.State.CHASE
	if is_moonlight_following:
		start_state = Ghost.State.FLEE

	ghost_spawner.spawn_ghosts(_wave_size, start_state)
	_spawn_pending = false

	var spawn_pickup: bool = randi_range(0, 2) == 1
	if spawn_pickup:
		health_pickup_spawner.try_spawn_health_pickup()

	ghost_difficulty_manager.increment_difficulty()