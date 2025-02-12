class_name NoiseLayers extends GeneratorSettings

@export var layers: Array[NoiseLayersNoiseLayer]
@export var base_block: int
@export var max_y: int
@export var y_distance_reduction: float = 0.05

@export var block_layers: YBlockLayers


func get_block_at(global_position: Vector3) -> int:
	var addon := _get_addons_block(global_position)
	if not should_addon_block_be_ignored(addon):
		return addon
	
	var y_distance := global_position.y - max_y
	
	var density := 0.0
	for layer in layers:
		density += layer.get_density(global_position)
	
	if global_position.y > max_y:
		density -= y_distance * y_distance_reduction
	
	if density >= 0:
		return base_block
	
	return BlockTypes.AIR
