extends Label3D

@export var chunk: Chunk


func _on_timer_timeout() -> void:
	text = ("pos: " + chunk.name
			+ "\nload_step: " + str(Chunk.LoadSteps.find_key(chunk.load_step))
			+ "\nblock_data size: " + str(chunk.data.block_data.size())
			+ "\nhistory: " + str(chunk._history)
	)
