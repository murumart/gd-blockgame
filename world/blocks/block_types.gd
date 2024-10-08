class_name BlockTypes

## Stores block types.

const INVALID_BLOCK_ID := -1
const AIR := 0

static var _array: Array[BlockType] = [
	preload("res://world/blocks/default_blocks/empty.tres"),
	preload("res://world/blocks/default_blocks/stone.tres"),
	preload("res://world/blocks/default_blocks/soil.tres"),
	preload("res://world/blocks/default_blocks/grassy_soil.tres"),
]


## Get a block by the id.
static func get_block(id: int) -> BlockType:
	return _array[id]
