extends Node3D

@onready var bobber: CharacterBody3D = %Bobber
@onready var fishing_line_starter_marker: Marker3D = %FishingLineStarterMarker
@onready var bobber_start_marker: Marker3D = %BobberStartMarker
@onready var fishing_line: MeshInstance3D = %FishingLine
@onready var fishing_rod_model: Node3D = $FishingRodModel
@onready var cast_sound: AudioStreamPlayer = $CastSound
@onready var bobber_mesh: MeshInstance3D = %Bobber.get_node("MeshInstance3D")


func _ready() -> void:
	bobber.set_physics_process(false)
	fishing_line.hide()
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if bobber.get_parent() == self:
		bobber.global_position = bobber_start_marker.global_position
	_refresh_line()

func _refresh_line():
	var start_position = fishing_line_starter_marker.global_position
	var end_position = bobber_mesh.global_position

	var direction = end_position - start_position
	var distance = direction.length()
	
	if distance <= 0.001:
		return
	
	fishing_line.global_position = start_position + direction / 2.0
	fishing_line.global_transform = fishing_line.global_transform.looking_at(end_position, Vector3.UP)
	fishing_line.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	if fishing_line.mesh is CylinderMesh:
		fishing_line.mesh.height = distance

func start_fishing():
	print("DEBUG: FishingRod.start_fishing() was called!")
	
	$AnimationPlayer.play("cast")

func stop_fishing():
	bobber.set_physics_process(false)
	
	bobber.reparent(fishing_rod_model, true)
	bobber.global_position = bobber_start_marker.global_position
	bobber.rotation = Vector3.ZERO
	bobber.velocity = Vector3.ZERO
	
	fishing_line.hide()

func _throw_bobber():
	cast_sound.play()
	fishing_line.show()
	
	var camera = get_viewport().get_camera_3d()
	var direction = -camera.global_transform.basis.z
	
	var world = get_tree().current_scene
	
	bobber.reparent(world, true)
	
	bobber.velocity = direction * 8
	bobber.velocity.y += 3
	
	bobber.set_physics_process(true)

func return_bobber_and_show_catch(fish: FishData, catch_display: Control) -> void:
	stop_fishing()
	
	var player = get_tree().get_first_node_in_group("player")
	
	if player != null:
		player.fishingStarted = false
		player.set_physics_process(true)
	
	if catch_display != null:
		catch_display.show_caught_fish(fish)
		
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "cast":
		print("Casting animation finished!")
