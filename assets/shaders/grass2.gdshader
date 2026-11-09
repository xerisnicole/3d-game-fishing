
shader_type spatial;
render_mode cull_disabled, unshaded;

// WIND SETTINGS
uniform float wind_speed = 0.2;
uniform float wind_strength = 2.0;
uniform float wind_texture_tile_size = 20.0;
uniform float wind_vertical_strength = 0.3;
uniform vec2 wind_horizontal_direction = vec2(1.0, 0.5);

// GRASS COLORS AND WIND NOISE
uniform sampler2D color_ramp : source_color, hint_default_black;
uniform sampler2D wind_noise : hint_default_black;

// CHARACTER INTERACTION
uniform vec3 character_position = vec3(0.0);
uniform float character_radius = 3.0;
uniform sampler2D character_distance_falloff_curve : hint_default_black;
uniform float character_push_strength = 1.0;

void vertex() {
	// Convert the grass vertex to world space.
	vec3 world_vert = (
		MODEL_MATRIX * vec4(VERTEX, 1.0)
	).xyz;

	// Determine the wind direction.
	vec2 normalized_wind_direction =
		normalize(wind_horizontal_direction);

	// Scroll the noise texture through world space.
	vec2 world_uv =
		world_vert.xz / wind_texture_tile_size
		+ normalized_wind_direction * TIME * wind_speed;

	// Affect the top of the blade more than its base.
	// This assumes UV.y = 1.0 at the base
	// and UV.y = 0.0 at the tip.
	float displacement_affect = 1.0 - UV.y;

	// Sample noise to create varied wind movement.
	float wind_noise_intensity =
		textureLod(wind_noise, world_uv, 0.0).r - 0.5;

	// Convert the wind direction from world space
	// into the grass object's local space.
	vec3 world_direction_3d = vec3(
		wind_horizontal_direction.x,
		0.0,
		wind_horizontal_direction.y
	);

	vec3 local_wind_direction = (
		inverse(MODEL_MATRIX)
		* vec4(world_direction_3d, 0.0)
	).xyz;

	vec2 vert_space_horizontal_dir =
		normalize(local_wind_direction.xz);

	// Build the wind displacement.
	vec3 bump_wind = vec3(
		wind_noise_intensity * vert_space_horizontal_dir.x,
		1.0 - wind_noise_intensity,
		wind_noise_intensity * vert_space_horizontal_dir.y
	);

	bump_wind = normalize(bump_wind);

	bump_wind *= vec3(
		wind_strength,
		wind_vertical_strength,
		wind_strength
	);

	VERTEX += bump_wind * displacement_affect;

	// CHARACTER-BASED GRASS DEFORMATION
	// Calculate the direction from the grass object
	// toward the character in world space.
	vec3 dir_to_character =
		character_position - MODEL_MATRIX[3].xyz;

	float distance_to_character = length(dir_to_character);

	// Calculate a smooth falloff within the character radius.
	float falloff = 1.0 - smoothstep(
		0.0,
		1.0,
		distance_to_character / max(character_radius, 0.001)
	);

	// Convert the direction into local space.
	dir_to_character = (
		inverse(MODEL_MATRIX)
		* vec4(dir_to_character, 0.0)
	).xyz;

	dir_to_character = normalize(dir_to_character);

	// Sample the falloff curve.
	float falloff_curve = texture(
		character_distance_falloff_curve,
		vec2(falloff, 0.5)
	).r;

	// Push the grass away from the character.
	VERTEX += normalize(-dir_to_character)
		* falloff_curve
		* character_push_strength
		* displacement_affect;
}

void fragment() {
	// Apply the grass color gradient from base to tip.
	ALBEDO = texture(
		color_ramp,
		vec2(1.0 - UV.y, 0.0)
	).rgb;
}