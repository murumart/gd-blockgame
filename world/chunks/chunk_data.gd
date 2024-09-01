class_name ChunkData extends Resource

## Stores specific data regarding a [Chunk].

## How many blocks are in a chunk.
const BLOCKS_IN_CHUNK := Chunk.SIZE.x * Chunk.SIZE.y * Chunk.SIZE.z
## How many bytes are used to store a block.
const BYTES_PER_BLOCK := 2
## Size of the [param block_data] array.
const BLOCK_DATA_SIZE := BLOCKS_IN_CHUNK * BYTES_PER_BLOCK
## How many sides a block has.
const SIDES_COUNT := 6
## Neighbors of a block coordinate in order.
const SIDE_CHECKS: PackedVector3Array = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.DOWN,
	Vector3.UP,
]
## Enumeration of sides.
enum SIDES {NORTH, SOUTH, WEST, EAST, BOTTOM, TOP}
## The default block data.
static var DEFAULT_BLOCK_DATA: PackedByteArray = []

## Stores all blocks of a chunk.
## [br]
## All of the block states of a chunk are stored in [param block_data]
## as a pair of bytes - 16 bits.
## The first 10 bits of this represent the numeric ID of a block,
## and the final 6 represent specific states of the block.
var block_data := PackedByteArray()


## Clears [member block_data].
func clear_block_data() -> void:
	block_data.clear()


## Sets [member block_data] to the default ([member DEFAULT_BLOCK_DATA]).
func init_block_data() -> void:
	block_data = DEFAULT_BLOCK_DATA.duplicate()


## Sets the block at given [param idx] with given [param data].
## The [param data] should be in range [0, 0xFFFF).
## The [param idx] should be at most [constant BLOCK_DATA_SIZE] - 1.
func set_block_at(idx: int, data: int) -> void:
	#assert(data < 0xFFFF, "block overflow")
	idx *= BYTES_PER_BLOCK
	if block_data.size() == BYTES_PER_BLOCK and data != get_block_at(0):
		init_block_data()
	block_data[idx] = data


## Returns the block at given [param idx].
## The [param idx] should be at most [constant BLOCK_DATA_SIZE] - 1.
func get_block_at(idx: int) -> int:
	if block_data.size() == BYTES_PER_BLOCK:
		return block_data.decode_u16(0)
	idx *= BYTES_PER_BLOCK
	#assert(not (idx < 0 or idx > block_data.size() - 2))
	return block_data.decode_u16(idx)


## Sets the chunk to consist of a single block type only.
func set_single_block_type(data: int) -> void:
	clear_block_data()
	block_data.resize(BYTES_PER_BLOCK)
	block_data.encode_u16(0, data)


## Returns the [BlockType] in a certain local [param pos]ition.
func get_block_type_from_pos(pos: Vector3) -> BlockType:
	return BlockTypes.get_block(get_block_at(ChunkData.pos_to_index(pos)))


static func _static_init() -> void:
	DEFAULT_BLOCK_DATA.resize(BLOCK_DATA_SIZE)
	for x in BLOCKS_IN_CHUNK:
		DEFAULT_BLOCK_DATA.encode_u16(x * BYTES_PER_BLOCK, 3)


## Converts a local [param pos] into an index to be used with [member block_data].
## Does not check if position exceeds chunk boundaries.
static func pos_to_index(pos: Vector3) -> int:
	return int(
			pos.y
			+ pos.z * Chunk.SIZE.y
			+ pos.x * Chunk.SIZE.z * Chunk.SIZE.y)
