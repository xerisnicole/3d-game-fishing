extends Panel

@onready var equip_button: Button = $EquipButton
@onready var item_name: Label = $"../HotbarBackground/Hotbar/Slot1/ItemName"
@onready var hotbar: HBoxContainer = $"../HotbarBackground/Hotbar"
@onready var proto_controller: CharacterBody3D = $"../../ProtoController"
@onready var item_hover_label: Label = $ItemHoverLabel
@onready var fishing_rod_item: Button = $InventoryScroll/InventoryGrid/FishingRodItem
@onready var inventory_grid: GridContainer = $InventoryScroll/InventoryGrid
@onready var close_button: Button = $CloseButton
@onready var inventory_sfx: AudioStreamPlayer = $InventorySFX


var inventory_items: Array[Dictionary] = []

func _ready():
	add_to_group("player_inventory")
	equip_button.visible = false
	item_name.visible = false
	proto_controller.fishing_rod.visible = false
	
	equip_button.pressed.connect(_on_equip_pressed)
	fishing_rod_item.pressed.connect(_on_fishing_rod_item_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	var rod_preview = preload("res://scenes/fishing_rod_preview.tscn")
	fishing_rod_item.setup_item("Fishing Rod", rod_preview, 1, "rod")
	

func _on_fishing_rod_item_pressed():
	if fishing_rod_item.equipped_label.visible:
		equip_button.text = "[UNEQUIP]"
	else:
		equip_button.text = "[EQUIP]"

	equip_button.visible = not equip_button.visible

func _on_equip_pressed():
	if fishing_rod_item.equipped_label.visible:
		# Unequip the fishing rod.
		fishing_rod_item.set_equipped(false)
		proto_controller.fishing_rod.visible = false
		item_name.visible = false
		equip_button.visible = false
		print("Fishing Rod Unequipped!")
	else:
		# Equip the fishing rod.
		fishing_rod_item.set_equipped(true)
		item_name.text = "Fishing Rod"
		item_name.visible = true
		hotbar.equip_fishing_rod()
		proto_controller.fishing_rod.visible = true
		equip_button.visible = false
		print("Fishing Rod Equipped!")

func _process(_delta: float) -> void:
	if item_hover_label.visible:
		item_hover_label.position = get_local_mouse_position() + Vector2(15, 15)

func show_item_hover(display_name: String) -> void:
	item_hover_label.text = display_name
	item_hover_label.visible = true
	item_hover_label.position = get_local_mouse_position() + Vector2(15, 15)

func hide_item_hover() -> void:
	item_hover_label.visible = false

func add_fish(fish: FishData) -> void:
	for item in inventory_items:
		if item["type"] == "fish" and item["data"] == fish:
			item["quantity"] += 1
			print(fish.fish_name, " quantity: ", item["quantity"])
			refresh_inventory()
			return

	inventory_items.append({
		"type": "fish",
		"data": fish,
		"name": fish.fish_name,
		"quantity": 1
	})

	print("Added fish to inventory: ", fish.fish_name)
	refresh_inventory()

func refresh_inventory() -> void:
	# Remove old fish slots, but keep the fishing rod slot.
	for child in inventory_grid.get_children():
		if child != fishing_rod_item:
			child.queue_free()

	# Copy the inventory data so we can sort it by rarity.
	var sorted_items = inventory_items.duplicate()

	sorted_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var fish_a: FishData = a["data"]
		var fish_b: FishData = b["data"]
		return fish_a.rarity < fish_b.rarity
	)

	# Re-create fish slots in rarity order.
	for item in sorted_items:
		if item["type"] != "fish":
			continue

		var fish: FishData = item["data"]
		var item_scene = preload("res://scenes/inventory_item.tscn")
		var fish_slot = item_scene.instantiate()
		inventory_grid.add_child(fish_slot)

		fish_slot.setup_item(
			fish.fish_name,
			fish.fish_scene,
			item["quantity"],
			"fish"
		)

func _on_close_button_pressed() -> void:
	play_close_sound()
	proto_controller.toggle_inventory()

func play_open_sound() -> void:
	inventory_sfx.pitch_scale = 1.15
	inventory_sfx.play()


func play_close_sound() -> void:
	inventory_sfx.pitch_scale = 0.85
	inventory_sfx.play()
