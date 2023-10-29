using Godot;
using Godot.NativeInterop;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class meshtest : MeshInstance3D {

	public override void _Ready() {
		base._Ready();
		MeshGen();
	}

	void MeshGen() {
		ArrayMesh am = new();

		var surfaceArray = new Godot.Collections.Array();
		surfaceArray.Resize((int)Mesh.ArrayType.Max);

		var verts = new List<Vector3>();
		var uvs = new List<Vector2>();
		var normals = new List<Vector3>();
		var indices = new List<int>();

		// bottom
		verts.Add(new Vector3(0, 0, 0)); // 0
		verts.Add(new Vector3(1, 0, 0)); // 1
		verts.Add(new Vector3(1, 0, 1)); // 2
		verts.Add(new Vector3(0, 0, 1)); // 3
		// top
		verts.Add(new Vector3(0, 1, 0)); // 4
		verts.Add(new Vector3(1, 1, 0)); // 5
		verts.Add(new Vector3(1, 1, 1)); // 6
		verts.Add(new Vector3(0, 1, 1)); // 7
		// left
		verts.Add(new Vector3(0, 0, 0)); // 8
		verts.Add(new Vector3(0, 1, 0)); // 9
		verts.Add(new Vector3(0, 1, 1)); // 10
		verts.Add(new Vector3(0, 0, 1)); // 11
		// right
		verts.Add(new Vector3(1, 0, 0)); // 12
		verts.Add(new Vector3(1, 0, 1)); // 13
		verts.Add(new Vector3(1, 1, 1)); // 14
		verts.Add(new Vector3(1, 1, 0)); // 15
		// back
		verts.Add(new Vector3(0, 0, 0)); // 16
		verts.Add(new Vector3(1, 0, 0)); // 17
		verts.Add(new Vector3(1, 1, 0)); // 18
		verts.Add(new Vector3(0, 1, 0)); // 19
		// front
		verts.Add(new Vector3(0, 0, 1)); // 20
		verts.Add(new Vector3(0, 1, 1)); // 21
		verts.Add(new Vector3(1, 1, 1)); // 22
		verts.Add(new Vector3(1, 0, 1)); // 23

		int[] indxs = {
			// bottom
			0, 3, 2, 2, 1, 0,
			// top
			4, 5, 6, 6, 7, 4,
			// left
			8, 9, 10, 10, 11, 8,
			// right
			12, 13, 14, 14, 15, 12,
			// back
			16, 17, 18, 18, 19, 16,
			// front
			20, 21, 22, 22, 23, 20
		};
		indices.AddRange(indxs);

		Vector2[] uvs_ = {
			// bottom
			new(0, 1),
			new(1, 1),
			new(1, 0),
			new(0, 0),
			// top
			new(0, 0),
			new(1, 0),
			new(1, 1),
			new(0, 1),
			// left
			new(1, 1),
			new(1, 0),
			new(0, 0),
			new(0, 1),
			// right
			new(1, 1),
			new(0, 1),
			new(0, 0),
			new(1, 0),
			// back
			new(1, 1),
			new(0, 1),
			new(0, 0),
			new(1, 0),
			// front
			new(0, 1),
			new(0, 0),
			new(1, 0),
			new(1, 1)
		};
		uvs.AddRange(uvs_);

		Vector3[] nrmls = {
			// bottom
			new(0, -1, 0),
			new(0, -1, 0),
			new(0, -1, 0),
			new(0, -1, 0),
			// top
			new(0, 1, 0),
			new(0, 1, 0),
			new(0, 1, 0),
			new(0, 1, 0),
			// left
			new(-1, 0, 0),
			new(-1, 0, 0),
			new(-1, 0, 0),
			new(-1, 0, 0),
			// right
			new(1, 0, 0),
			new(1, 0, 0),
			new(1, 0, 0),
			new(1, 0, 0),
			// back
			new(0, 0, -1),
			new(0, 0, -1),
			new(0, 0, -1),
			new(0, 0, -1),
			// front
			new(0, 0, 1),
			new(0, 0, 1),
			new(0, 0, 1),
			new(0, 0, 1),
		};
		normals.AddRange(nrmls);

		surfaceArray[(int)Mesh.ArrayType.Vertex] = verts.ToArray();
		surfaceArray[(int)Mesh.ArrayType.TexUV] = uvs.ToArray();
		surfaceArray[(int)Mesh.ArrayType.Normal] = normals.ToArray();
		surfaceArray[(int)Mesh.ArrayType.Index] = indices.ToArray();

		am.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, surfaceArray);

		Mesh = am;
		Mesh.Set("surface_0/material", ResourceLoader.Load("res://scenes/test/testmat.tres"));
	}
}
