class_name RandomBlicks extends GeneratorSettings

var rng := RandomNumberGenerator.new()


func get_block_at(pos: Vector3) -> int:
	rng.seed = hash(pos)
	return 0 if rng.randf() < 0.75 else rng.randi_range(1, 3)
	#return super(pos)
