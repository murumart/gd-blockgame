using Godot;
using System;
using System.Collections.Generic;

public partial class ChunkMesh : MeshInstance3D {
	int vertexCounter = 0;
	Godot.Collections.Array surfaceArray = new Godot.Collections.Array();
	//surfaceArray.Resize((int)Mesh.ArrayType.Max);

	List<Vector3> verts = new List<Vector3>();
	List<Vector2> uvs = new List<Vector2>();
	List<Vector3> normals = new List<Vector3>();
	List<int> indices = new List<int>();

	ArrayMesh am = new();

	public Vector3I chunkPosition;


	public void BuildMesh(ref short[] blocks) {
		ResetMesh();
		for (short x = 0; x < Chunk.WIDTH; x++) {
		for (short y = 0; y < Chunk.WIDTH; y++) {
		for (short z = 0; z < Chunk.WIDTH; z++) {
			int index = x + z * Chunk.WIDTH + y * Chunk.AREA;
			if (blocks[index] > 0) {
				AddBlockMesh(x, y, z);
			}
		}}} 
		am.ClearSurfaces();
		surfaceArray.Resize((int)Mesh.ArrayType.Max);
		surfaceArray[(int)Mesh.ArrayType.Vertex] = verts.ToArray();
		surfaceArray[(int)Mesh.ArrayType.TexUV] = uvs.ToArray();
		surfaceArray[(int)Mesh.ArrayType.Normal] = normals.ToArray();
		surfaceArray[(int)Mesh.ArrayType.Index] = indices.ToArray();

		am.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, surfaceArray);

		Mesh = am;
		Mesh.Set("surface_0/material", ResourceLoader.Load("res://scenes/test/testmat.tres"));
	}


	private void AddBlockMesh(int x, int y, int z) {
		int gx = chunkPosition.X * Chunk.WIDTH + x;
		int gy = chunkPosition.Y * Chunk.HEIGHT + y;
		int gz = chunkPosition.Z * Chunk.WIDTH + z;

		// bottom
		int vc = vertexCounter;
		if (!IsSolid(x, y - 1, z)) {
			verts.AddRange(new Vector3[] {
				new(0 + x, 0 + y, 0 + z),
				new(1 + x, 0 + y, 0 + z),
				new(1 + x, 0 + y, 1 + z),
				new(0 + x, 0 + y, 1 + z)
			});
			indices.AddRange(new int[] {
				0 + vc, 3 + vc, 2 + vc, 2 + vc, 1 + vc, 0 + vc
			});
			vertexCounter += 4;
			uvs.AddRange(new Vector2[] {
				new(0, 1), new(1, 1), new(1, 0), new(0, 0)
			});
			normals.AddRange(new Vector3[] {
				new(0, -1, 0),
				new(0, -1, 0),
				new(0, -1, 0),
				new(0, -1, 0)
			});
		}
		// top
		vc = vertexCounter;
		if (!IsSolid(x, y + 1, z)) {
			verts.AddRange(new Vector3[] {
				new(0 + x, 1 + y, 0 + z),
				new(1 + x, 1 + y, 0 + z),
				new(1 + x, 1 + y, 1 + z), 
				new(0 + x, 1 + y, 1 + z)
			});
			indices.AddRange(new int[] {
				0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc
			});
			vertexCounter += 4;
			uvs.AddRange(new Vector2[] {
				new(0, 0), new(1, 0), new(1, 1), new(0, 1)
			});
			normals.AddRange(new Vector3[] {
				new(0, 1, 0),
				new(0, 1, 0),
				new(0, 1, 0),
				new(0, 1, 0)
			});
		}
		// left
		vc = vertexCounter;
		if (!IsSolid(x - 1, y, z)) {
			verts.AddRange(new Vector3[] {
				new(0 + x, 0 + y, 0 + z),
				new(0 + x, 1 + y, 0 + z),
				new(0 + x, 1 + y, 1 + z),
				new(0 + x, 0 + y, 1 + z)
			});
			indices.AddRange(new int[] {
				0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc
			});
			vertexCounter += 4;
			uvs.AddRange(new Vector2[] {
				new(1, 1), new(1, 0), new(0, 0), new(0, 1)
			});
			normals.AddRange(new Vector3[] {
				new(-1, 0, 0),
				new(-1, 0, 0),
				new(-1, 0, 0),
				new(-1, 0, 0)
			});
		}
		// right
		vc = vertexCounter;
		if (!IsSolid(x + 1, y, z)) {
			verts.AddRange(new Vector3[] {
				new(1 + x, 0 + y, 0 + z),
				new(1 + x, 0 + y, 1 + z),
				new(1 + x, 1 + y, 1 + z),
				new(1 + x, 1 + y, 0 + z)
			});
			indices.AddRange(new int[] {
				0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc
			});
			vertexCounter += 4;
			uvs.AddRange(new Vector2[] {
				new(1, 1), new(0, 1), new(0, 0), new(1, 0)
			});
			normals.AddRange(new Vector3[] {
				new(1, 0, 0),
				new(1, 0, 0),
				new(1, 0, 0),
				new(1, 0, 0)
			});
		}
		// back
		vc = vertexCounter;
		if (!IsSolid(x, y, z - 1)) {
			verts.AddRange(new Vector3[] {
				new(0 + x, 0 + y, 0 + z),
				new(1 + x, 0 + y, 0 + z),
				new(1 + x, 1 + y, 0 + z),
				new(0 + x, 1 + y, 0 + z)
			});
			indices.AddRange(new int[] {
				0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc
			});
			vertexCounter += 4;
			uvs.AddRange(new Vector2[] {
				new(1, 1), new(0, 1), new(0, 0), new(1, 0)
			});
			normals.AddRange(new Vector3[] {
				new(0, 0, -1),
				new(0, 0, -1),
				new(0, 0, -1),
				new(0, 0, -1)
			});
		}
		// front
		vc = vertexCounter;
		if (!IsSolid(x, y, z - 1)) {
			verts.AddRange(new Vector3[] {
				new(0 + x, 0 + y, 1 + z),
				new(0 + x, 1 + y, 1 + z),
				new(1 + x, 1 + y, 1 + z),
				new(1 + x, 0 + y, 1 + z)
			});
			indices.AddRange(new int[] {
				0 + vc, 1 + vc, 2 + vc, 2 + vc, 3 + vc, 0 + vc
			});
			vertexCounter += 4;
			uvs.AddRange(new Vector2[] {
				new(0, 1), new(0, 0), new(1, 0), new(1, 1)
			});
			normals.AddRange(new Vector3[] {
				new(0, 0, 1),
				new(0, 0, 1),
				new(0, 0, 1),
				new(0, 0, 1)
			});
		}
	}


	private void ResetMesh() {
		vertexCounter = 0;
		am = new();
		verts.Clear();
		uvs.Clear();
		normals.Clear();
		indices.Clear();
		surfaceArray.Clear();
	}


	private bool IsSolid(int x, int y, int z) {
		
		return false;
	}
}
