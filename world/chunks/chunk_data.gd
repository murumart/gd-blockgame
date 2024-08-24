class_name ChunkData extends Resource

const BLOCKS_IN_CHUNK := Chunk.SIZE.x * Chunk.SIZE.y * Chunk.SIZE.z
const BYTES_PER_BLOCK := 2
const BLOCK_DATA_SIZE := BLOCKS_IN_CHUNK * BYTES_PER_BLOCK
const SIDES_COUNT := 6
const SIDE_CHECKS: PackedVector3Array = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.DOWN,
	Vector3.UP,
]
enum SIDES {NORTH, SOUTH, WEST, EAST, BOTTOM, TOP}
static var DEFAULT_BLOCK_DATA: PackedByteArray = []

var block_data := PackedByteArray()


func clear_block_data() -> void:
	block_data.clear()


func init_block_data() -> void:
	block_data = DEFAULT_BLOCK_DATA.duplicate()


func set_block_at(idx: int, data: int) -> void:
	#assert(data < 0xFFFF, "block overflow")
	idx *= BYTES_PER_BLOCK
	if block_data.size() == BYTES_PER_BLOCK and data != get_block_at(0):
		init_block_data()
	block_data[idx] = data


func get_block_at(idx: int) -> int:
	if block_data.size() == BYTES_PER_BLOCK:
		return block_data.decode_u16(0)
	idx *= BYTES_PER_BLOCK
	#assert(not (idx < 0 or idx > block_data.size() - 2))
	return block_data.decode_u16(idx)


func set_single_block_type(data: int) -> void:
	clear_block_data()
	block_data.resize(BYTES_PER_BLOCK)
	block_data.encode_u16(0, data)


func get_block_type_from_pos(pos: Vector3) -> BlockType:
	return BlockTypes.get_block(get_block_at(ChunkData.pos_to_index(pos)))


static func _static_init() -> void:
	DEFAULT_BLOCK_DATA.resize(BLOCK_DATA_SIZE)
	for x in BLOCKS_IN_CHUNK:
		DEFAULT_BLOCK_DATA.encode_u16(x * BYTES_PER_BLOCK, 3)


static func pos_to_index(pos: Vector3) -> int:
	return int(
			pos.y
			+ pos.z * Chunk.SIZE.y
			+ pos.x * Chunk.SIZE.z * Chunk.SIZE.y)
