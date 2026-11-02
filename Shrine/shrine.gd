extends StaticBody3D

enum ShrineType {
	Heart,
	Speed,
	Duration,
	Angle
}

@export var shrine_type: ShrineType

@export var upgrade_manager: UpgradeManager

@onready var shrine_visual: ShrineVisual = $ShrineVisual

@onready var interact_area: Area3D = $InteractArea

var player_in_interact_area: bool = false

func _ready() -> void:
	show_correct_visual()

	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)

func _process(_delta: float) -> void:
	if player_in_interact_area and Input.is_action_just_pressed("interact"):
		interact()

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

func interact():
	if upgrade_manager.try_apply_upgrade(shrine_type as UpgradeManager.UpgradeType):
		print("Upgrade!")
	else:
		print("Upgrade failed!")

func _on_interact_area_body_entered(body: Node3D):
	if body is not Player:
		return

	player_in_interact_area = true

func _on_interact_area_body_exited(body: Node3D):
	if body is not Player:
		return

	player_in_interact_area = false
