extends Control

var minimized = true : set = _set_minimized
@onready var anim_player = $AnimationPlayer
@onready var task_container = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
var toptask

func _set_minimized(value):
    minimized = value
    if minimized:
        anim_player.play("contract")
    else:
        anim_player.play("expand")

func _unhandled_input(event):
    if event.is_action_pressed("ui_focus_next"):
        minimized = not minimized

func add_toptask(task):
    if task is Control:
        toptask = task
        task_container.add_child(task)

func update_toptask(hint_text):
    if toptask:
        toptask.set_hint_text(hint_text)