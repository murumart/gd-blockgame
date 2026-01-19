extends RichTextLabel

@export var world: World


func _physics_process(_delta: float) -> void:
	var txt := "Debug"
	txt += "\nTarget Pos: " + str(world.chunk_load_center.position)
	txt += "\nTarget Chunk Pos: " + str(world.get_center_chunk())
	txt += "\nChunk Generating: " + str(world.chunks._THREADACCESS_chunk_to_load)
	txt += " (" + str(world.chunks._chunks_to_load_queue.size()) + " queued)"
	txt += " (" + str(world.chunks._last_center) + " around)"
	text = txt
