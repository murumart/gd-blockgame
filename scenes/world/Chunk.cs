using Godot;
using System;
using System.Collections.Generic;
using System.Threading;

[GlobalClass]
public partial class Chunk : Node3D {
	public static readonly int AREA = World.CHUNK_SIZE * World.CHUNK_SIZE;
	public static readonly int VOLUME = AREA * World.CHUNK_SIZE;

	public Vector3I chunkPosition = new(0, 0, 0);
	public bool isEmpty = true;
	public short[] blocks = new short[VOLUME];

	public ChunkMesh mesh;
	public bool meshGenned = false;


	public override void _Ready()
	{
		base._Ready();
		mesh = GetNode<ChunkMesh>("ChunkMesh");
		mesh.chunkPosition = chunkPosition;
		GenBlocks();
	}


	public void GenBlocks() {
		for (int x = 0; x < World.CHUNK_SIZE; x++) {
		for (int y = 0; y < World.CHUNK_SIZE; y++) {
		for (int z = 0; z < World.CHUNK_SIZE; z++) {
			int index = x + z * World.CHUNK_SIZE + y * Chunk.AREA;
			int gx = x + chunkPosition.X * World.CHUNK_SIZE;
			int gy = y + chunkPosition.Y * World.CHUNK_SIZE;
			int gz = z + chunkPosition.Z * World.CHUNK_SIZE;
			if (gy < World.noise1.GetNoise2D(gx, gz) * 8) {
				blocks[index] = 1;
				isEmpty = false;
			}
		}}} 
	}


	public int GetBlock(Vector3I pos) {
		int index = pos.X + pos.Z * World.CHUNK_SIZE + pos.Y * Chunk.AREA;
		return blocks[index];
	}


	public void GenMesh() {
		meshGenned = true;
		if (isEmpty) return;
		mesh.BuildMesh(ref blocks);
	}
}
