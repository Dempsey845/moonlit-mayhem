extends Node3D

@onready var player: Player = $Player
@onready var intro_camera: Camera3D = $TransitionCamera


func _ready() -> void:
	BackgroundMusic.play_graveyard()


func warm_up_effects() -> void:
	if DisplayServer.get_name() == "headless":
		return

	# Draw these meshes in the gameplay viewport so Compatibility also sees them.
	var ghost := $Ghosts/Ghost/Ghost/Cylinder as MeshInstance3D
	var shrine := $NavigationRegion3D/Shrine/ShrineVisual as ShrineVisual
	var ghost_material := ghost.material_override.duplicate() as ShaderMaterial
	ghost_material.set_shader_parameter("death_progress", 0.45)
	_add_warmup_mesh(ghost, Vector3(-0.65, 0.0, -3.0), ghost_material)
	var shrine_preview := _add_warmup_mesh(shrine.shrine_mesh, Vector3(0.65, 0.0, -3.0))
	shrine_preview.material_overlay = shrine.outline_material.duplicate() as ShaderMaterial
	shrine_preview.material_overlay.set_shader_parameter("outline_strength", 1.0)
	_add_warmup_mesh(shrine.ghost_icon, Vector3(0.65, 0.55, -3.0))

	await player.warm_up_hit_particles(intro_camera)
	for preview in intro_camera.get_children():
		if preview.has_meta(&"effect_warmup"):
			preview.hide()
			preview.queue_free()


func _add_warmup_mesh(source: MeshInstance3D, offset: Vector3, material: Material = null) -> MeshInstance3D:
	var preview := MeshInstance3D.new()
	preview.mesh = source.mesh
	preview.material_override = material if material != null else source.material_override
	preview.cast_shadow = source.cast_shadow
	preview.position = offset - source.get_aabb().get_center()
	preview.set_meta(&"effect_warmup", true)
	intro_camera.add_child(preview)
	return preview
