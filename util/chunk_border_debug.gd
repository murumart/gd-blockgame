extends MeshInstance3D

@export var world: World


func _ready() -> void:
	var im := mesh as ImmediateMesh
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	im.surface_add_vertex(Vector3(0, 0, 0))
	im.surface_add_vertex(Vector3(1, 0, 0))
	im.surface_add_vertex(Vector3(1, 0, 0))
	im.surface_add_vertex(Vector3(1, 1, 0))
	im.surface_add_vertex(Vector3(1, 1, 0))
	im.surface_add_vertex(Vector3(0, 1, 0))
	im.surface_add_vertex(Vector3(0, 1, 0))
	im.surface_add_vertex(Vector3(0, 0, 0))

	im.surface_add_vertex(Vector3(0, 0, 0))
	im.surface_add_vertex(Vector3(0, 0, 1))
	im.surface_add_vertex(Vector3(0, 0, 1))
	im.surface_add_vertex(Vector3(0, 1, 1))
	im.surface_add_vertex(Vector3(0, 1, 1))
	im.surface_add_vertex(Vector3(0, 1, 0))
	im.surface_add_vertex(Vector3(0, 1, 0))
	im.surface_add_vertex(Vector3(0, 0, 0))

	im.surface_add_vertex(Vector3(1, 0, 0))
	im.surface_add_vertex(Vector3(1, 0, 1))
	im.surface_add_vertex(Vector3(1, 0, 1))
	im.surface_add_vertex(Vector3(1, 1, 1))
	im.surface_add_vertex(Vector3(1, 1, 1))
	im.surface_add_vertex(Vector3(1, 1, 0))
	im.surface_add_vertex(Vector3(1, 1, 0))
	im.surface_add_vertex(Vector3(1, 0, 0))

	im.surface_add_vertex(Vector3(0, 0, 0))
	im.surface_add_vertex(Vector3(1, 0, 0))
	im.surface_add_vertex(Vector3(1, 0, 0))
	im.surface_add_vertex(Vector3(1, 0, 1))
	im.surface_add_vertex(Vector3(1, 0, 1))
	im.surface_add_vertex(Vector3(0, 0, 1))
	im.surface_add_vertex(Vector3(0, 0, 1))
	im.surface_add_vertex(Vector3(0, 0, 0))

	im.surface_add_vertex(Vector3(0, 1, 0))
	im.surface_add_vertex(Vector3(1, 1, 0))
	im.surface_add_vertex(Vector3(1, 1, 0))
	im.surface_add_vertex(Vector3(1, 1, 1))
	im.surface_add_vertex(Vector3(1, 1, 1))
	im.surface_add_vertex(Vector3(0, 1, 1))
	im.surface_add_vertex(Vector3(0, 1, 1))
	im.surface_add_vertex(Vector3(0, 1, 0))

	im.surface_end()


func _process(_delta: float) -> void:
	scale = Chunks.CHUNK_SIZE
	position = world.get_center_chunk() * Chunks.CHUNK_SIZE
