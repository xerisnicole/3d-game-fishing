extends Node
class_name FishCollection

@export var all_fish: Array[FishData] = []

func get_fish_for_location(location: int) -> Array[FishData]:
	var eligible_fish: Array[FishData] = []
	
	for fish in all_fish:
		if fish == null:
			continue
		
		if (fish.available_locations & location) != 0:
			eligible_fish.append(fish)
	
	return eligible_fish

func _ready() -> void:
	var north_sea_fish = get_fish_for_location(2)
	var south_sea_fish = get_fish_for_location(4)
	var lake_fish = get_fish_for_location(1)
	var east_sea_fish = get_fish_for_location(8)
	
	print("North Sea fish: ", north_sea_fish.size())
	print("South Sea fish: ", south_sea_fish.size())
	print("Lake fish:", lake_fish.size())
	print("East Sea fish: ", east_sea_fish.size())
