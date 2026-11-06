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

var active: bool = true

func _ready() -> void:
	show_correct_visual()

	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)

	shrine_visual.max_uses = upgrade_manager.get_max_upgrades(shrine_type as UpgradeManager.UpgradeType)

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
	if !active:
		return

	if upgrade_manager.try_apply_upgrade(shrine_type as UpgradeManager.UpgradeType):
		if upgrade_manager.is_upgrade_maxed(shrine_type as UpgradeManager.UpgradeType):
			shrine_visual.hide_outline()
			shrine_visual.hide_amount()
			shrine_visual.hide_shrine_light()
			active = false
		shrine_visual.fill()
		_update_cost_label()
	else:
		print("Upgrade failed!")

func _on_interact_area_body_entered(body: Node3D):
	if body is not Player:
		return

	player_in_interact_area = true

	if !upgrade_manager.is_upgrade_maxed(shrine_type as UpgradeManager.UpgradeType):
		shrine_visual.show_outline()

		_update_cost_label()

		shrine_visual.show_amount()

func _on_interact_area_body_exited(body: Node3D):
	if body is not Player:
		return

	player_in_interact_area = false

	shrine_visual.hide_outline()
	shrine_visual.hide_amount()

func _update_cost_label():
	shrine_visual.set_ghost_amount_label (
		upgrade_manager.get_upgrade_cost(shrine_type as UpgradeManager.UpgradeType)
	)