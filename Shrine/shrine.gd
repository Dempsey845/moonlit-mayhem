extends StaticBody3D

enum ShrineType {
    Heart,
    Speed,
    Duration,
    Angle
}

@export var shrine_type: ShrineType

@onready var shrine_visual: ShrineVisual = $ShrineVisual

func _ready() -> void:
    show_correct_visual()

func show_correct_visual():
    match shrine_type:
        ShrineType.Heart:
            shrine_visual.heart_mesh.show()
        ShrineType.Speed:
            shrine_visual.speed_mesh.show()
        ShrineType.Duration:
            shrine_visual.duration_mesh.show()
        ShrineType.Angle:
            shrine_visual.angle_mesh.show()

    print("Visual shown")