extends Node

@onready var button = $Button
var main_game = preload("res://levels/town_demo.tscn")

func _ready():
	button.pressed.connect(start_game)

func start_game():
	get_tree().change_scene_to_packed(main_game)
