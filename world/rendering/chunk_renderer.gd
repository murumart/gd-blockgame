class_name ChunkRenderer

static var rs := RenderingServer
static var am := Mesh

static var axes := [
	[Chunks.ADJ_AXIS_XY, Vector2i(Chunks.CHUNK_SIZE.x, Chunks.CHUNK_SIZE.y), Vector3i(0, 1, 2), 1],
	[Chunks.ADJ_AXIS_XZ, Vector2i(Chunks.CHUNK_SIZE.x, Chunks.CHUNK_SIZE.z), Vector3i(0, 2, 1), 1],
	[Chunks.ADJ_AXIS_YZ, Vector2i(Chunks.CHUNK_SIZE.y, Chunks.CHUNK_SIZE.z), Vector3i(1, 2, 0), 1],
	[Chunks.ADJ_AXIS_XY + 3, Vector2i(Chunks.CHUNK_SIZE.x, Chunks.CHUNK_SIZE.y), Vector3i(0, 1, 2), 0],
	[Chunks.ADJ_AXIS_XZ + 3, Vector2i(Chunks.CHUNK_SIZE.x, Chunks.CHUNK_SIZE.z), Vector3i(0, 2, 1), 0],
	[Chunks.ADJ_AXIS_YZ + 3, Vector2i(Chunks.CHUNK_SIZE.y, Chunks.CHUNK_SIZE.z), Vector3i(1, 2, 0), 0],
]

var world: World
var scenario: RID

var instances: Dictionary[Vector3i, RID]
var meshes: Dictionary[Vector3i, RID]
var material := preload("res://world/rendering/chunk_material.tres").get_rid()

var chunks_to_mesh: Array[Vector3i]


func _init(world_: World) -> void:
	world = world_
	scenario = world.get_world_3d().scenario
	world.chunks.chunk_destroyed.connect(_on_chunk_destroyed)


func cleanup() -> void:
	meshes.values().map(func(a: RID) -> void: rs.free_rid(a))
	instances.values().map(func(a: RID) -> void: rs.free_rid(a))


var _last_display_target_pos: Vector3i = Vector3i.ONE * -9999999 # weird default so we sort straight away probably
func display_target_update(pos: Vector3i) -> void:
	if _last_display_target_pos != pos:
		chunks_to_mesh.sort_custom(
			func(a: Vector3i, b: Vector3i) -> bool:
				return a.distance_squared_to(pos) > b.distance_squared_to(pos)
	)
	_last_display_target_pos = pos


func check_meshing() -> void:
	var to_mesh := 5
	while to_mesh:
		if chunks_to_mesh.is_empty(): return
		var cpos: Vector3i = chunks_to_mesh[-1]
		# remove dead queued chunks (assuming there will be)
		while cpos not in world.chunks.blocks:
			chunks_to_mesh.pop_back()
			if chunks_to_mesh.is_empty(): return
			cpos = chunks_to_mesh[-1]
		#print("ChunkRenderer::check_meshing : trying meshing chunk at ", cpos)

		assert(world.chunks.flags[cpos] & Chunks.FLAG_NEEDS_MESHING != 0)
		chunks_to_mesh.pop_back()
		if cpos not in instances:
			_create_chunk_render(cpos)
		mesh_chunk(meshes[cpos], world.chunks.adjacency_maps[cpos])
		world.chunks.flags[cpos] &= ~Chunks.FLAG_NEEDS_MESHING
		#print("ChunkRenderer::check_meshing : meshed chunk at ", cpos)
		to_mesh -= 1


func _create_chunk_render(pos: Vector3i) -> void:
	assert(is_instance_valid(world))
	assert(pos not in meshes)
	assert(pos not in instances)
	#var start := Time.get_ticks_usec()
	#print("ChunkRenderer::_create_chunk_render : creating chunk render at ", pos)

	var instance := rs.instance_create()
	rs.instance_set_scenario(instance, scenario)
	rs.instance_set_custom_aabb(instance, AABB(Vector3.ZERO, Vector3.ONE * 32))

	var mesh := rs.mesh_create()
	rs.instance_set_base(instance, mesh)

	var tf := Transform3D()
	tf.origin = Vector3(pos * Chunks.CHUNK_SIZE)
	rs.instance_set_transform(instance, tf)

	instances[pos] = instance
	meshes[pos] = mesh
	#print("ChunkRenderer::_create_chunk_render : chunk meshing took ", Time.get_ticks_usec() - start, " us")


func _on_chunk_destroyed(pos: Vector3i) -> void:
	if pos in instances:
		print("ChunkRenderer::_on_chunk_destroyed : a rendered chunk at ", pos, " was destroyed, freeing")
		rs.free_rid(instances[pos])
		instances.erase(pos)
		rs.free_rid(meshes[pos])
		meshes.erase(pos)


