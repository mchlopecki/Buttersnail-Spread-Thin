extends Node

@onready var dialogue_bubble_scene = preload("res://dialogue/dialogue_bubble.tscn")

var dialogue_bubbles = {} # dict of caller (object) : {"object" : obj (sprite) ; "position" : Vector3 ; 
                          #                 "cur_line_idx" : int ; "lines" : Array[String] ;
                          #                 "is_active" : bool ; "can_advance_line" : bool

const BUBBLE_OFFSET = Vector3(0,2,0)
signal dialogue_finished

func start_dialogue(caller, position, lines: Array[String]):
    if caller in dialogue_bubbles.keys():
        return

    if not position or not position is Vector3:
        position = Vector3.ZERO

    var bubble_data = _init_bubble_data(caller, position, lines)
    dialogue_bubbles[caller] = bubble_data

    _show_dialogue_bubble(caller)
    
    dialogue_bubbles[caller]["is_active"] = true
    
func abrupt_end_dialogue(caller):
    if caller in dialogue_bubbles.keys():
        dialogue_bubbles[caller]["object"].queue_free()
        dialogue_bubbles.erase(caller)

func _init_bubble_data(caller, position, lines):
    return {
        "object" : null,
        "position" : position,
        "cur_line_idx" : 0,
        "lines" : lines,
        "is_active" : false,
        "can_advance_line" : false,
        "caller" : caller
    }

func _move_to_center(bubble):
    bubble.global_position.x += (bubble.center_container.size.x / 2.0) * bubble.pixel_size
    bubble.global_position.z += (bubble.center_container.size.y / 2.0) * bubble.pixel_size

func _show_dialogue_bubble(caller):
    dialogue_bubbles[caller]["object"] = dialogue_bubble_scene.instantiate()
    var bubble = dialogue_bubbles[caller]["object"]
    bubble.finished_displaying.connect(_on_dialogue_bubble_finished_displaying.bind(caller))
    bubble.message_timout.connect(_advance_line.bind(caller))
    get_tree().root.add_child(bubble)
    bubble.global_position = dialogue_bubbles[caller]["position"]
    var current_line_idx = dialogue_bubbles[caller]["cur_line_idx"]
    bubble.display_text(dialogue_bubbles[caller]["lines"][current_line_idx])
    await bubble.size_calculated
    _move_to_center(bubble)
    dialogue_bubbles[caller]["can_advance_line"] = false

func _on_dialogue_bubble_finished_displaying(caller):
    dialogue_bubbles[caller]["can_advance_line"] = true
    dialogue_bubbles[caller]["object"].end_timer.start()
    if dialogue_bubbles[caller]["cur_line_idx"] +1 >= dialogue_bubbles[caller]["lines"].size():
        dialogue_finished.emit(caller)

func _unhandled_input(event):
    if (event.is_action_pressed("space")):
        for bubble in dialogue_bubbles.values():
            if (
                bubble["is_active"] &&
                bubble["can_advance_line"]
            ):
                var caller = dialogue_bubbles.find_key(bubble)
                bubble["object"].queue_free()
                
                bubble["cur_line_idx"] += 1
                if bubble["cur_line_idx"] >= bubble["lines"].size():
                    dialogue_bubbles.erase(caller)
                else:
                    _show_dialogue_bubble(caller)


func _advance_line(caller):
    var bubble = dialogue_bubbles[caller]
    
    bubble["cur_line_idx"] += 1
    if bubble["cur_line_idx"] >= bubble["lines"].size():
        # bubble["object"].queue_free()
        # dialogue_bubbles.erase(caller)
        return
        
    bubble["object"].queue_free()
    _show_dialogue_bubble(caller)
