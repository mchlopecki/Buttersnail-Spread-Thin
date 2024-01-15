extends CharacterBody3D

@export_range(3,20,0.5) var accel = 8
@export_range(3,20,0.5) var deaccel = 8
# @export_range(1,5,0.1) var forward_max_speed = 3.0
# @export_range(1,5,0.1) var backward_max_speed = 3.0
# @export_range(1,5,0.1) var left_max_speed = 3.0
# @export_range(1,5,0.1) var right_max_speed = 3.0
@export var speed = 3
@export var gravity = -10

@export var slip_accel_curve : Curve
@export var slip_deaccel_curve : Curve
@export var accel_curve : Curve
@export var deaccel_curve : Curve

var butter_blob = preload("res://effects/butter_blob.tscn")

var sliding_on_butter = false

enum INPUTS {FORWARD = 1, BACKWARD = 1, FORBACK = 1, LEFT = 2, RIGHT = 2, LEFTRIGHT = 2}
var input_mask = 0

var obj_butter_overlap = {} # ButterBlob Area3d object : ButterContainer 
var last_cols = []
var butter_idx := 0

@onready var col_shape = $CollisionShape3D
@onready var but_model = $ButterModel

@onready var cur_accel_curve = accel_curve
@onready var cur_deaccel_curve = deaccel_curve

func _ready():
    pass

# update to area, blob, butter_container
func _on_butter_spill_entered(_area, butter_area, butter_container):
    obj_butter_overlap[butter_area] = butter_container

func _on_butter_spill_exited(_area, butter_area, _butter_container):
    obj_butter_overlap.erase(butter_area)

func _physics_process(delta):
    move_and_slide()
    deaccelerate(delta)

    last_cols = []
    var num_silde_collisions = get_slide_collision_count()
    for collision_i in num_silde_collisions:
        last_cols.append(get_slide_collision(collision_i))

func _process(delta):
    check_butter()
    
    if sliding_on_butter:
        cur_accel_curve = slip_accel_curve
        cur_deaccel_curve = slip_deaccel_curve
    else:
        cur_accel_curve = accel_curve
        cur_deaccel_curve = deaccel_curve

    handle_input(delta)

func normalize_move_speed(move_speed, move_max):
    return clamp(move_speed / move_max, 0, 1)

func get_accel(move_speed, move_max):
    move_speed = normalize_move_speed(move_speed, move_max)
    return cur_accel_curve.sample(move_speed) * accel

func get_deaccel(move_speed, move_max):
    move_speed = normalize_move_speed(move_speed, move_max)
    return cur_deaccel_curve.sample(move_speed) * deaccel

func deaccelerate(delta):
    if not input_mask && INPUTS.FORBACK:
        velocity.z += -sign(velocity.z) * get_deaccel(abs(velocity.z), speed) * delta
    
    if not input_mask && INPUTS.LEFTRIGHT:
        velocity.x += -sign(velocity.x) * get_deaccel(abs(velocity.x), speed) * delta
    
    input_mask = 0

func handle_input(delta):
    if Input.is_action_pressed("forward"):
        velocity += delta * (get_accel(velocity.z, speed) * Vector3.MODEL_FRONT)
        velocity.z = min(velocity.z, speed)
        input_mask = input_mask || INPUTS.FORWARD
    if Input.is_action_pressed("backward"):
        velocity += delta * (get_accel(-velocity.z, speed) * Vector3.MODEL_REAR)
        velocity.z = max(velocity.z, -speed)
        input_mask = input_mask || INPUTS.BACKWARD
    if Input.is_action_pressed("left"):
        velocity += delta * (get_accel(velocity.x, speed) * Vector3.MODEL_LEFT)
        velocity.x = min(velocity.x, speed)
        input_mask = input_mask || INPUTS.LEFT
    if Input.is_action_pressed("right"):
        velocity += delta * (get_accel(-velocity.x, speed) * Vector3.MODEL_RIGHT)
        velocity.x = max(velocity.x, -speed)
        input_mask = input_mask || INPUTS.RIGHT
        
    velocity.y = gravity

func check_butter():
    sliding_on_butter = false
    for collision in last_cols:
        var collision_obj = collision.get_collider()
        var collision_container = collision_obj.get_node("ButterContainer")
        for butter_area in obj_butter_overlap.keys():
            if (butter_area.get_node("..") == collision_container
                and butter_area.is_in_group("active_butter")):
                    sliding_on_butter = true

        if not (collision_container in obj_butter_overlap.values()):
            create_spill(collision)
    
func create_spill(collision):
    var col_obj = collision.get_collider()
    var butter_container = col_obj.get_node("ButterContainer")
    if butter_container:
        var col_pos = collision.get_position()
        # var col_normal = collision.get_normal()

        var blob = butter_blob.instantiate()
        if not butter_container.bound:
            butter_container.active_butter.connect("body_entered", _on_butter_spill_entered.bind(butter_container.active_butter, butter_container), CONNECT_DEFERRED)
            butter_container.active_butter.connect("body_exited", _on_butter_spill_exited.bind(butter_container.active_butter, butter_container), CONNECT_DEFERRED)
            butter_container.fresh_butter.connect("body_exited", _on_butter_spill_exited.bind(butter_container.fresh_butter, butter_container), CONNECT_ONE_SHOT & CONNECT_DEFERRED)
            butter_container.bound = true
        obj_butter_overlap[butter_container.fresh_butter] = butter_container
        blob.position = col_pos
        butter_container.fresh_butter.add_child(blob)
        
