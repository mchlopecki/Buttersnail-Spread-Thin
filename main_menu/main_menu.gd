extends Node

@export var start_button : Button
@export var house_button : Button
@export var exit_button : Button
var main_game = preload("res://levels/house_demo.tscn")
var house_test = preload("res://levels/bakery.tscn")

func _ready():
	start_button.pressed.connect(load_scene.bind(main_game))
	house_button.pressed.connect(load_scene.bind(house_test))
	exit_button.pressed.connect(quit_game)

func load_scene(scene):
	get_tree().change_scene_to_packed(scene)

func quit_game():
	get_tree().quit()
