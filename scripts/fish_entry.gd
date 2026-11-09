extends Control
class_name FishEntry

@onready var fish_visual: SubViewportContainer = $Card/Layout/FishVisual
@onready var sub_viewport: SubViewport = $Card/Layout/FishVisual/SubViewport
@onready var preview_world: Node3D = $Card/Layout/FishVisual/SubViewport/PreviewWorld
@onready var preview_camera: Camera3D = $Card/Layout/FishVisual/SubViewport/PreviewWorld/PreviewCamera
@onready var fish_name: Label = $Card/Layout/FishName
@onready var fish_rarity: Label = $Card/Layout/FishRarity

var fish_data: FishData
var fish_model: Node3D

func _ready() -> void:
	fish_name.text = "???"
	fish_rarity.text = "???"
	fish_visual.visible = true

func setup(fish: FishData, has_been_caught: bool) -> void:
	fish_data = fish
	
	if fish_model != null:
		fish_model.queue_free()
		fish_model = null
	
	if fish_data == null:
		return
	
	if fish_data.fish_scene == null:
		push_warning("Fish has no assigned scene: " + fish_data.fish_name)
		return
	
	fish_model = fish_data.fish_scene.instantiate() as Node3D
	
	if fish_model == null:
		push_warning("Fish scene must have a Node3D root.")
		return
	
	preview_world.add_child(fish_model)
	fish_model.position = Vector3.ZERO
	
	if has_been_caught:
		fish_name.text = fish_data.fish_name
		fish_rarity.text = get_rarity_name(fish_data.rarity)
	else:
		fish_name.text = "???"
		fish_rarity.text = "???"
		make_silouhette(fish_model)

func get_rarity_name(rarity: FishData.FishRarity) -> String:
	match rarity:
		FishData.FishRarity.COMMON:
			return "Common"
		FishData.FishRarity.UNCOMMON:
			return "Uncommon"
		FishData.FishRarity.RARE:
			return "Rare"
		FishData.FishRarity.EPIC:
			return "Epic"
		FishData.FishRarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"

func make_silouhette(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var silhouette_material := StandardMaterial3D.new()
		silhouette_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		silhouette_material.albedo_color = Color.BLACK
		mesh_instance.material_override = silhouette_material
	
	for child in node.get_children():
		make_silouhette(child)
