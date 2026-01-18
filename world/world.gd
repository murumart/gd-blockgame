class_name World extends Node3D

const TICKS_PER_SECOND := 20
const SECONDS_PER_TICK := 1.0 / TICKS_PER_SECOND

@export var chunk_load_center: Node3D

var chunks: Chunks
var chunk_renderer: ChunkRenderer


func _ready() -> void:
	chunks = Chunks.new()
	chunk_renderer = ChunkRenderer.new(self)
	var b := 3
	for x in range(-b, b): for y in range(-b, b): for z in range(-b, b):
		chunks.create_chunk(Vector3i(x, y, z))


func _exit_tree() -> void:
	chunk_renderer.cleanup()


var _tick_delay := 0.0
func _process(delta: float) -> void:
	_tick_delay += delta
	while _tick_delay > SECONDS_PER_TICK:
		tick()
		_tick_delay -= SECONDS_PER_TICK

	chunk_renderer.check_meshing()


func tick() -> void:
	chunks.get_chunks_to_mesh(chunk_renderer.chunks_to_mesh)
	chunk_renderer.display_target_update(Vector3i(chunk_load_center.position) / Chunks.CHUNK_SIZE)
