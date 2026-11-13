extends Node

const LOADING_SCREEN := preload("res://Systems/Loading/loading_screen.tscn")

var is_loading := false


func load_gameplay(path: String, transition: TransitionUI) -> bool:
	if is_loading:
		return false

	is_loading = true
	await transition.transition()

	var tree := get_tree()
	var screen := LOADING_SCREEN.instantiate() as CanvasLayer
	add_child(screen)
	var status := screen.get_node("%Status") as Label
	var progress := screen.get_node("%Progress") as ProgressBar

	# Paint the overlay before a single-threaded web build starts loading.
	await _wait_for_draw()
	var scene := await _load_scene(path, progress)
	if scene == null:
		return await _show_failure(screen, status, path)

	status.text = "Preparing graveyard…"
	progress.value = 0.85
	await _wait_for_draw()

	tree.paused = true
	var error := tree.change_scene_to_packed(scene)
	if error != OK:
		tree.paused = false
		return await _show_failure(screen, status, path)

	await tree.scene_changed
	status.text = "Preparing effects…"
	progress.value = 0.95
	if tree.current_scene.has_method("warm_up_effects"):
		await tree.current_scene.warm_up_effects()
	progress.value = 1.0
	await _wait_for_draw()

	screen.queue_free()
	tree.paused = false
	is_loading = false
	return true


func _load_scene(path: String, progress: ProgressBar) -> PackedScene:
	if OS.has_feature("web") and not OS.has_feature("threads"):
		return ResourceLoader.load(path, "PackedScene") as PackedScene

	if ResourceLoader.load_threaded_request(path, "PackedScene") != OK:
		return null

	var loaded: Array = []
	while true:
		match ResourceLoader.load_threaded_get_status(path, loaded):
			ResourceLoader.THREAD_LOAD_LOADED:
				return ResourceLoader.load_threaded_get(path) as PackedScene
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				if not loaded.is_empty():
					progress.value = float(loaded[0]) * 0.8
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_FAILED:
				# Release the completed request so a retry can start a new one.
				ResourceLoader.load_threaded_get(path)
				return null
			_:
				return null
	return null


func _show_failure(screen: CanvasLayer, status: Label, path: String) -> bool:
	push_error("Could not load gameplay scene: %s" % path)
	status.text = "Could not load the graveyard. Returning to the menu…"
	await get_tree().create_timer(2.0).timeout
	screen.queue_free()
	is_loading = false
	return false


func _wait_for_draw() -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
