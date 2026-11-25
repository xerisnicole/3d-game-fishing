extends Node3D

@export var sun_light: DirectionalLight3D
@export var moon_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var cycle_length_seconds: float = 1200.0
@export_range(0.0, 24.0, 0.1) var starting_hour: float = 8.0
@export var time_speed_multiplier: float = 1.0

var time_of_day: float = 8.0
var sky_material: ProceduralSkyMaterial

var sky_top_keys = [
	{"hour": 0.0, "color": Color("#101A38")},
	{"hour": 5.0, "color": Color("#263B62")},
	{"hour": 7.0, "color": Color("#8498B5")},
	{"hour": 12.0, "color": Color("#5686B5")},
	{"hour": 17.0, "color": Color("#5686B5")},
	{"hour": 19.0, "color": Color("#D17C68")},
	{"hour": 21.0, "color": Color("#26385D")}]

var sky_horizon_keys = [
	{"hour": 0.0, "color": Color("#1c2b4b")},
	{"hour": 5.0, "color": Color("#B66E76")},
	{"hour": 7.0, "color": Color("#E8B58B")},
	{"hour": 12.0, "color": Color("#B8CDE0")},
	{"hour": 17.0, "color": Color("#B8CDE0")},
	{"hour": 19.0, "color": Color("#E28A65")},
	{"hour": 21.0, "color": Color("#374B73")}]

func _ready():
	time_of_day = starting_hour
	
	if sun_light == null or world_environment == null:
		push_error("Assign the Sun and WorldEnvironment in the Inspector!")
		set_process(false)
		return
		
	if world_environment.environment == null:
		push_error("WorldEnvironment has no Environment resource!")
		set_process(false)
		return
		
	var sky = world_environment.environment.sky
	
	if sky == null:
		push_error("No Sky resource found!")
		set_process(false)
		return
		
	sky_material = sky.sky_material as ProceduralSkyMaterial
	
	if sky_material == null:
		push_error("Sky Material must be ProceduralSkyMaterial!")
		set_process(false)
		return
	
	if moon_light != null:
		moon_light.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
		moon_light.shadow_enabled = false
		
	update_lighting()

func _process(delta):
	time_of_day += (24.0 / cycle_length_seconds) * delta * time_speed_multiplier
	time_of_day = fposmod(time_of_day, 24.0)
	
	update_lighting()

func update_lighting():
	var daylight = maxf(0.0, sin((time_of_day - 6.0) / 12.0 * PI))
	var sun_angle = -((time_of_day - 6.0) * 15.0)
	var sun_rotation = sun_light.rotation_degrees
	sun_rotation.x = sun_angle
	sun_light.rotation_degrees = sun_rotation
	sun_light.light_energy = daylight
	sun_light.light_color = Color(1.0, 0.72, 0.52).lerp(Color(1.0, 0.95, 0.84), daylight)

	if moon_light != null:
		var moon_rotation = sun_light.rotation_degrees
		moon_rotation.x += 180.0
		moon_light.rotation_degrees = moon_rotation

		moon_light.light_energy = 0.12 * (1.0 - daylight)
		moon_light.light_color = Color("#A9C6FF")
	
	sky_material.sky_top_color = get_sky_color(time_of_day, sky_top_keys)
	sky_material.sky_horizon_color = get_sky_color(time_of_day, sky_horizon_keys)

func get_sky_color(hour: float, keys: Array) -> Color:
	for i in range(keys.size()):
		var current = keys[i]
		var next = keys[(i + 1) % keys.size()]
		var start_hour = float(current["hour"])
		var end_hour = float(next["hour"])
		var adjusted_hour = hour
		
		if end_hour <= start_hour:
			end_hour += 24.0
			if adjusted_hour < start_hour:
				adjusted_hour += 24.0
		
		if adjusted_hour >= start_hour and adjusted_hour <= end_hour:
			var weight = (adjusted_hour - start_hour) / (end_hour - start_hour)
			weight = weight * weight * (3.0 - 2.0 * weight)
			
			var start_color: Color = current["color"]
			var end_color: Color = next["color"]
			
			return start_color.lerp(end_color, weight)
			
	return keys[0]["color"]
