class_name TextAnimation
extends Label

@export var character_delay: float = 0.04

var _animation_id: int = 0


func type_text(new_text: String) -> void:
	_animation_id += 1
	var current_id: int = _animation_id

	text = new_text
	visible_characters = 0

	var total_characters: int = get_total_character_count()

	while visible_characters < total_characters:
		await get_tree().create_timer(character_delay).timeout

		if current_id != _animation_id:
			return

		visible_characters += 1


func untype_text() -> void:
	_animation_id += 1
	var current_id: int = _animation_id

	if visible_characters < 0:
		visible_characters = get_total_character_count()

	while visible_characters > 0:
		await get_tree().create_timer(character_delay).timeout

		if current_id != _animation_id:
			return

		visible_characters -= 1

func skip_animation() -> void:
	_animation_id += 1
	visible_characters = -1