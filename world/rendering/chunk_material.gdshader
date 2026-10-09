shader_type spatial;

render_mode unshaded;

uniform sampler2D atlas;

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
	uint bytes4u = floatBitsToUint(ogx);
	int bytes4s = floatBitsToInt(ogx);
	UV = UV_TABLE[bitfieldExtract(bytes4u, 24, 3)];
	NORMAL = NORMAL_TABLE[bitfieldExtract(bytes4u, 27, 3)];
	VERTEX = vec3(
		float(bitfieldExtract(bytes4s, 0, 8)),
		float(bitfieldExtract(bytes4s, 8, 8)),
		float(bitfieldExtract(bytes4s, 16, 8)));
	COLOR = vec4(vec3(0.1) + abs(NORMAL * 0.5) + NORMAL * 0.25, 1.0);
}

void fragment() {
	if (UV.x > 1.0 || UV.y > 1.0) discard;
	ALBEDO = COLOR.xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
