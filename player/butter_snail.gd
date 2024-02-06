extends RigidBody3D

@export_range(3,50,0.5) var accel = 38
@export_range(3,50,0.5) var deaccel = 8
@export var max_speed = 20
@export var stair_lock_boost = 2.5
var speed = 0
var boost = 1.0

@export var slip_accel_curve : Curve
@export var accel_curve : Curve
@export var slip_friction_curve : Curve
@export var friction_curve : Curve

@export var slip_ang_damp := 0.5
@export var ang_damp := 3.3

@onready var cur_accel_curve = accel_curve
@onready var cur_friction_curve = friction_curve

@export var trail_make_height = 0.5
var sliding_on_butter = false

@export var shear_factor = 0.3
@export var particle_max_speed = 6.0
@export var butter_particle_threshold = 2.0
var butter_blob = preload("res://effects/butter_blob.tscn")

var external_forces = []

enum INPUTS {FORWARD = 1, BACKWARD = 1, FORBACK = 1, LEFT = 2, RIGHT = 2, LEFTRIGHT = 2}
var input_mask = 0
var force_control = false
var force_direction := Vector3(0.0,0.0,0.0)

var obj_butter_overlap = {} # ButterBlob Area3d object : ButterContainer 
var last_cols = {} # contact Object : {contact_count : int, position_sum : Vec3, normal_sum : Vec3}
var butter_idx := 0

@onready var col_shape = $CollisionShape3D
@onready var anim_tree = $Node3D/AnimationTree
@onready var butter_particles = $Node3D/ButterParticles
@onready var second_spring_arm = $Node3D/ShortArm/LongArm
# @onready var lock_rot_timer = $LockRotationTimer
# @export_range(0.1,0.5,0.1) var lock_rot_time = 0.1

var items = []
@onready var item_store_locs = [$Node3D/SnailSprite/Item1, $Node3D/SnailSprite/Item1/Item2, $Node3D/SnailSprite/Item1/Item2/Item3] #, $Node3D/SnailSprite/Item1/Item2/Item3/Item4, $Node3D/SnailSprite/Item1/Item2/Item3/Item4/Item5]
@onready var max_items = item_store_locs.size()

# var report_contacts = false

func _ready():
    pass

# update to area, blob, butter_container
func _on_butter_spill_entered(_area, butter_area, butter_container):
    obj_butter_overlap[butter_area] = butter_container

func _on_butter_spill_exited(_area, butter_area, _butter_container):
    obj_butter_overlap.erase(butter_area)

func _integrate_forces(state):
    boost = 1.0
    for i in state.get_contact_count():
        var col_obj = state.get_contact_collider_object(i)
        var col_pos = state.get_contact_collider_position(i)
        var col_norm = state.get_contact_local_normal(i)
        var col_loc_pos = state.get_contact_local_position(i)
        if abs(col_pos - (position - Vector3(0.0,0.5,0.0))).length() < trail_make_height:
            if col_obj not in last_cols.keys():
                last_cols[col_obj] = {"contact_count": 1, "position_sum": col_pos, "normal_sum": col_norm, "local_pos_sum": col_loc_pos}
            else:
                last_cols[col_obj]["contact_count"] += 1
                last_cols[col_obj]["position_sum"] += col_pos
                last_cols[col_obj]["normal_sum"] += col_norm
                last_cols[col_obj]["local_pos_sum"] += col_loc_pos
        elif abs(angular_velocity.length()) > 0.1:
            linear_velocity.y = min(linear_velocity.y, 0)
        else:
            # we may get stuck on stairs so provide a boost
            boost = stair_lock_boost
            
    check_butter(state)
    
    if sliding_on_butter:
        cur_accel_curve = slip_accel_curve
        cur_friction_curve = slip_friction_curve
        angular_damp = slip_ang_damp
    else:
        cur_accel_curve = accel_curve
        cur_friction_curve = friction_curve
        angular_damp = ang_damp

    if not force_control:
        handle_input(state)
    else:
        state.apply_force(get_accel(-linear_velocity.z, max_speed) * force_direction)

    handle_external_forces(state)
    # clamp_speed(state)
    update_friction(state)
    _update_animation_paratemers()

    last_cols = {}

func _update_animation_paratemers():
    anim_tree["parameters/up_down/blend_position"] = linear_velocity.z / max_speed
    anim_tree["parameters/speed_shear/blend_position"] = linear_velocity.x / max_speed
    if sliding_on_butter and linear_velocity.length() > butter_particle_threshold:
        butter_particles.emitting = true
    else:
        butter_particles.emitting = false
    butter_particles.initial_velocity_max = (linear_velocity.length() / max_speed) * particle_max_speed

func _physics_process(_delta):
    pass
    
func normalize_move_speed(move_speed, move_max):
    return clamp(move_speed / move_max, 0, 1)

func get_accel(move_speed, move_max):
    var deaccel_scalar = 1.0
    if move_speed < 0:
        deaccel_scalar = 0.5
    move_speed = normalize_move_speed(move_speed, move_max)
    return cur_accel_curve.sample(move_speed) * accel * deaccel_scalar * boost

