extends Node

const RECENTER_EVERY_X_CHUNKS := 16
const HALF := Vector3.ONE * RECENTER_EVERY_X_CHUNKS * 0.5

var world: World
var recenter_target: Node3D
var _last_region_position: Vector3


func _ready() -> void:
	set_process(false)
	assert(owner is World)
	world = owner
	await world.ready
	recenter_target = world.recenter_target
	assert(is_instance_valid(world.recenter_target))
	set_process(true)


func _process(_delta: float) -> void:
	# make the RECENTER_EVERY_X_CHUNKS region be centered around (0, 0, 0)
	var specific_chunk_position := World.world_pos_to_chunk_pos(recenter_target.global_position
			+ Vector3(Chunk.SIZE) * RECENTER_EVERY_X_CHUNKS * 0.5)
	var region_position := (specific_chunk_position / RECENTER_EVERY_X_CHUNKS).floor()

	if _last_region_position != region_position:
		print("should recenter.")
		var recenter_target_position := recenter_target.global_position
		var recenter_chunk_position := World.world_pos_to_chunk_pos(recenter_target_position)
		var detail := recenter_target_position - recenter_chunk_position * Vector3(Chunk.SIZE)
		recenter_target.global_position = detail
		world.global_position -= recenter_chunk_position * Vector3(Chunk.SIZE)
		world.world_position += recenter_chunk_position * Vector3(Chunk.SIZE)
	_last_region_position = region_position
