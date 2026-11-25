extends CharacterBody3D

const SPLASH_VFX_SCENE: PackedScene = preload("res://addons/water_splash_vfx/SCENES/splash_vfx.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var splash_sound: AudioStreamPlayer = $SplashSound
@onready var fish_bite_sound: AudioStreamPlayer = $FishBiteSound
@onready var fishing_line_snap_sound: AudioStreamPlayer = $FishingLineSnapSound
@onready var catch_prompt_label: Label = $"../../../../../../UI/CatchPromptLabel"


var is_in_water: bool = false
var is_waiting_for_fish: bool = false
var water_height := 0.0
var fish_has_bitten: bool = false
var minigame_is_open: bool = false
var bobber_start_height := 0.0
var is_bobbing : bool = false
var current_water_location: int = 0
var fish_collection: FishCollection
var catch_display: Control
var fishing_minigame: Control
var pending_fish: FishData = null
var fish_got_away_label: Label

const RARITY_CHANCES = {
	FishData.FishRarity.COMMON: 40.0,
	FishData.FishRarity.UNCOMMON: 30.0,
	FishData.FishRarity.RARE: 18.0,
	FishData.FishRarity.EPIC: 9.0,
	FishData.FishRarity.LEGENDARY: 3.0
}

func _ready() -> void:
	catch_prompt_label.hide()
	
	$WaterDetector.area_entered.connect(_on_water_detector_area_entered)
	$WaterDetector.area_exited.connect(_on_water_detector_area_exited)
	
	var collections = get_tree().get_nodes_in_group("fish_collection")
	if not collections.is_empty():
		fish_collection = collections[0] as FishCollection
	
	catch_display = get_tree().get_first_node_in_group("catch_display") as Control
	fishing_minigame = get_tree().current_scene.get_node("UI/FishingMiniGame") as Control
	fish_got_away_label = get_tree().current_scene.get_node("UI/FishGotAwayLabel") as Label
	fish_got_away_label.hide()
	
	print("Fishing minigame found: ", fishing_minigame != null)
	
	if fishing_minigame != null:
		fishing_minigame.minigame_won.connect(_on_minigame_won)
		fishing_minigame.minigame_lost.connect(_on_minigame_lost)


func _physics_process(delta: float) -> void:
	if not is_in_water:
		if not is_on_floor():
			velocity += get_gravity() * delta

		if is_on_floor() and velocity.y <= 0:
			velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO
		
		if fish_has_bitten:
			global_position.y = water_height - 0.25
		else:
			global_position.y = water_height

	move_and_slide()


func _on_water_detector_area_entered(area: Area3D) -> void:
	if area.is_in_group("water"):
		splash_sound.play()
		spawn_splash_vfx()
		is_in_water = true
		water_height = global_position.y
		
		current_water_location = int(area.get_meta("water_location", 0))
		
		print("Bobber entered water!")
		print("Water location ID: ", current_water_location)
		
		if fish_collection != null:
			var eligible_fish = fish_collection.get_fish_for_location(current_water_location)
			print("Eligible fish: ", eligible_fish.size())
		start_fishing_timer()


func _on_water_detector_area_exited(area: Area3D) -> void:
	if area.is_in_group("water"):
		stop_catch_prompt_blink()
		is_in_water = false
		is_waiting_for_fish = false
		fish_has_bitten = false
		print("Bobber left water!")


func start_fishing_timer() -> void:
	if is_waiting_for_fish or fish_has_bitten:
		return
		
	is_waiting_for_fish = true
	print("Waiting for a fish...")

	var wait_time = randf_range(3.0, 8.0)
	await get_tree().create_timer(wait_time).timeout

	if is_in_water and is_waiting_for_fish:
		is_waiting_for_fish = false
		fish_has_bitten = true
		is_bobbing = true
		animation_player.play("fishbite")
		fish_bite_sound.play()
		start_catch_prompt_blink()
		print("A fish has bitten! Press E to catch!")


func _input(event: InputEvent) -> void:
	if catch_display != null and catch_display.get("catch_display_open"):
		return
		
	if minigame_is_open:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and fish_has_bitten:
			if fishing_minigame == null:
				print("Error: FishingMiniGame not found!")
				return
				
			if fish_collection == null:
				print("Error: FishCollection not found!")
				return
				
			var eligible_fish = fish_collection.get_fish_for_location(current_water_location)
			
			if eligible_fish.is_empty():
				print("No fish available in this water!")
				return
			
			# Group eligible fish by rarity.
			var fish_by_rarity: Dictionary = {}
			
			for fish in eligible_fish:
				if not fish_by_rarity.has(fish.rarity):
					fish_by_rarity[fish.rarity] = []
					
				fish_by_rarity[fish.rarity].append(fish)
				
			# Find the rarities available in this water.
			var available_rarities: Array = []
			var total_chance: float = 0.0
				
			for rarity in RARITY_CHANCES:
				if fish_by_rarity.has(rarity):
					available_rarities.append(rarity)
					total_chance += RARITY_CHANCES[rarity]
					
			if available_rarities.is_empty():
				print("No eligible fish rarities found!")
				return
				
			# Choose a rarity using the configured chances.
			var random_weight = randf_range(0.0, total_chance)
			var weight_so_far: float = 0.0
			var selected_rarity = available_rarities[0]
			
			for rarity in available_rarities:
				weight_so_far += RARITY_CHANCES[rarity]
				
				if random_weight <= weight_so_far:
					selected_rarity = rarity
					break
					
			# Choose a fish within the selected rarity.
			var rarity_fish: Array = fish_by_rarity[selected_rarity]
			var selected_fish: FishData = rarity_fish[0]
			var total_fish_weight: float = 0.0
			
			for fish in rarity_fish:
				total_fish_weight += fish.catch_weight
				
			if total_fish_weight > 0.0:
				var fish_roll = randf_range(0.0, total_fish_weight)
				var fish_weight_so_far: float = 0.0
				
				for fish in rarity_fish:
					fish_weight_so_far += fish.catch_weight
					
					if fish_roll <= fish_weight_so_far:
						selected_fish = fish
						break
			
			# Store the fish temporarily. It is not awarded yet.
			pending_fish = selected_fish
			minigame_is_open = true
			
			# Stop the fishbite animation and sound.
			stop_catch_prompt_blink()
			fish_has_bitten = false
			is_bobbing = false
			fish_bite_sound.stop()
			animation_player.stop()
			
			# Reset the bobber back to the fishing rod.
			var player = get_tree().get_first_node_in_group("player")
			
			if player != null:
				player.fishing_rod.stop_fishing()
			else:
				print("Error: Player not found!")
			
			print("Pending fish: ", pending_fish.fish_name)
			print("Rarity: ", FishData.FishRarity.keys()[pending_fish.rarity])
			
			fishing_minigame.start_minigame()


func _process(delta: float) -> void:
	if fish_has_bitten and not fish_bite_sound.playing:
		fish_bite_sound.play()


func _on_minigame_won() -> void:
	print("Fishing minigame won!")
	stop_catch_prompt_blink()

	minigame_is_open = false
	fish_has_bitten = false
	is_bobbing = false

	fish_bite_sound.stop()
	animation_player.stop()

	if pending_fish == null:
		print("Error: No pending fish to award!")
		return

	var player = get_tree().get_first_node_in_group("player")

	if player != null and catch_display != null:
		player.fishing_rod.return_bobber_and_show_catch(pending_fish, catch_display)
		pending_fish = null
	else:
		print("Error: Player or CatchDisplay not found!")


func _on_minigame_lost() -> void:
	fishing_line_snap_sound.play()
	print("Fishing minigame lost!")
	stop_catch_prompt_blink()
	show_fish_got_away()

	minigame_is_open = false
	fish_has_bitten = false
	is_bobbing = false
	pending_fish = null

	fish_bite_sound.stop()
	animation_player.stop()

	var player = get_tree().get_first_node_in_group("player")

	if player != null:
		player.fishing_rod.stop_fishing()
		player.fishingStarted = false
		player.set_physics_process(true)
	else:
		print("Error: Player not found!")

func show_fish_got_away() -> void:
	if fish_got_away_label == null:
		return

	fish_got_away_label.show()
	fish_got_away_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(
		fish_got_away_label,
		"modulate:a",
		0.0,
		0.8
	)
	tween.tween_callback(fish_got_away_label.hide)
	
var catch_prompt_tween: Tween

func start_catch_prompt_blink() -> void:
	catch_prompt_label.show()
	catch_prompt_label.modulate.a = 1.0
	
	if catch_prompt_tween and catch_prompt_tween.is_running():
		catch_prompt_tween.kill()

	catch_prompt_tween = create_tween()
	catch_prompt_tween.set_loops()
	catch_prompt_tween.tween_property(catch_prompt_label, "modulate:a", 0.2, 0.5)
	catch_prompt_tween.tween_property(catch_prompt_label, "modulate:a", 1.0, 0.5)

func stop_catch_prompt_blink() -> void:
	if catch_prompt_tween and catch_prompt_tween.is_running():
		catch_prompt_tween.kill()

	catch_prompt_label.hide()
	catch_prompt_label.modulate.a = 1.0

func spawn_splash_vfx() -> void:
	var splash_vfx = SPLASH_VFX_SCENE.instantiate() as Node3D
	splash_vfx.scale = Vector3(0.4, 0.4, 0.4)
	get_tree().current_scene.add_child(splash_vfx)
	splash_vfx.global_position = global_position
