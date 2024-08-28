extends Control

@export var camera: Camera3D
@export var world: World

@onready var label: Label = $Label
@onready var rc_label: Label = $RcLabel

@onready var recenterer: Node = world.get_node("Recenterer")

func _physics_process(_delta: float) -> void:
	label.text = get_text()
	rc_label.text = get_raycast_text()


func get_text() -> String:
	var wpos := camera.global_position + world.world_position
	var chunk_pos_old := World.world_pos_to_chunk_pos(camera.global_position)
	var chunk_pos := World.world_pos_to_chunk_pos(camera.global_position + world.world_position)
	var facing := Vector3(
			rad_to_deg(camera.global_basis.z.x),
			rad_to_deg(camera.global_basis.z.y),
			rad_to_deg(camera.global_basis.z.z))
	return (
			"fps: " + str(Engine.get_frames_per_second())
			+ "\ngpos: " + str(camera.global_position)
			+ "\nwpos: " + str(wpos)
			+ "\nchunk_pos_old: " + str(chunk_pos_old)
			+ "\nchunk_pos: " + str(chunk_pos)
			+ "\nworld_pos: " + str(world.world_position)
			+ "\npos_in_chunk: " + str(wpos.round() - chunk_pos * Vector3(Chunk.SIZE))
			+ "\nrecenter_region: " + str(recenterer._last_region_position)
			+ "\nfacing: " + str(camera.global_basis.z)

			#+ "\ngen_queue_size: " + str(world.world_generator._queue.size())
	)


func get_raycast_text() -> String:
	var raycast := BlockRaycast.cast_ray_fast(camera.global_position, -camera.global_basis.z, 9, world)
	return (
			"raycast: " + str(raycast)
			#+ "\nrc_pre: " + str(raycast._debug_data["pre"])
			+ "\nrc_debug: " + JSON.stringify(raycast._debug_data, "  ", false).replace("{", "").replace(",\n", "").replace("}", "")
	)
