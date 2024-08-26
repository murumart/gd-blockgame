class_name SineLayers extends GeneratorSettings

#if (cos((global_position.x + 410) * 0.01) * 100 + sin(global_position.z * 0.01) * 100 < -110):
		#return 2
	#var ypos := int((sin(global_position.x * 0.1) * cos(global_position.z * 0.1) * 16.0
		#+ cos(global_position.x * 0.001) * sin(global_position.z * 0.001) * 500))
	#if global_position.y == ypos:
		#return 3
	#if (global_position.y < ypos - 3):
		#return 1
	#elif global_position.y < ypos:
		#return 2 if randf() < 0.5 else 1
	#return 0

@export var layers: Array[SineLayersSineLayer]
@export var block_layers: YBlockLayers


func get_block_at(global_position: Vector3) -> int:
	var addon := _get_addons_block(global_position)
	if not should_addon_block_be_ignored(addon):
		return addon
	var ypos := 0.0
	for layer in layers:
		var layer_y := layer.get_layer_y(global_position)
		if layer.mode == SineLayersSineLayer.Modes.ADD:
			ypos += layer_y
		else:
			if ypos == 0.0:
				ypos = 1.0
			ypos *= layer_y
	return block_layers.get_block(int(ypos), int(global_position.y))
