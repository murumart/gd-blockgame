using Godot;
using System;
using System.Collections.Generic;

public partial class World : Node
{
	public static readonly int CHUNK_SIZE = 32;
	public readonly int WORLD_SIZE = 128;
	public static Dictionary<Vector3I, Chunk> chunks = new Dictionary<Vector3I, Chunk>();
	
	public static FastNoiseLite noise1 = new FastNoiseLite();

	public override void _Ready() {
		
	}

	
	public int GetBlock(int x, int y, int z) {
		Chunk c = IsInWhichChunk(x, y, z);
		return c.GetBlock(ToInsideChunkPos(x, y, z));
		//return 0;
	}


	private Chunk IsInWhichChunk(int x, int y, int z) {
		Vector3I v3 = new(
			(int)Math.Floor((float)x / CHUNK_SIZE),
			(int)Math.Floor((float)y / CHUNK_SIZE),
			(int)Math.Floor((float)z / CHUNK_SIZE)
		);
		return GetChunk(v3);
	}


	private static Vector3I ToInsideChunkPos(int x, int y, int z) {
		// https://stackoverflow.com/questions/14415753/wrap-value-into-range-min-max-without-division
		int min = 0;
		int maxxz = CHUNK_SIZE;
		int maxy = CHUNK_SIZE;
		return new Vector3I(
			(((x - min) % (maxxz - min)) + (maxxz - min)) % (maxxz - min) + min,
			(((y - min) % (maxy - min)) + (maxy - min)) % (maxy - min) + min,
			(((z - min) % (maxxz - min)) + (maxxz - min)) % (maxxz - min) + min
		);
	}


	public Chunk GetChunk(Vector3I pos) {
		if (chunks.ContainsKey(pos)) {
			return chunks[pos];
		} else {
			return AddChunk(pos);
		}
	}


	public Chunk AddChunk(Vector3I pos) {
		if (chunks.ContainsKey(pos)) {
			return chunks[pos];
		}
		var cscene = GD.Load<PackedScene>("res://scenes/world/chunk.tscn");
		Chunk c = cscene.Instantiate<Chunk>();
		c.Name = pos.ToString();
		c.chunkPosition = pos;
		chunks[pos] = c;
		AddChild(c);
		c.GlobalPosition = new Vector3(
			pos.X * CHUNK_SIZE,
			pos.Y * CHUNK_SIZE,
			pos.Z * CHUNK_SIZE
		);
		return c;
	}
}
