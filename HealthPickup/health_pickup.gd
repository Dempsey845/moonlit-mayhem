
class_name HealthPickup
extends Area3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var heal_player: AudioStreamPlayer3D = $HealPlayer

var player_health: PlayerHealth
var collected: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

    heal_player.finished.connect(func():
        queue_free()
    )

func start_idle_animation():
    animation_player.play("idle")

func _on_body_entered(body: Node3D):
    if body is not Player:
        return

    if collected:
        return

    animation_player.play("pickup")

    heal_player.play()

    player_health.heal(1)

    collected = true