class_name World extends Node3D

const TICKS_PER_SECOND := 20
const SECONDS_PER_TICK := 1.0 / TICKS_PER_SECOND

@export var chunk_load_center: Node3D

var chunks: Chunks
var chunk_renderer: ChunkRenderer


func _ready() -> void:
	chunks = Chunks.new(self)
	chunk_renderer = ChunkRenderer.new(self)
	#var b := 3
	#for x in range(-b, b): for y in range(-b, b): for z in range(-b, b):
	#	chunks.create_chunk(Vector3i(x, y, z))


func _exit_tree() -> void:
	chunk_renderer.cleanup()
	chunks.cleanup()


var _tick_delay := 0.0
func _process(delta: float) -> void:
	_tick_delay += delta
	while _tick_delay > SECONDS_PER_TICK:
		tick()
		_tick_delay -= SECONDS_PER_TICK

	chunk_renderer.check_meshing()


var last_center_cpos := Vector3i.MIN
func tick() -> void:
	var center_cpos := get_center_chunk()
	chunks.unload_chunks(center_cpos)
	chunks.load_chunks(center_cpos)
	chunks.process(center_cpos)
	chunks.get_chunks_to_mesh(chunk_renderer.chunks_to_mesh)
	chunk_renderer.display_target_update(center_cpos)
	if center_cpos != last_center_cpos:
		last_center_cpos = center_cpos


func get_center_chunk() -> Vector3i:
	return Vector3i((chunk_load_center.position / Vector3(Chunks.CHUNK_SIZE)).floor())
