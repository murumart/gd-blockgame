extends Label3D

@export var chunk: Chunk


func _on_timer_timeout() -> void:
	text = ("pos: " + chunk.name +
			#"\ndata: " + str(chunk.data) +
			"\nblock_data size: " + str(chunk.data.block_data.size()))
