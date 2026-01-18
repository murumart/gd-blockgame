class_name ChunkRenderer

static var rs := RenderingServer
static var am := Mesh

var world: World
var scenario: RID

var instances: Dictionary[Vector3i, RID]
var meshes: Dictionary[Vector3i, RID]


func _init(world_: World) -> void:
	world = world_
	scenario = world.get_world_3d().scenario

	world.chunks.chunk_created.connect(_create_chunk_render)


func cleanup() -> void:
	meshes.values().map(func(a: RID) -> void: rs.free_rid(a))
	instances.values().map(func(a: RID) -> void: rs.free_rid(a))


static var axes := [
	[Chunks.ADJ_AXIS_XY, Vector2i(Chunks.CHUNK_SIZE.x, Chunks.CHUNK_SIZE.y), _append_face_z_pos, Vector3i(0, 1, 2), 1],
	[Chunks.ADJ_AXIS_XZ, Vector2i(Chunks.CHUNK_SIZE.x, Chunks.CHUNK_SIZE.z), _append_face_y_pos, Vector3i(0, 2, 1), 1],
	[Chunks.ADJ_AXIS_YZ, Vector2i(Chunks.CHUNK_SIZE.y, Chunks.CHUNK_SIZE.z), _append_face_x_pos, Vector3i(1, 2, 0), 1],
	[Chunks.ADJ_AXIS_XY + 3, Vector2i(Chunks.CHUNK_SIZE.x, Chunks.CHUNK_SIZE.y), _append_face_z_neg, Vector3i(0, 1, 2), 0],
	[Chunks.ADJ_AXIS_XZ + 3, Vector2i(Chunks.CHUNK_SIZE.x, Chunks.CHUNK_SIZE.z), _append_face_y_neg, Vector3i(0, 2, 1), 0],
	[Chunks.ADJ_AXIS_YZ + 3, Vector2i(Chunks.CHUNK_SIZE.y, Chunks.CHUNK_SIZE.z), _append_face_x_neg, Vector3i(1, 2, 0), 0],
]
func _create_chunk_render(pos: Vector3i) -> void:
	assert(is_instance_valid(world))
	assert(pos not in meshes)
	assert(pos not in instances)
	var start := Time.get_ticks_usec()
	#print("ChunkRenderer::_create_chunk_render : creating chunk render at ", pos)

	var instance := rs.instance_create()
	rs.instance_set_scenario(instance, scenario)

	var mesh := rs.mesh_create()
	rs.instance_set_base(instance, mesh)

	var tf := Transform3D()
	tf.origin = Vector3(pos * Chunks.CHUNK_SIZE)
	rs.instance_set_transform(instance, tf)

	instances[pos] = instance
	meshes[pos] = mesh

	var ia: Array
	ia.resize(am.ARRAY_MAX)

	var vx: PackedVector3Array
	var ix: PackedInt32Array
	var ns: PackedVector3Array
	ia[am.ARRAY_VERTEX] = vx
	ia[am.ARRAY_INDEX] = ix
	ia[am.ARRAY_NORMAL] = ns

	var vxix := 0
	var adjdata := world.chunks.adjacency_maps[pos]

	var vpos := Vector3i()
	for axis: Array in axes:
		var fun: Callable = axis[2]
		var axaxis: int = axis[3].x
		var ayaxis: int = axis[3].y
		var vecaxis: int = axis[3].z
		var axisadd: int = axis[4]
		for ax: int in axis[1].x: for ay: int in axis[1].y:
			vpos[axaxis] = ax
			vpos[ayaxis] = ay
			vpos[vecaxis] = axisadd
			var line: int = adjdata[axis[0]][ax + ay * axis[1].x]
			while line:
				if line & 1:
					vxix = fun.call(vpos.x, vpos.y, vpos.z, vx, ix, ns, vxix)
				line = line >> 1
				vpos[vecaxis] += 1
	if vx.size() == 0:
		return
	rs.mesh_add_surface_from_arrays(mesh, rs.PRIMITIVE_TRIANGLES, ia)
	print("ChunkRenderer::_create_chunk_render : chunk meshing took ", Time.get_ticks_usec() - start, " us")


static func _append_face_z_pos(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x, y, z))
	vx.append(Vector3(x, y + 1, z))
	vx.append(Vector3(x + 1, y + 1, z))
	vx.append(Vector3(x + 1, y, z))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(0, 0, 1)); ns.append(Vector3(0, 0, 1))
	ns.append(Vector3(0, 0, 1)); ns.append(Vector3(0, 0, 1))

	return vxix + 4


static func _append_face_z_neg(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x, y, z))
	vx.append(Vector3(x + 1, y, z))
	vx.append(Vector3(x + 1, y + 1, z))
	vx.append(Vector3(x, y + 1, z))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(0, 0, -1)); ns.append(Vector3(0, 0, -1))
	ns.append(Vector3(0, 0, -1)); ns.append(Vector3(0, 0, -1))

	return vxix + 4


static func _append_face_x_pos(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x, y, z))
	vx.append(Vector3(x, y, z + 1))
	vx.append(Vector3(x, y + 1, z + 1))
	vx.append(Vector3(x, y + 1, z))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(1, 0, 0)); ns.append(Vector3(1, 0, 0))
	ns.append(Vector3(1, 0, 0)); ns.append(Vector3(1, 0, 0))

	return vxix + 4


static func _append_face_x_neg(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x, y, z))
	vx.append(Vector3(x, y + 1, z))
	vx.append(Vector3(x, y + 1, z + 1))
	vx.append(Vector3(x, y, z + 1))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(-1, 0, 0)); ns.append(Vector3(-1, 0, 0))
	ns.append(Vector3(-1, 0, 0)); ns.append(Vector3(-1, 0, 0))

	return vxix + 4


static func _append_face_y_pos(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x, y, z))
	vx.append(Vector3(x + 1, y, z))
	vx.append(Vector3(x + 1, y, z + 1))
	vx.append(Vector3(x, y, z + 1))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(0, 1, 0)); ns.append(Vector3(0, 1, 0))
	ns.append(Vector3(0, 1, 0)); ns.append(Vector3(0, 1, 0))

	return vxix + 4


static func _append_face_y_neg(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x, y, z))
	vx.append(Vector3(x, y, z + 1))
	vx.append(Vector3(x + 1, y, z + 1))
	vx.append(Vector3(x + 1, y, z))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(0, -1, 0)); ns.append(Vector3(0, -1, 0))
	ns.append(Vector3(0, -1, 0)); ns.append(Vector3(0, -1, 0))

	return vxix + 4
