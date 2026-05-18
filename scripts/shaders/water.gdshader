shader_type spatial;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform mediump float refraction_strength : hint_range(0.0, 0.5) = 0.15;
uniform mediump float speed = 1.0;
uniform mediump float height_scale = 0.1;
uniform sampler2D noise;
uniform mediump float noise_scale = 0.1;
uniform lowp vec4 color: source_color = vec4(0.1, 0.3, 0.5, 0.8);
uniform mediump float metallic: hint_range(0.0, 1.0) = 0.0;
uniform mediump float roughness: hint_range(0.0, 1.0) = 0.2;
uniform mediump float specular: hint_range(0.0, 1.0) = 0.3;
uniform mediump float rim: hint_range(0.0, 1.0) = 0.2;
uniform mediump float foam_width = 0.05;
uniform mediump float fogginess: hint_range(0.0, 1.0) = 0.5;
uniform lowp vec3 fog_color: source_color = vec3(0.15, 0.225, 0.3);

varying float height;

float wave(vec2 pos, float scale_xz, float scale_y, float pointiness) {
	mediump vec2 new_pos = pos + texture(noise, pos).x - 0.5;
	mediump vec2 wv = abs(sin(scale_xz * new_pos));
	return pow(1.0 * wv.x * wv.y, pointiness) * scale_y;
}

float get_height(vec2 pos, float time) {
	mediump float h = wave(pos + time * 0.05, 8.0, 0.25, 2.0);
	//h += wave(pos - time * 0.01, 8.0, 0.2, 4.0);
	h += wave(pos - time * 0.03, 12.0, 0.25, 1.0);
	//h += wave(vec2(pos.y - time * 0.01, pos.x + time * 0.01), 1, 0.5, 4.0);
	//h += wave(vec2(pos.y + time * 0.01, pos.x - time * 0.01), 1, 0.5, 4.0);
	return h * height_scale;
}

void vertex() {
	// Called for every vertex the material is visible on.
	vec2 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xz;
	vec2 global_pos = world_pos + VERTEX.xz * noise_scale;
	height = get_height(global_pos, TIME * speed);
	VERTEX.y += height;
	
	NORMAL = normalize(vec3(height - get_height(global_pos + vec2(0.1, 0.0), TIME * speed), 0.1, height - get_height(global_pos + vec2(0.0, 0.1), TIME * speed)));
}

float linear_depth(vec2 uv, mat4 inv_proj_mat, float depth) {
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 world = inv_proj_mat * vec4(ndc, 1.0);
	world.xyz /= world.w;
	return -world.z;
}

void fragment() {
	// Called for every pixel the material is visible on.
	//float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	//ALPHA = color.a;
	METALLIC = metallic;
	RIM = rim;
	SPECULAR = specular;
	
	mediump vec2 distorted_uv = clamp(SCREEN_UV + height * refraction_strength, 0.0, 1.0);
	mediump vec3 refraction = texture(SCREEN_TEXTURE, distorted_uv).rgb;
	
	
	float scene_depth = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX, texture(DEPTH_TEXTURE, SCREEN_UV).r);
	float water_depth = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX, FRAGCOORD.z);
	
	float depth_diff = scene_depth - water_depth;
	float foaminess = smoothstep(foam_width, 0.0, depth_diff);
	
	ALBEDO = mix(mix(mix(color.rgb/* + (0.01 * fresnel)*/, refraction, 1.0 - color.a), fog_color, clamp(fogginess * depth_diff, 0.0, 1.0)), vec3(1.0, 1.0, 1.0), foaminess);
	ROUGHNESS = mix(clamp(roughness/* * (1.0 - fresnel)*/, 0.0, 1.0), 1.0, foaminess);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
