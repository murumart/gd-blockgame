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
	vec3 og = VERTEX;
	uint bytes4 = floatBitsToUint(VERTEX.x);
	uint posx = bitfieldExtract(bytes4, 0, 8);
	uint posy = bitfieldExtract(bytes4, 8, 8);
	uint posz = bitfieldExtract(bytes4, 16, 8);
	uint norm = bitfieldExtract(bytes4, 24, 3);
	NORMAL = NORMAL_TABLE[norm];
	VERTEX = vec3(float(posx), float(posy), float(posz));
	//COLOR = vec4(1.0 - sin(float(VERTEX_ID) * 0.1), cos(float(VERTEX_ID) * 0.1), sin(float(VERTEX_ID)), 1.0);
	if (og.x == 0.0) {
		VERTEX.y += sin(float(VERTEX_ID));
		VERTEX.z += cos(float(VERTEX_ID));
	}
	//if (posx == 0u || posy == 0u || posz == 0u) COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	//if (posx == 0u) COLOR.b = 1.0;
	//if (posz == 0u) COLOR.r = 1.0;
	//if (posy == 0u) COLOR.g = 1.0;

	//VERTEX.x += sin(TIME + VERTEX.y);
}

void fragment() {
	//ALBEDO = vec3(0.5) - NORMAL * 0.5;
	//ALBEDO = COLOR.xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
