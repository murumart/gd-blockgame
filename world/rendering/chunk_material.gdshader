shader_type spatial;

render_mode unshaded;

const vec3 NORMAL_TABLE[6] = vec3[6] (
	vec3(0, 0, 1),
	vec3(0, 1, 0),
	vec3(1, 0, 0),
	vec3(0, 0, -1),
	vec3(0, -1, 0),
	vec3(-1, 0, 0)
);

void vertex() {
	float ogx = VERTEX.x;
	uint bytes4 = floatBitsToUint(VERTEX.x);
	NORMAL = NORMAL_TABLE[bitfieldExtract(bytes4, 24, 3)];
	VERTEX = vec3(
		float(bitfieldExtract(bytes4, 0, 8)),
		float(bitfieldExtract(bytes4, 8, 8)),
		float(bitfieldExtract(bytes4, 16, 8)));
	if (ogx == 0.0) {
		VERTEX.y += sin(float(VERTEX_ID));
		VERTEX.z += cos(float(VERTEX_ID));
	}
	COLOR = vec4(vec3(0.1) + abs(NORMAL * 0.5) + NORMAL * 0.25, 1.0);
	//if (posx == 0u || posy == 0u || posz == 0u) COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	//if (posx == 0u) COLOR.b = 1.0;
	//if (posz == 0u) COLOR.r = 1.0;
	//if (posy == 0u) COLOR.g = 1.0;

	//VERTEX.x += sin(TIME + VERTEX.y);
}

void fragment() {
	//ALBEDO = vec3(0.5) - NORMAL * 0.5;
	ALBEDO = COLOR.xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
