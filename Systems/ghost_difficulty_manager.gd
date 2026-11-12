class_name GhostDifficultyManager
extends Node

@export var ghost_spawner: GhostSpawner

var max_ghost_flee_speed: float = 8.0
var ghost_flee_speed_increment: float = 0.25

var max_ghost_chase_speed: float = 7.0
var ghost_chase_speed_increment: float = 0.175

var current_ghost_flee_speed: float
var current_ghost_chase_speed: float

func _ready() -> void:
    current_ghost_flee_speed = ghost_spawner.ghosts[0].flee_speed
    current_ghost_chase_speed = ghost_spawner.ghosts[0].chase_speed

func increment_difficulty():
    current_ghost_flee_speed = minf(
        current_ghost_flee_speed + ghost_flee_speed_increment, 
        max_ghost_flee_speed
    )

    current_ghost_chase_speed = minf(
        current_ghost_chase_speed + ghost_chase_speed_increment,
        max_ghost_chase_speed
    )

    for ghost: Ghost in ghost_spawner.ghosts:
        ghost.flee_speed = current_ghost_flee_speed
        ghost.chase_speed = current_ghost_chase_speed
    