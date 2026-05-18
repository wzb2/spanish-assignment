shader_type spatial;

render_mode cull_disabled, depth_draw_opaque;

const vec3 FORWARD_DIR = vec3(0.0, 0.0, 1.0);
const vec3 RIGHT_DIR = vec3(1.0, 0.0, 0.0);

uniform vec3 top_color: source_color = vec3(0.0, 0.223, 0.0);
uniform vec3 bottom_color: source_color = vec3(0.341, 1.0, 0.447);

uniform float bend = 0.1;

uniform float dip_percentage = 0.4;

uniform vec3 color_variation: source_color = vec3(0.9, 0.9, 0.2);
uniform float noise_scale = 5.0;
uniform sampler2D wind_noise: hint_default_white;
uniform float noise_factor_multiplier = 0.3;

uniform vec2 wind_direction = vec2(-1.0, 0.0);
uniform float wind_texture_scale = 20.0;
uniform float wind_speed = 0.1;
uniform float wind_strength = 0.3;
uniform float still_sway_speed = 4.5;
uniform float still_sway_strength = 0.1;

uniform float push_strength = 5.0;

uniform vec3[32] push_object_positions;
uniform lowp float[32] push_object_radii;
uniform int num_push_objects;

varying float noise_factor;

void vertex() {
	// Called for every vertex the material is visible on.
	float bend_strength = pow(1.0 - UV.y, 2.0);

	vec3 bent_vertex_pos = VERTEX + FORWARD_DIR * bend * bend_strength;

	vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	noise_factor = texture(wind_noise, world_pos.xz / noise_scale).r;

	vec2 global_wind_pos = (world_pos.xz / wind_texture_scale) + normalize(wind_direction) * TIME * wind_speed;
	float wind_val = texture(wind_noise, global_wind_pos).r;

	float idle_sway = sin(TIME * still_sway_speed + world_pos.x + world_pos.z) * still_sway_strength;

	vec3 sway_offset = vec3(bent_vertex_pos.x, 0, bent_vertex_pos.z) * idle_sway;
	vec3 wind_offset = (mat3(inverse(MODEL_MATRIX)) * vec3(-wind_direction.x, 0.0, -wind_direction.y)) * wind_val * wind_strength;

	vec3 total_offset = (sway_offset + wind_offset) * bend_strength;

	vec3 dip = length(total_offset.xz) * vec3(0.0, -dip_percentage, 0.0);

	VERTEX = bent_vertex_pos + total_offset + dip;

	for (int i = 0; i < num_push_objects; i++) {
		vec3 pusher_pos = push_object_positions[i];
		float pusher_radius = push_object_radii[i];

		vec3 pos_difference = world_pos - pusher_pos;
		float dist = length(pos_difference);

		if (dist < pusher_radius) {
			vec3 push_direction = normalize((mat3(inverse(MODEL_MATRIX)) * vec3(pos_difference.x, 0.0, pos_difference.z)));

			vec3 push_offset = push_direction * pow(1.0 - (dist / pusher_radius), 2.0) * push_strength * bend_strength * (1.0 - dip_percentage);

			VERTEX += push_offset + length(push_offset.xz) * vec3(0.0, -dip_percentage, 0.0);
		}
	}
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 gradient = mix(top_color, bottom_color, UV.y);
	vec3 varied_color = mix(gradient, color_variation, noise_factor * noise_factor_multiplier);

	ALBEDO = varied_color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
