extends Node

var town_scene = preload("res://levels/town_demo.tscn")
var bakery = preload("res://levels/bakery.tscn")

func change_to_town():
    get_tree().unload_current_scene()
    get_tree().change_scene_to_packed(town_scene)

func change_to_bakery():
    get_tree().unload_current_scene()
    get_tree().change_scene_to_packed(bakery)
    