func mesh_chunk(mesh: RID, adjdata: Array[PackedInt64Array]) -> void:
	rs.mesh_clear(mesh)

	var ia: Array
	ia.resize(am.ARRAY_MAX)

	var vx: PackedVector2Array
	var ix: PackedInt32Array # unused..
	ia[am.ARRAY_VERTEX] = vx

	var vxix := 0

	var vpos := Vector3()
	for axis: Array in axes:
		var axisi: int = axis[0]
		var axaxis: int = axis[2].x
		var ayaxis: int = axis[2].y
		var vecaxis: int = axis[2].z
		var axisadd: int = axis[3]

		var vtx1: Vector3i = _FACE_VTICES[axisi][0]
		var vtx2: Vector3i = _FACE_VTICES[axisi][1]
		var vtx3: Vector3i = _FACE_VTICES[axisi][2]
		var normal: _FaceNormalIx = (axisi + 1) as _FaceNormalIx

		for ax: int in axis[1].x: for ay: int in axis[1].y:
			vpos[axaxis] = ax
			vpos[ayaxis] = ay
			vpos[vecaxis] = axisadd
			var line: int = adjdata[axisi][ax + ay * axis[1].x]
			while line:
				if line & 1:
					vxix = _append_face(
						vpos,
						vtx1, vtx2, vtx3,
						normal,
						vx, ix, vxix,
					)
				line = line >> 1
				vpos[vecaxis] += 1
	if vx.size() == 0: return
	rs.mesh_add_surface_from_arrays(mesh, rs.PRIMITIVE_TRIANGLES, ia)
	rs.mesh_surface_set_material(mesh, 0, material)


static var _FACE_VTICES: Array[Array] = [
	[Vector3i(0, 0, 0), Vector3i(0, 2, 0), Vector3i(2, 0, 0)], # +z
	[Vector3i(1, 0, 0), Vector3i(1, 0, 2), Vector3i(-1, 0, 0)], # +y
	[Vector3i(0, 0, 1), Vector3i(0, 2, 1), Vector3i(0, 0, -1) ], # +x
	[Vector3i(1, 0, 0), Vector3i(1, 2, 0), Vector3i(-1, 0, 0)], # -z
	[Vector3i(1, 0, -1), Vector3i(-1, 0, 1), Vector3i(1, 0, 1)], # -y
	[Vector3i(0, 0, 0), Vector3i(0, 2, 0), Vector3i(0, 0, 2)], # -x
]

enum _FaceNormalIx {
	INVALID,
	BACK,
	UP,
	RIGHT,
	FORWARD,
	DOWN,
	LEFT,
}

enum _FaceUvIx {
	Uv00,
	Uv01,
	Uv10,
}

static func _append_face(
	pos: Vector3i,

	vtx1: Vector3i,
	vtx2: Vector3i,
	vtx3: Vector3i,
	normal: _FaceNormalIx,

	vx: PackedVector2Array,
	ix: PackedInt32Array,
	vxix: int,
) -> int:
	var pba := PackedByteArray()
	pba.resize(12)

	var pos1 := Vector3i()
	var vertex := Vector2(NAN, NAN)

	pos1 = pos + vtx1
	pba.encode_s8(0, pos1.x)
	pba.encode_s8(1, pos1.y)
	pba.encode_s8(2, pos1.z)
	pba.encode_u8(3, int(normal) << 3 | _FaceUvIx.Uv00)
	vertex.x = pba.decode_float(0)
	#vertex.y = vertex.x
	vx.append(vertex)
	pba.encode_float(0, vertex.x)

	pos1 = pos + vtx2
	pba.encode_s8(0, pos1.x)
	pba.encode_s8(1, pos1.y)
	pba.encode_s8(2, pos1.z)
	pba.encode_u8(3, int(normal) << 3 | _FaceUvIx.Uv01)
	vertex.x = pba.decode_float(0)
	#vertex.y = vertex.x
	vx.append(vertex)

	pos1 = pos + vtx3
	pba.encode_s8(0, pos1.x)
	pba.encode_s8(1, pos1.y)
	pba.encode_s8(2, pos1.z)
	pba.encode_u8(3, int(normal) << 3 | _FaceUvIx.Uv10)
	vertex.x = pba.decode_float(0)
	#vertex.y = vertex.x
	vx.append(vertex)

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	
	return vxix + 3


static var debruijn_lookup: PackedByteArray = [
	 0, 47, 1, 56, 48, 27, 2, 60,
	57, 49, 41, 37, 28, 16, 3, 61,
	54, 58, 35, 52, 50, 42, 21, 44,
	38, 32, 29, 23, 17, 11, 4, 62,
	46, 55, 26, 59, 40, 36, 15, 53,
	34, 51, 20, 43, 31, 22, 10, 45,
	25, 39, 14, 33, 19, 30, 9, 24,
	13, 18, 8, 12, 7, 6, 5, 63
]
# https://stackoverflow.com/a/45225089
static func ntz(x: int) -> int:
	var y := x ^ (x - 1)
	const d := 0x03f79d71b4cb0a89
	var z := (d * y) >> 58
	return debruijn_lookup[z]
