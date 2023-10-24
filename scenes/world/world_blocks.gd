class_name WorldBlocks extends Node

static var blocks := {}


func _init() -> void:
	var pregen_size := 2
	for x in range(-pregen_size, pregen_size):
		for y in  range(-pregen_size, pregen_size):
			for z in  range(-pregen_size, pregen_size):
				blocks[Vector3i(x, y, z)] = PackedInt32Array()
				gen_blocks(Vector3i(x, y, z))
				print("chunk %s blocks generated." % Vector3i(x, y, z))
	# test
	var pos := Vector3i(34, 384, 32)
	var cpos := is_in_which_chunk(pos)
	print(cpos)
	print(to_in_chunk_position(pos, cpos))
	print(get_block(pos.x, pos.y, pos.z))
	print(_get_block(cpos,
			to_in_chunk_position(pos, cpos)))


static func is_in_which_chunk(bpos: Vector3i) -> Vector3i:
	return Vector3i(
		floori(bpos.x / float(Chunk.WIDTH)),
		floori(bpos.y / float(Chunk.HEIGHT)),
		floori(bpos.z / float(Chunk.WIDTH))
	)


static func to_in_chunk_position(
		bpos: Vector3i, cpos: Vector3i) -> Vector3i:
	return Vector3i(
		bpos.x - cpos.x * Chunk.WIDTH,
		bpos.y - cpos.y * Chunk.HEIGHT,
		bpos.z - cpos.z * Chunk.WIDTH,
	)


static func gen_blocks(chunk_position: Vector3i) -> PackedInt32Array:
	if blocks.get(chunk_position, null) == null or\
			blocks.get(chunk_position, []).size() < 1:
		var nb := PackedInt32Array()
		nb.resize(Chunk.VOLUME)
		blocks[chunk_position] = nb
	var cx := chunk_position.x
	var cy := chunk_position.y
	var cz := chunk_position.z
	for x in Chunk.WIDTH:
		for y in Chunk.HEIGHT:
			for z in Chunk.WIDTH:
				var gx := cx * Chunk.WIDTH + x
				var gy := cy * Chunk.HEIGHT + y
				var gz := cz * Chunk.WIDTH + z
				if Noises.noise1.get_noise_3d(gx, gy, gz) * 3 < 1.4 and\
					Noises.noise1.get_noise_2d(gx, gz) * (
						Noises.noise1.get_noise_2d(gx + 800, gz + 800) * 80
					) > gy and not (
						Noises.noise1.get_noise_3d(gz + 100, gy, gx - 100) > -0.11 and
						Noises.noise1.get_noise_3d(gz + 100, gy, gx - 100) < 0.01
					):
					_set_block(chunk_position, Vector3i(x, y, z), 1)
	return blocks[chunk_position]


static func set_block(x: int, y: int, z: int, block: int) -> void:
	var cpos := is_in_which_chunk(Vector3i(x, y, z))
	var bpos := to_in_chunk_position(Vector3i(x, y, z), cpos)
	if not blocks.get(cpos, null):
		var nb := PackedInt32Array()
		nb.resize(Chunk.VOLUME)
		blocks[cpos] = nb
	_set_block(cpos, bpos, block)
	#blocks[cpos][x + Chunk.WIDTH * z + Chunk.AREA * y] = block


static func _set_block(cpos: Vector3i, bpos: Vector3i, block: int) -> void:
	blocks[cpos][bpos.x + Chunk.WIDTH * bpos.z + Chunk.AREA * bpos.y] = block


static func get_block(x: int, y: int, z: int) -> int:
	var cpos := is_in_which_chunk(Vector3i(x, y, z))
	var bpos := to_in_chunk_position(Vector3i(x, y, z), cpos)
	if not blocks.get(cpos, null):
		gen_blocks(cpos)
	return _get_block(cpos, bpos)


static func _get_block(cpos: Vector3i, bpos: Vector3i) -> int:
	return blocks[cpos][bpos.x + Chunk.WIDTH * bpos.z + Chunk.AREA * bpos.y]


static func get_chunk_blocks(cpos: Vector3i) -> PackedInt32Array:
	if not blocks.get(cpos, null):
		gen_blocks(cpos)
	return blocks.get(cpos)
