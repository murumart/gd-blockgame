shader_type spatial;

render_mode depth_prepass_alpha;

const vec3 NORMAL_TABLE[6] = vec3[6] (
	vec3(0, 0, 1),
	vec3(0, 1, 0),
	vec3(1, 0, 0),
	vec3(0, 0, -1),
	vec3(0, -1, 0),
	vec3(-1, 0, 0)
);

void vertex() {
	uint bytes4 = floatBitsToUint(VERTEX.x);
	uint posx = bitfieldExtract(bytes4, 0, 8);
	uint posy = bitfieldExtract(bytes4, 8, 8);
	uint posz = bitfieldExtract(bytes4, 16, 8);
	uint norm = bitfieldExtract(bytes4, 24, 3);
	NORMAL = NORMAL_TABLE[norm];
	VERTEX = vec3(
		float(posx),
		float(posy),
		float(posz)
	);
	//VERTEX.x += sin(TIME + VERTEX.y);
}

void fragment() {
	//ALBEDO = vec3(0.5) - NORMAL * 0.5;
	ALBEDO = vec3(1.0, 1.0, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
