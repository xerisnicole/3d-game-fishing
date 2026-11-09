extends Button

@onready var quantity_label: Label = $QuantityLabel
@onready var preview_model: Node3D = $SubViewportContainer/SubViewport/PreviewModel
@onready var preview_camera: Camera3D = $SubViewportContainer/SubViewport/PreviewCamera
@onready var equipped_label: Label = $EquippedLabel


var item_name: String = ""
var item_type: String = "fish"
var item_quantity: int = 1

func setup_item(display_name: String, model_scene: PackedScene, quantity: int = 1, type: String = "fish") -> void:
	item_name = display_name
	item_type = type
	item_quantity = quantity

	quantity_label.text = "×" + str(item_quantity)
	quantity_label.visible = item_quantity > 1

	for child in preview_model.get_children():
		child.queue_free()

	if model_scene != null:
		var model = model_scene.instantiate()
		preview_model.add_child(model)
		_frame_preview(model)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	var inventory = get_tree().get_first_node_in_group("player_inventory")
	if inventory != null:
		inventory.show_item_hover(item_name)

func _on_mouse_exited() -> void:
	var inventory = get_tree().get_first_node_in_group("player_inventory")
	if inventory != null:
		inventory.hide_item_hover()

func _frame_preview(model: Node3D) -> void:
	var bounds := AABB()
	var found_mesh := false

	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var mesh_bounds := mesh_instance.global_transform * mesh_instance.get_aabb()
			if not found_mesh:
				bounds = mesh_bounds
				found_mesh = true
			else:
				bounds = bounds.merge(mesh_bounds)

	if not found_mesh:
		return

	var center := bounds.get_center()
	var size := bounds.size.length()

	preview_camera.position = center + Vector3(0, 0, maxf(size * 1.8, 1.0))
	preview_camera.look_at(center, Vector3.UP)

func set_equipped(is_equipped: bool) -> void:
	equipped_label.visible = is_equipped
