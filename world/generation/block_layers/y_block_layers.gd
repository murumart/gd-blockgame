class_name YBlockLayers extends Resource

@export var layers: Array[BlockLayer]


func get_block(top_y: int, position_y: int) -> int:
	for layer in layers:
		var distance := top_y - position_y
		if distance < 0:
			return BlockTypes.AIR
		if layer.distance >= distance:
			return layer.block_type
	return layers.back().block_type
