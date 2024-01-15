@tool
extends Node

var viewports_3d

func _on_timeout():
    viewports_3d[0].set_cull_mask_value(2, false)
    viewports_3d[0].set_cull_mask_value(5, false)
        
func _ready():
    # var editor_viewport_container_2d = find_viewport_2d(get_node("/root/EditorNode"), 0)
    
    var spatialeditor_viewport_container = find_SpatialEditorViewportContainer(get_node("/root/EditorNode"), 0)
    viewports_3d = find_viewports_3d(spatialeditor_viewport_container)
    
    # viewports_3d[ <viewport index 0-3> ] = {
    #     "viewport_container": ViewportContainer,
    #     "viewport": Viewport,
    #     "camera": Camera,
    #     "control": Control, 
    # }
    #      Indices:
    # 1 viewport: index 0
    # 2 viewports (both ways): indices 0 and 2
    # 3 viewports: indices 0, 2 and 3
    # 4 viewports: indices 0, 1, 2, 3
    
    # print( viewports_3d[0]["camera"].fov ) # Prints 70 (if you haven't changed)
    print(viewports_3d)

    # var timer := Timer.new()
    # add_child(timer)
    # timer.start(1)
    # timer.timeout.connect(_on_timeout)

func find_viewport_2d(node: Node, recursive_level):
    if node.get_class() == "CanvasItemEditor":
        return node.get_child(1).get_child(0).get_child(0).get_child(0).get_child(0)
    else:
        recursive_level += 1
        if recursive_level > 15:
            return null
        for child in node.get_children():
            var result = find_viewport_2d(child, recursive_level)
            if result != null:
                return result

func find_viewports_3d(spatial_editor_viewport_container) -> Array:
    var result = []
    for spatial_editor_viewport in spatial_editor_viewport_container.get_children():
        var viewport_container = spatial_editor_viewport.get_child(0)
        var control = spatial_editor_viewport.get_child(1)
        var viewport = viewport_container.get_child(0)
        var camera = viewport.get_child(0)
        result.append( {
            "viewport_container": viewport_container,
            "viewport": viewport,
            "camera": camera,
            "control": control,
        } )
    return result

func find_SpatialEditorViewportContainer(node: Node, recursive_level):
    if node.get_class() == "SpatialEditor":
        return node.get_child(1).get_child(0).get_child(0).get_child(0)
    else:
        recursive_level += 1
        if recursive_level > 15:
            return null
        for child in node.get_children():
            var result = find_SpatialEditorViewportContainer(child, recursive_level)
            if result != null:
                return result