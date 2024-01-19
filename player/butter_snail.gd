extends RigidBody3D

@export_range(3,50,0.5) var accel = 30
@export_range(3,50,0.5) var deaccel = 8
@export var max_speed = 8

@export var slip_accel_curve : Curve
@export var accel_curve : Curve
@export var slip_friction_curve : Curve
@export var friction_curve : Curve

@export var slip_ang_damp := 0.5
@export var ang_damp := 3.3

@onready var cur_accel_curve = accel_curve
@onready var cur_friction_curve = friction_curve

var butter_blob = preload("res://effects/butter_blob.tscn")

var sliding_on_butter = false
var speed = 0
@export var trail_make_height = 0.5

enum INPUTS {FORWARD = 1, BACKWARD = 1, FORBACK = 1, LEFT = 2, RIGHT = 2, LEFTRIGHT = 2}
var input_mask = 0

var obj_butter_overlap = {} # ButterBlob Area3d object : ButterContainer 
var last_cols = {} # contact Object : {contact_count : int, position_sum : Vec3, normal_sum : Vec3}
var butter_idx := 0

@onready var col_shape = $CollisionShape3D
@onready var anim_tree = $Node3D/AnimationTree

var items = []
@onready var item_store_locs = [$Node3D/SnailSprite/Item1, $Node3D/SnailSprite/Item1/Item2,$Node3D/SnailSprite/Item1/Item2/Item3,$Node3D/SnailSprite/Item1/Item2/Item3/Item4, $Node3D/SnailSprite/Item1/Item2/Item3/Item4/Item5]
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
			
	check_butter(state)
	
	if sliding_on_butter:
		cur_accel_curve = slip_accel_curve
		cur_friction_curve = slip_friction_curve
		angular_damp = slip_ang_damp
	else:
		cur_accel_curve = accel_curve
		cur_friction_curve = friction_curve
		angular_damp = ang_damp

	handle_input(state)
	clamp_speed(state)
	update_friction(state)
	anim_tree["parameters/up_down/blend_position"] = linear_velocity.z / max_speed

	last_cols = {}

func _physics_process(_delta):
	pass
	
func normalize_move_speed(move_speed, move_max):
	return clamp(move_speed / move_max, 0, 1)

func get_accel(move_speed, move_max):
	var deaccel_scalar = 1.0
	if move_speed < 0:
		deaccel_scalar = 0.5
	move_speed = normalize_move_speed(move_speed, move_max)
	return cur_accel_curve.sample(move_speed) * accel * deaccel_scalar

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
