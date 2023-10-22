class_name Chunk extends NullChunk


func _ready() -> void:
	mesh = $ChunkMesh
	mesh.chunk_position = chunk_position
	_calc_blocks()


func _build() -> void:
	_build_mesh()


func _build_mesh() -> void:
	#Util.measure_time(mesh.build_mesh.bind(blocks))
	mesh.build_mesh(blocks)


func _calc_blocks() -> void:
	if blocks.is_empty():
		blocks.resize(VOLUME)
	for x in WIDTH:
		for y in HEIGHT:
			for z in WIDTH:
				var gx := chunk_position.x * WIDTH + x
				var gy := chunk_position.y * HEIGHT + y
				var gz := chunk_position.z * WIDTH + z
				if Noises.noise1.get_noise_3d(gx, gy, gz) * 3 < 1.2 and\
					Noises.noise1.get_noise_2d(gx, gz) * (
						Noises.noise1.get_noise_2d(gx + 800, gz + 800) * 80
					) > gy and not (
						Noises.noise1.get_noise_3d(gz + 100, gy, gx - 100) > -0.11 and
						Noises.noise1.get_noise_3d(gz + 100, gy, gx - 100) < 0.01
					):
					set_block(x, y, z, 1)


func get_block(x: int, y: int, z: int) -> int:
	if blocks.is_empty():
		_calc_blocks()
	if (x >= WIDTH or x < 0) or (y >= WIDTH or y < 0) or (z >= WIDTH or z < 0):
		return 0
	return blocks[x + WIDTH * z + AREA * y]


func set_block(x: int, y: int, z: int, block: int) -> bool:
	if blocks.is_empty():
		_calc_blocks()
	if (x >= WIDTH or x < 0) or (y >= WIDTH or y < 0) or (z >= WIDTH or z < 0):
		return false
	blocks[x + WIDTH * z + AREA * y] = block
	return true
	
