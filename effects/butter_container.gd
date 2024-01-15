extends Node3D

signal fresh_body_exited

@onready var active_butter = $ActiveButter
@onready var fresh_butter = $FreshButter
@onready var blob_multimesh = $BlobRenderer.multimesh
var blob_count = 0
var bound := false

func _on_fresh_butter_body_exited(body:Node3D):
	fresh_body_exited.emit(body)

func add_new_blob(blob):
	blob_multimesh.visible_instance_count += 1
	blob_multimesh.set_instance_transform(blob_count, Transform3D(Basis(), blob.position))
	blob_count += 1
