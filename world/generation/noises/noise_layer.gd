class_name NoiseLayersNoiseLayer extends Resource

@export var noise: FastNoiseLite


func get_density(pos: Vector3) -> float:
	return noise.get_noise_3dv(pos)
