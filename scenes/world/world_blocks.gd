class_name WorldBlocks extends Node

static var blocks := {}


func _init() -> void:
	var pregen_size := 2
	for x in range(-pregen_size, pregen_size):
		for y in  range(-pregen_size, pregen_size):
			for z in  range(-pregen_size, pregen_size):
				blocks[Vector3i(x, y, z)] = PackedInt32Array()
				WorldBlocks.gen_blocks(Vector3i(x, y, z))
				print("chunk %s blocks generated." % Vector3i(x, y, z))
	# test
	var pos := Vector3i(34, 384, 32)
	var cpos := WorldBlocks.is_in_which_chunk(pos)
	print(cpos)
	print(WorldBlocks.to_in_chunk_position(pos, cpos))
	print(WorldBlocks.get_block(pos.x, pos.y, pos.z))
	print(WorldBlocks._get_block(cpos,
			WorldBlocks.to_in_chunk_position(pos, cpos)))


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
	for x in Chunk.WIDTH:
		for y in Chunk.HEIGHT:
			for z in Chunk.WIDTH:
				_world_per_block(chunk_position, Vector3i(x, y, z))
	return blocks[chunk_position]


static func _world_per_block(cpos: Vector3i, bpos: Vector3i) -> void:
	var gx := cpos.x * Chunk.WIDTH + bpos.x
	var gy := cpos.y * Chunk.HEIGHT + bpos.y
	var gz := cpos.z * Chunk.WIDTH + bpos.z
	var n := Noises.noise1
	var surface_height := 0 #n.get_noise_2d(gx, gz) * 30
	var grubbly_mult := n.get_noise_2d(gx * 0.2, gz * 0.2) + 1
	
	surface_height += (
		n.get_noise_2d(
			gx * 10 * grubbly_mult, gz * 10 * grubbly_mult) *
			7 * (0.8 - grubbly_mult) +
		pow(
			n.get_noise_2d(gx * 0.02 + 391, gz * 0.02 + 358
		) * 3, 5) * 200
	)
	
	if gy <= surface_height:
		_set_block(cpos, bpos, 1)


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

# old worldgen
#if Noises.noise1.get_noise_3d(gx, gy, gz) * 3 < 1.4 and\
#	Noises.noise1.get_noise_2d(gx, gz) * (
#		Noises.noise1.get_noise_2d(gx + 800, gz + 800) * 160 /
#		(Noises.noise1.get_noise_2d(gz - 66, gx + 43) + 1.01)
#	) > gy \
#	and not (
#		Noises.noise1.get_noise_3d(gz + 100, gy, gx - 100) - gy * 0.5 > -0.11 and
#		Noises.noise1.get_noise_3d(gz + 100, gy, gx - 100) - gy * 0.5 < 0.01
#	):
#	_set_block(chunk_position, Vector3i(x, y, z), 1)
