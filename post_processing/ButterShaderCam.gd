extends Camera3D

@onready var follow_cam = $"../.."

func _process(_delta):
    global_position = follow_cam.global_position

