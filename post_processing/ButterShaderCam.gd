extends Camera3D

@onready var follow_cam = $"../.."
@onready var butt_boy = $"../../.."

func _process(_delta):
    position = follow_cam.position + butt_boy.position

