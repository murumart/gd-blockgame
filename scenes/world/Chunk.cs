using Godot;
using System;
using System.Collections.Generic;

public partial class Chunk : Node3D {
	public const short WIDTH = 32;
	public const short HEIGHT = 32;
	public const int AREA = WIDTH * WIDTH;
	public const int VOLUME = AREA * HEIGHT;

	public Vector3I chunkPosition = new(0, 0, 0);
	public short[] blocks = new short[VOLUME];

	public ChunkMesh mesh;


	public override void _Ready()
	{
		base._Ready();
		mesh = GetNode<ChunkMesh>("ChunkMesh");
		mesh.chunkPosition = chunkPosition;

		for (short x = 0; x < Chunk.WIDTH; x++) {
		for (short y = 0; y < Chunk.WIDTH; y++) {
		for (short z = 0; z < Chunk.WIDTH; z++) {
			int index = x + z * Chunk.WIDTH + y * Chunk.AREA;
			if (y < 7) {
				blocks[index] = 1;
			}
		}}}

		mesh.BuildMesh(ref blocks);
	}
}
