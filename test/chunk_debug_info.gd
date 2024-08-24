extends Label3D

@export var chunk: Chunk


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_page_up"):
		do_text()
		show()
	elif event.is_action_pressed("ui_page_down"):
		hide()


func do_text() -> void:
	text = ("pos: " + chunk.name
			+ "\nload_step: " + str(Chunk.LoadSteps.find_key(chunk.load_step))
			+ "\nblock_data size: " + str(chunk.data.block_data.size())
			+ "\nhistory: " + str(chunk._history)
	)
