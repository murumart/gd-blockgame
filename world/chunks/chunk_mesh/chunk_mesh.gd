@tool
extends MeshInstance3D

var chunk_size := Vector3i(16, 16, 16) # DEBUG


@export var _debug_regenerate: bool:
	set(to):
		_debug_regen()


func _debug_regen() -> void:
	_create_mesh()


func _create_mesh() -> void:
	var time := Time.get_ticks_msec()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for y in chunk_size.y:
		for x in chunk_size.x:
			for z in chunk_size.z:
				var bpos := Vector3(x, y, z)
				_add_block_mesh(st, bpos)
	
	st.generate_normals()
	
	mesh = st.commit()
	print("meshgen took ", Time.get_ticks_msec() - time)


func _add_block_mesh(
	st: SurfaceTool,
	block_position: Vector3) -> void:
	# NORTH -Z
	st.add_vertex(Vector3(0, 0, 0) + block_position)
	st.add_vertex(Vector3(1, 0, 0) + block_position)
	st.add_vertex(Vector3(1, 1, 0) + block_position)
	st.add_vertex(Vector3(1, 1, 0) + block_position)
	st.add_vertex(Vector3(0, 1, 0) + block_position)
	st.add_vertex(Vector3(0, 0, 0) + block_position)
	# SOUTH +Z
	st.add_vertex(Vector3(0, 0, 1) + block_position)
	st.add_vertex(Vector3(1, 1, 1) + block_position)
	st.add_vertex(Vector3(1, 0, 1) + block_position)
	st.add_vertex(Vector3(1, 1, 1) + block_position)
	st.add_vertex(Vector3(0, 0, 1) + block_position)
	st.add_vertex(Vector3(0, 1, 1) + block_position)
	# EAST +X
	st.add_vertex(Vector3(1, 0, 0) + block_position)
	st.add_vertex(Vector3(1, 0, 1) + block_position)
	st.add_vertex(Vector3(1, 1, 1) + block_position)
	st.add_vertex(Vector3(1, 1, 1) + block_position)
	st.add_vertex(Vector3(1, 1, 0) + block_position)
	st.add_vertex(Vector3(1, 0, 0) + block_position)
	# WEST -X
	st.add_vertex(Vector3(0, 0, 0) + block_position)
	st.add_vertex(Vector3(0, 1, 0) + block_position)
	st.add_vertex(Vector3(0, 1, 1) + block_position)
	st.add_vertex(Vector3(0, 1, 1) + block_position)
	st.add_vertex(Vector3(0, 0, 1) + block_position)
	st.add_vertex(Vector3(0, 0, 0) + block_position)
	# BOTTOM -Y
	st.add_vertex(Vector3(0, 0, 0) + block_position)
	st.add_vertex(Vector3(0, 0, 1) + block_position)
	st.add_vertex(Vector3(1, 0, 1) + block_position)
	st.add_vertex(Vector3(1, 0, 1) + block_position)
	st.add_vertex(Vector3(1, 0, 0) + block_position)
	st.add_vertex(Vector3(0, 0, 0) + block_position)
	# TOP +Y
	st.add_vertex(Vector3(1, 1, 1) + block_position)
	st.add_vertex(Vector3(0, 1, 1) + block_position)
	st.add_vertex(Vector3(0, 1, 0) + block_position)
	st.add_vertex(Vector3(0, 1, 0) + block_position)
	st.add_vertex(Vector3(1, 1, 0) + block_position)
	st.add_vertex(Vector3(1, 1, 1) + block_position)
