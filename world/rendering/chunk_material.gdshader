shader_type spatial;

render_mode diffuse_lambert_wrap;

uniform sampler2D terrain : filter_nearest, repeat_disable, source_color;
uniform uint terrain_atlas_blocks_x;
uniform uint terrain_atlas_blocks_y;
uniform uint terrain_atlas_block_size;

const vec3 CHUNK_SIZE = vec3(16, 16, 16);
const float RANGEM = 1.0;

varying vec2 atlas_spot;

const vec3 NORMAL_TABLE[7] = vec3[7] (
	// invalid value
	// i have no idea why, but i can't just have 0 passed in
	// as the normal index. for whatever reason, it just treats
	// the rest of the data as 0 then
	vec3(0, 0, 0),
	vec3(0, 0, 1),
	vec3(0, 1, 0),
	vec3(1, 0, 0),
	vec3(0, 0, -1),
	vec3(0, -1, 0),
	vec3(-1, 0, 0)
);

const vec2 UV_TABLE[3] = vec2[3] (
	vec2(0, 0),
	vec2(0, 2),
	vec2(2, 0)
);

void vertex() {
	float ogx = VERTEX.x;
	float ogy = VERTEX.y;
	uint bytes4u = floatBitsToUint(ogx);
	uint bytes4u2 = floatBitsToUint(ogy);
	vec2 uv = UV_TABLE[bitfieldExtract(bytes4u, 24, 2)];
	NORMAL = NORMAL_TABLE[bitfieldExtract(bytes4u, 26, 3)];
	uint tx_index = bitfieldExtract(bytes4u2, 0, 12);
	vec3 vpos = vec3(
		float(bitfieldExtract(bytes4u, 0, 8)) / RANGEM - 1.0,
		float(bitfieldExtract(bytes4u, 8, 8)) / RANGEM - 1.0,
		float(bitfieldExtract(bytes4u, 16, 8)) / RANGEM - 1.0
	);
	VERTEX = vpos;
	UV = uv;
	UV.y = 1.0 - UV.y;
	atlas_spot = vec2(
		float(tx_index % terrain_atlas_blocks_x) / float(terrain_atlas_blocks_x),
		float(tx_index / terrain_atlas_blocks_y) / float(terrain_atlas_blocks_y)
	);
	//COLOR = vec4(vec3(0.1) + abs(NORMAL * 0.5) + NORMAL * 0.25, 1.0);
}

void fragment() {
	if (UV.x > 1.0 || UV.y < 0.0) discard;
	vec2 atlas_size = vec2(float(terrain_atlas_blocks_x), float(terrain_atlas_blocks_y));
	vec4 sample = texture(terrain, UV / atlas_size + atlas_spot);
	ALBEDO = COLOR.rgb * sample.rgb;
	//ALBEDO = vec3(0.0);
	//ALBEDO.rg = UV / atlas_size + atlas_spot;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
