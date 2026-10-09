extends RichTextLabel

@export var world: World
@export var cam: Camera3D


func _physics_process(_delta: float) -> void:
	var txt := "Debug"
	txt += "\nFps: " + str(Engine.get_frames_per_second())
	txt += "\nTarget Pos: " + str(world.chunk_load_center.position)
	txt += "\nCam Pos: " + str(cam.global_position)
	txt += "\nTarget Chunk Pos: " + str(world.get_center_chunk())
	#txt += "\nChunk Generating: " + str(world.chunks._THREADACCESS_chunk_to_load)
	txt += " (" + str(world.chunks._chunks_to_load_queue.size()) + " queued)"
	txt += " (" + str(world.chunks._last_center) + " around)"
	#txt += " (" + str(world.chunks._THREADACCESS_chunk_to_load.distance_squared_to(world.get_center_chunk())) + " distance)"
	text = txt
