class_name ChunkLoader extends Node3D

## [World]s use the position of these to load chunks.

@export_range(1, 32) var load_distance := 3 ## How many circles to load chunks around this loader.
