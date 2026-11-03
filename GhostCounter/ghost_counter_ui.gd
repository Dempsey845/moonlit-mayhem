extends Control

@export var ghost_counter: GhostCounter

@onready var ghost_count_label: Label = $GhostCountLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    ghost_counter.ghost_added.connect(_on_ghost_counter_ghost_added)
    ghost_counter.ghost_removed.connect(_on_ghost_counter_ghost_removed)

func _on_ghost_counter_ghost_added():
    ghost_count_label.text = str(ghost_counter.ghost_count)
    if !animation_player.is_playing():
        animation_player.play("ghost_added")

func _on_ghost_counter_ghost_removed():
    ghost_count_label.text = str(ghost_counter.ghost_count)
    if !animation_player.is_playing():
        animation_player.play("ghost_removed")
