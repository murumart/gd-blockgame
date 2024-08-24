class_name GeneratorSettings extends Resource


func get_block_at(global_position: Vector3) -> int:
	return 1 if global_position.y < 0 else 0
