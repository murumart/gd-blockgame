extends Node2D

var _selected_first := Vector2i()


func _process(_delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not _selected_first:
			_selected_first = Vector2i(get_global_mouse_position())
			print(_selected_first)
		else:
			raycast(_selected_first,
					(get_global_mouse_position() - Vector2(_selected_first)).normalized())
			_selected_first = Vector2i()
	queue_redraw()


func _draw() -> void:
	if _selected_first:
		var vector := (get_global_mouse_position() - Vector2(_selected_first)).normalized()
		draw_line(_selected_first, Vector2(_selected_first) + vector, Color.GREEN)


func raycast(start_pos: Vector2i, direction: Vector2) -> void:
	var next_d := Vector2(
		signf(direction.x),
		signf(direction.y)
	)
