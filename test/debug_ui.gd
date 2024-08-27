extends Control

@export var camera: Camera3D
@export var world: World

@onready var label: Label = $Label

func _physics_process(_delta: float) -> void:
	label.text = get_text()


func get_text() -> String:
	var chunk_pos := World.world_pos_to_chunk_pos(camera.global_position)
	return (
			"fps: " + str(Engine.get_frames_per_second())
			+ "\npos: " + str(camera.global_position)
			+ "\nchunk_pos: " + str(chunk_pos)
			+ "\npos_in_chunk: " + str(camera.global_position.round() - chunk_pos * Vector3(Chunk.SIZE))
			#+ "\ngen_queue_size: " + str(world.world_generator._queue.size())
	)
