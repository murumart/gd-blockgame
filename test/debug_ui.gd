extends Control

@export var camera: Camera3D
@export var world: World

@onready var label: Label = $Label
@onready var recenterer: Node = world.get_node("Recenterer")

func _physics_process(_delta: float) -> void:
	label.text = get_text()


func get_text() -> String:
	var chunk_pos_old := World.world_pos_to_chunk_pos(camera.global_position)
	var chunk_pos := World.world_pos_to_chunk_pos(camera.global_position + world.world_position)
	return (
			"fps: " + str(Engine.get_frames_per_second())
			+ "\npos: " + str(camera.global_position)
			+ "\nchunk_pos_old: " + str(chunk_pos_old)
			+ "\nchunk_pos: " + str(chunk_pos)
			+ "\nworld_pos: " + str(world.world_position)
			+ "\npos_in_chunk: " + str(camera.global_position.round() - chunk_pos * Vector3(Chunk.SIZE))
			+ "\nrecenter_region: " + str(recenterer._last_region_position)
			#+ "\ngen_queue_size: " + str(world.world_generator._queue.size())
	)
