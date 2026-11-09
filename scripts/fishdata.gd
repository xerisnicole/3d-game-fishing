extends Resource
class_name FishData

@export var fish_name: String = "New Fish"

enum FishRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var rarity: FishRarity = FishRarity.COMMON

@export var fish_scene: PackedScene

@export_flags("Lake", "North Sea", "South Sea", "East Sea")
var available_locations: int = 0

@export var catch_weight: float = 100.0
