extends Node3D

var viewport_initial_size = Vector2()

@onready var viewport = $ButterBoy/Camera3D/SubViewport

func _ready():
	get_viewport().connect("size_changed", _root_viewport_size_changed)
	viewport.size = get_viewport().size
	viewport_initial_size = viewport.size

# Called when the root's viewport size changes (i.e. when the window is resized).
# This is done to handle multiple resolutions without losing quality.
func _root_viewport_size_changed():
	# The viewport is resized depending on the window height.
	# To compensate for the larger resolution, the viewport sprite is scaled down.
	viewport.size = get_viewport().size
	# viewport_sprite.scale = Vector2(1, -1) * viewport_initial_size.y / get_viewport().size.y
