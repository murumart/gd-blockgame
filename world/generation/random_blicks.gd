class_name RandomBlicks extends GeneratorSettings

@export_range(0.0, 1.0) var air_chance := 0.85

var rng := RandomNumberGenerator.new()


func get_block_at(pos: Vector3) -> int:
	rng.seed = hash(pos)
	return BlockTypes.AIR if rng.randf() < air_chance else rng.randi_range(1, 3)
	#return super(pos)
