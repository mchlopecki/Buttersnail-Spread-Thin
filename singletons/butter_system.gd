extends Node

@export var butter_container := preload("res://effects/butter_container.tscn")
@export var butter_blob := preload("res://effects/butter_blob.tscn")
var bodies_3d := [StaticBody3D, AnimatableBody3D, RigidBody3D, VehicleBody3D] # softbody3d, characterbody3d?

func _ready():
    get_tree().node_added.connect(_add_butter_container)

func _add_butter_container(new_node):
    if (not new_node.is_in_group("system_added")):
        for bt in bodies_3d:
            if is_instance_of(new_node, bt):
                var cont = butter_container.instantiate()
                cont.fresh_body_exited.connect(_move_to_active_container.bind(cont), CONNECT_DEFERRED)
                new_node.add_child(cont)

func _move_to_active_container(_body, container):
    for child in container.fresh_butter.get_children():
        child.reparent(container.active_butter)
