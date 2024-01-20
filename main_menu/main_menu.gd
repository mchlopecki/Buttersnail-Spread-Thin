extends Node

@onready var start_button = $StartButton
@onready var house_button = $HouseButton
var main_game = preload("res://levels/town_demo.tscn")
var house_test = preload("res://levels/house_demo.tscn")

func _ready():
	start_button.pressed.connect(load_scene.bind(main_game))
	house_button.pressed.connect(load_scene.bind(house_test))

func load_scene(scene):
	get_tree().change_scene_to_packed(scene)
