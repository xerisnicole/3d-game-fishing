extends Control

@onready var panel: Panel = $Background/Panel
@onready var title: Label = $Background/Panel/Title
@onready var content: VBoxContainer = $Background/Panel/Content
@onready var previous_page_button: Button = $Background/Panel/PreviousPageButton
@onready var next_page_button: Button = $Background/Panel/NextPageButton
@onready var close_button: Button = $Background/Panel/CloseButton
@onready var flip_page_button_sound: AudioStreamPlayer = $FlipPageButtonSound
@onready var journal_sound: AudioStreamPlayer = $JournalSound


var fish_collection: FishCollection
var current_page: int = 0
var total_pages: int = 4
var journal_open: bool = false
var fish_entry_scene: PackedScene = preload("res://scenes/fish_entry.tscn")
var caught_fish: Array[FishData] = []

var page_names: Array[String] = [
	"Page1_Lake",
	"Page2_NorthSea",
	"Page3_SouthSea",
	"Page4_EastSea",
]

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	fish_collection = get_tree().get_first_node_in_group("fish_collection") as FishCollection
	
	if fish_collection == null:
		push_error("FishJournal: FishCollection was not found!")
	
	print("Fish Journal initialized.")
	print("Pages available: ", total_pages)
	
	if fish_collection != null:
		print("Fish resources available: ", fish_collection.all_fish.size())
	
	previous_page_button.pressed.connect(_on_previous_page_button_pressed)
	next_page_button.pressed.connect(_on_next_page_button_pressed)
	close_button.pressed.connect(close_journal)
	
	show_page(0)
	
	if fish_collection != null:
		for i in range(total_pages):
			populate_fish_page(i)


func show_page(page_index: int) -> void:
	current_page = clampi(page_index, 0, total_pages - 1)

	for i in range(page_names.size()):
		var page = content.get_node_or_null("FishCenterContainer/" + page_names[i])

		if page != null:
			page.visible = (i == current_page)

	update_page_title()
	update_navigation_buttons()


func update_page_title() -> void:
	var water_names: Array[String] = [
		"Lake",
		"North Sea",
		"South Sea",
		"East Sea"
		]
	
	title.text = "Fish Collection Journal - " + water_names[current_page]


func update_navigation_buttons() -> void:
	previous_page_button.disabled = current_page == 0
	next_page_button.disabled = current_page == total_pages - 1


func _on_previous_page_button_pressed() -> void:
	show_page(current_page - 1)
	flip_page_button_sound.play()


func _on_next_page_button_pressed() -> void:
	show_page(current_page + 1)
	flip_page_button_sound.play()

func open_journal() -> void:
	journal_open = true
	visible = true
	show_page(current_page)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_journal() -> void:
	journal_open = false
	visible = false
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			if journal_open:
				close_journal()
				journal_sound.play()
			else:
				open_journal()
				journal_sound.play()
		elif journal_open and event.keycode == KEY_Q:
			show_page(current_page - 1)
			flip_page_button_sound.play()
			
		elif journal_open and event.keycode == KEY_R:
			show_page(current_page + 1)
			flip_page_button_sound.play()

func sort_fish_by_rarity(a: FishData, b: FishData) -> bool:
	return a.rarity < b.rarity

func populate_fish_page(page_index: int) -> void:
	var page = content.get_node_or_null("FishCenterContainer/" + page_names[page_index])

	if page == null:
		push_warning("Fish Journal page not found: " + page_names[page_index])
		return

	var fish_grid: GridContainer = page.get_node_or_null("FishGrid")

	if fish_grid == null:
		push_warning("FishGrid not found in " + page_names[page_index])
		return

	# Remove existing fish entries.
	for child in fish_grid.get_children():
		fish_grid.remove_child(child)
		child.queue_free()

	# Lake = 1, North Sea = 2, South Sea = 4, East Sea = 8.
	var water_locations: Array[int] = [1, 2, 4, 8]
	var water_location: int = water_locations[page_index]

	var eligible_fish: Array[FishData] = []

	# Only collect fish available in this body of water.
	for fish in fish_collection.all_fish:
		if fish != null and (fish.available_locations & water_location) != 0:
			eligible_fish.append(fish)

	# Sort from Common to Legendary.
	eligible_fish.sort_custom(sort_fish_by_rarity)

	# Create an entry for each eligible fish.
	for fish in eligible_fish:
		var entry := fish_entry_scene.instantiate() as FishEntry

		if entry == null:
			push_warning("Could not create a FishEntry.")
			continue

		fish_grid.add_child(entry)
		entry.setup(fish, caught_fish.has(fish))

	print("Populated ", page_names[page_index], " with ", eligible_fish.size(), " fish.")

	# Print each fish and its rarity for verification.
	for fish in eligible_fish:
		print(fish.fish_name, " - ", get_rarity_name(fish.rarity))


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

func register_caught_fish(fish: FishData) -> void:
	if fish == null:
		return

	if not caught_fish.has(fish):
		caught_fish.append(fish)
		print("Fish registered in journal: ", fish.fish_name)

		for i in range(total_pages):
			populate_fish_page(i)
