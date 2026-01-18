class_name ChunkRenderer

static var rs := RenderingServer
static var am := ArrayMesh

var world: World
var scenario: RID

var instances: Dictionary[Vector3i, RID]
var meshes: Dictionary[Vector3i, RID]


func _init(world_: World) -> void:
	world = world_
	scenario = world.get_world_3d().scenario

	world.chunks.chunk_created.connect(_create_chunk_render)


func _create_chunk_render(pos: Vector3i) -> void:
	assert(is_instance_valid(world))
	assert(pos not in meshes)
	assert(pos not in instances)
	var start := Time.get_ticks_msec()
	#print("ChunkRenderer::_create_chunk_render : creating chunk render at ", pos)
	var cs := Chunks.CHUNK_SIZE

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

	var bix := 0
	var vxix := 0
	var bdata := world.chunks.blocks[pos]
	var adjdata := world.chunks.adjacency_maps[pos]
	for z in cs.z: \
	for y in cs.y: \
	for x in cs.x:
		var block := bdata[bix]
		bix += 1
		if block == 0:
			continue

		if adjdata[Chunks.ADJ_AXIS_XY    ][x + y * cs.x] & 1 << z:
			vxix = _append_face_z_pos(x, y, z + 1, vx, ix, ns, vxix)
		if adjdata[Chunks.ADJ_AXIS_XY + 3][x + y * cs.x] & 1 << z:
			vxix = _append_face_z_neg(x, y, z, vx, ix, ns, vxix)

		if adjdata[Chunks.ADJ_AXIS_XZ    ][x + z * cs.x] & 1 << y:
			vxix = _append_face_y_pos(x, y + 1, z, vx, ix, ns, vxix)
		if adjdata[Chunks.ADJ_AXIS_XZ + 3][x + z * cs.x] & 1 << y:
			vxix = _append_face_y_neg(x, y, z, vx, ix, ns, vxix)

		if adjdata[Chunks.ADJ_AXIS_YZ    ][y + z * cs.y] & 1 << x:
			vxix = _append_face_x_pos(x + 1, y, z, vx, ix, ns, vxix)
		if adjdata[Chunks.ADJ_AXIS_YZ + 3][y + z * cs.y] & 1 << x:
			vxix = _append_face_x_neg(x, y, z, vx, ix, ns, vxix)

	if vx.size() == 0:
		return
	rs.mesh_add_surface_from_arrays(mesh, rs.PRIMITIVE_TRIANGLES, ia)
	print("ChunkRenderer::_create_chunk_render : chunk meshing took ", Time.get_ticks_msec() - start, " ms")


func _append_face_z_pos(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x    , y    , z))
	vx.append(Vector3(x    , y + 1, z))
	vx.append(Vector3(x + 1, y + 1, z))
	vx.append(Vector3(x + 1, y    , z))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(0, 0, 1)); ns.append(Vector3(0, 0, 1))
	ns.append(Vector3(0, 0, 1)); ns.append(Vector3(0, 0, 1))

	return vxix + 4


func _append_face_z_neg(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x    , y    , z))
	vx.append(Vector3(x + 1, y    , z))
	vx.append(Vector3(x + 1, y + 1, z))
	vx.append(Vector3(x    , y + 1, z))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(0, 0, -1)); ns.append(Vector3(0, 0, -1))
	ns.append(Vector3(0, 0, -1)); ns.append(Vector3(0, 0, -1))

	return vxix + 4


func _append_face_x_pos(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x    , y    , z    ))
	vx.append(Vector3(x    , y    , z + 1))
	vx.append(Vector3(x    , y + 1, z + 1))
	vx.append(Vector3(x    , y + 1, z    ))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(1, 0, 0)); ns.append(Vector3(1, 0, 0))
	ns.append(Vector3(1, 0, 0)); ns.append(Vector3(1, 0, 0))

	return vxix + 4


func _append_face_x_neg(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x    , y    , z    ))
	vx.append(Vector3(x    , y + 1, z    ))
	vx.append(Vector3(x    , y + 1, z + 1))
	vx.append(Vector3(x    , y    , z + 1))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(-1, 0, 0)); ns.append(Vector3(-1, 0, 0))
	ns.append(Vector3(-1, 0, 0)); ns.append(Vector3(-1, 0, 0))

	return vxix + 4


func _append_face_y_pos(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x    , y    , z    ))
	vx.append(Vector3(x + 1, y    , z    ))
	vx.append(Vector3(x + 1, y    , z + 1))
	vx.append(Vector3(x    , y    , z + 1))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(0, 1, 0)); ns.append(Vector3(0, 1, 0))
	ns.append(Vector3(0, 1, 0)); ns.append(Vector3(0, 1, 0))

	return vxix + 4


func _append_face_y_neg(
	x: int, y: int, z: int,
	vx: PackedVector3Array,
	ix: PackedInt32Array,
	ns: PackedVector3Array,
	vxix: int
) -> int:
	vx.append(Vector3(x    , y    , z    ))
	vx.append(Vector3(x    , y    , z + 1))
	vx.append(Vector3(x + 1, y    , z + 1))
	vx.append(Vector3(x + 1, y    , z    ))

	ix.append(vxix + 0); ix.append(vxix + 1); ix.append(vxix + 2)
	ix.append(vxix + 2); ix.append(vxix + 3); ix.append(vxix + 0)
	ns.append(Vector3(0, -1, 0)); ns.append(Vector3(0, -1, 0))
	ns.append(Vector3(0, -1, 0)); ns.append(Vector3(0, -1, 0))

	return vxix + 4
