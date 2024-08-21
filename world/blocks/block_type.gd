class_name BlockType extends Resource

## Stores data regarding a type of block.

enum MeshType {
	ALL_ONE, ## All the sides of the block use the same atlas coordinate.
	SIX_SIDES, ## Each side of the block has its atlas coordinate set. The order is North, South, West, East, Bottom, Top.
	NONE, ## Nothing is rendered
}

## What type of mesh the block has. See [constant MeshType] for values.
@export var mesh_type := MeshType.ALL_ONE
## What atlas coordinates each face of the block has.
## If the [member mesh_type] is [constant MeshType.ALL_ONE], only the first vector is used.
## Otherwise, the first six are.
@export var atlas_coordinates: PackedVector2Array = []
