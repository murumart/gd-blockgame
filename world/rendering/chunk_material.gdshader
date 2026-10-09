shader_type spatial;

render_mode unshaded;

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

void vertex() {
	float ogx = VERTEX.x;
	uint bytes4 = floatBitsToUint(ogx);
	NORMAL = NORMAL_TABLE[bitfieldExtract(bytes4, 24, 3)];
	VERTEX = vec3(
		float(bitfieldExtract(bytes4, 0, 8)),
		float(bitfieldExtract(bytes4, 8, 8)),
		float(bitfieldExtract(bytes4, 16, 8)));
	COLOR = vec4(vec3(0.1) + abs(NORMAL * 0.5) + NORMAL * 0.25, 1.0);
}

void fragment() {
	ALBEDO = COLOR.xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
