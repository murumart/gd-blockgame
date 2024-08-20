class_name ChunkData extends Resource

const BLOCKS_IN_CHUNK := Chunk.SIZE.x * Chunk.SIZE.y * Chunk.SIZE.z
const BYTES_PER_BLOCK := 2

const BLOCK_DATA_SIZE := BLOCKS_IN_CHUNK * BYTES_PER_BLOCK


var block_data := PackedByteArray()


func _init() -> void:
	block_data.resize(BLOCK_DATA_SIZE)


func set_block_at(idx: int, data: int) -> void:
	assert(data < 0xFFFF, "block overflow")
	idx *= BYTES_PER_BLOCK
	block_data[idx] = data


func get_block_at(idx: int) -> int:
	idx *= BYTES_PER_BLOCK
	return block_data[idx]


static func pos_to_index(pos: Vector3) -> int:
	return int(
			pos.y
			+ pos.z * Chunk.SIZE.y
			+ pos.x * Chunk.SIZE.z * Chunk.SIZE.y)
