class_name ChunkLoader extends Node3D

signal changed_chunk(to: Vector3)

## [World]s use the position of these to load chunks.

@export_range(1, 32) var load_distance := 3 ## How many circles to load chunks around this loader.

var old_chunk: Vector3


func _process(delta: float) -> void:
	var current_chunk := World.global_pos_to_chunk_pos(global_position)
	if current_chunk != old_chunk:
		changed_chunk.emit(current_chunk)
	old_chunk = current_chunk
