extends Node3D

@export var world: World


func _process(delta: float) -> void:
	scale = Chunks.CHUNK_SIZE
	position = world.get_center_chunk() * Chunks.CHUNK_SIZE
