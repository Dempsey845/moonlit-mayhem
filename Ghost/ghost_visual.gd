class_name GhostVisual
extends Node3D

@onready var ghost_mesh: MeshInstance3D = $Cylinder
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var death_tween: Tween

func play_death_effect() -> void:
    if death_tween:
        death_tween.kill()

    ghost_mesh.set_instance_shader_parameter("death_progress", 0.0)

    death_tween = create_tween()
    death_tween.tween_method(
        func(value: float):
            ghost_mesh.set_instance_shader_parameter("death_progress", value),
        0.0,
        1.0,
        0.8
    )
    death_tween.tween_callback(func():
        animation_player.play("RESET")
    )

func reset_death_effect() -> void:
    if death_tween:
        death_tween.kill()

    ghost_mesh.set_instance_shader_parameter("death_progress", 0.0)

func play_attack_animation():
    animation_player.play("attack")