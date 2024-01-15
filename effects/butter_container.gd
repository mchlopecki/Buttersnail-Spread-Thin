extends Node3D

signal fresh_body_exited

@onready var active_butter = $ActiveButter
@onready var fresh_butter = $FreshButter
var bound := false

func _on_fresh_butter_body_exited(body:Node3D):
	fresh_body_exited.emit(body)