# TODO: change from individual applied forces to combined movement vector applied force
func handle_input(state):
    if Input.is_action_pressed("forward"):
        state.apply_force(get_accel(linear_velocity.z, max_speed) * Vector3.MODEL_FRONT)
    if Input.is_action_pressed("backward"):
        state.apply_force(get_accel(-linear_velocity.z, max_speed) * Vector3.MODEL_REAR)
    if Input.is_action_pressed("left"):
        state.apply_force(get_accel(linear_velocity.x, max_speed) * Vector3.MODEL_LEFT)
        anim_tree["parameters/left_right/blend_position"] = -1.0
        anim_tree["parameters/combine_anims/add_amount"] = 1.0
    if Input.is_action_pressed("right"):
        state.apply_force(get_accel(-linear_velocity.x, max_speed) * Vector3.MODEL_RIGHT)
        anim_tree["parameters/left_right/blend_position"] = 1.0
        anim_tree["parameters/combine_anims/add_amount"] = -1.0

func handle_external_forces(state):
    for force in external_forces:
        state.apply_force(force)
    
    external_forces = []

func clamp_speed(_state):
    var y_plane_vel = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
    speed = y_plane_vel.length()
    if speed > max_speed:
        var norm_speed = y_plane_vel.normalized() * max_speed
        linear_velocity.x = norm_speed.x
        linear_velocity.z = norm_speed.z

func update_friction(_state):
    physics_material_override.friction = cur_friction_curve.sample(speed / max_speed)

func check_butter(_state):
    sliding_on_butter = false
    for collision_obj in last_cols.keys():
        var butter_container = collision_obj.get_node("ButterContainer")
        if butter_container:
            for butter_area in obj_butter_overlap.keys():
                if (butter_area.get_node("..") == butter_container
                    and butter_area.is_in_group("active_butter")):
                        sliding_on_butter = true

            if not (butter_container in obj_butter_overlap.values()):
                create_spill(collision_obj, butter_container)
    
func create_spill(collision, butter_container):
    if butter_container:
        var col_pos = last_cols[collision]["position_sum"] / last_cols[collision]["contact_count"]
        var col_norm = (last_cols[collision]["normal_sum"] / last_cols[collision]["contact_count"]).normalized()
        
        var blob = butter_blob.instantiate()
        if not butter_container.bound:
            butter_container.active_butter.connect("body_entered", _on_butter_spill_entered.bind(butter_container.active_butter, butter_container), CONNECT_DEFERRED)
            butter_container.active_butter.connect("body_exited", _on_butter_spill_exited.bind(butter_container.active_butter, butter_container), CONNECT_DEFERRED)
            butter_container.fresh_butter.connect("body_exited", _on_butter_spill_exited.bind(butter_container.fresh_butter, butter_container), CONNECT_ONE_SHOT & CONNECT_DEFERRED)
            butter_container.bound = true
        obj_butter_overlap[butter_container.fresh_butter] = butter_container
        butter_container.fresh_butter.add_child(blob)
        blob.global_position = col_pos
        var rot_axis = Vector3.UP.cross(col_norm).normalized()
        if rot_axis:
            var rot_angle = Vector3.UP.angle_to(col_norm)
            var eulers = Basis(rot_axis, rot_angle).get_euler()
            blob.set_global_rotation(eulers) 

        butter_container.add_new_blob(blob)

func can_carry(_item):
    return items.size() < max_items

func begin_collect(item):
    item.connect("collision_removed", _collect_item, CONNECT_DEFERRED & CONNECT_ONE_SHOT)

func _collect_item(item):
    var num_items = items.size()
    items.append(item)
    var item_old_loc = item.global_position
    item.reparent(item_store_locs[num_items])
    item.global_position = item_old_loc
    item.begin_animation(item.ITEM_ANIM.COLLECT, [item.position, Vector3.ZERO])

func has_item(item):
    return items.find(item) >= 0

func dropoff_item(item, dropoff):
    var item_idx = items.find(item)
    if item_idx >= 0 and item.state == item.ITEM_STATE.CARRY:
        item.state = item.ITEM_STATE.DROPOFF_ANIM
        _remove_item(item)
        items.map(func (item): item.state = item.ITEM_STATE.CARRY_LOCK)
        var old_item_loc = item.global_position
        item.reparent(dropoff.dropoff_loc)
        item.global_position = old_item_loc
        item.begin_animation(item.ITEM_ANIM.DROPOFF, [item.position, Vector3.ZERO])
        items.map(func (item): item.state = item.ITEM_STATE.CARRY)
        return true

func _remove_item(item):
    var item_idx = items.find(item)
    if item_idx >= 0:
        for i in range(item_idx+1, items.size()):
            var item_old_loc = items[i].global_position
            items[i].reparent(item_store_locs[i-1])
            items[i].global_position = item_old_loc
            items[i].begin_animation(item.ITEM_ANIM.FALL, [item.position, Vector3.ZERO])

        items.remove_at(item_idx)

func item_fall(item):
    item.begin_animation(item.ITEM_ANIM.FALL, [item.position, Vector3.ZERO])
