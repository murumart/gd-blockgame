class_name ChunkLoader extends Node3D

## [World]s use the position of these to load chunks.

@export_range(1, 32) var load_distance := 3 ## How many circles to load chunks around this loader.


func _physics_process(delta: float) -> void:
	position += Vector3(0, -0.5, -1) * delta * 10
