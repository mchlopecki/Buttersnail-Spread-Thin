extends Node3D

signal collision_removed

@onready var pickup_area = $PickupArea
var collectible := true : set = _set_collectible

enum ITEM_STATE {ITEM, PICKUP_COLLISION, PICKUP_ANIM, CARRY, CARRY_LOCK, DROPOFF_ANIM}
var state := ITEM_STATE.ITEM : set = _set_state

enum ITEM_ANIM {COLLECT, DROPOFF}

func _ready():
    pickup_area.body_entered.connect(body_entered)
    
func _set_collectible(value):
    collectible = value
    pickup_area.set_deferred("monitorable", value)
    pickup_area.set_deferred("monitoring", value)
    if value == false and state == ITEM_STATE.PICKUP_COLLISION:
        set_deferred("state", ITEM_STATE.PICKUP_ANIM)

func _set_state(new_state):
    match new_state:
        ITEM_STATE.PICKUP_COLLISION:
            pass
        ITEM_STATE.PICKUP_ANIM:
            print("emitting")
            collision_removed.emit(self)
    state = new_state

func on_deliver():
    pass

func begin_animation(anim : ITEM_ANIM, anim_args):
    match anim:
        ITEM_ANIM.COLLECT:
            callv("pickup_anim", anim_args)
        ITEM_ANIM.DROPOFF:
            callv("dropoff_anim", anim_args)

func pickup_anim(start, destination):
    var current_position = start
    var vertical_tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC)
    vertical_tween.tween_property(self, "position:y", destination.y + 2, 0.5)
    vertical_tween.tween_property(self, "position:y", destination.y + 0.5, 0.5)
    vertical_tween.tween_property(self, "position:y", destination.y, 0.5).set_trans(Tween.TRANS_BOUNCE)
    var horizontal_tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR).set_parallel(true)
    horizontal_tween.tween_property(self, "position:x", (destination.x + current_position.x) / 2 , 0.5)
    horizontal_tween.tween_property(self, "position:z", (destination.z + current_position.z) / 2 , 0.5)
    horizontal_tween.set_parallel(false)
    horizontal_tween.tween_property(self, "position:x", destination.x, 0.5)
    horizontal_tween.set_parallel(true)
    horizontal_tween.tween_property(self, "position:z", destination.z, 0.5)
    vertical_tween.tween_callback(set_deferred.bind("state", ITEM_STATE.CARRY))

func dropoff_anim(start, destination):
    var current_position = start
    var vertical_tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC)
    vertical_tween.tween_property(self, "position:y", destination.y + 2, 1.0)
    vertical_tween.tween_property(self, "position:y", destination.y + 0.5, 1.5)
    vertical_tween.tween_property(self, "position:y", destination.y, 0.5).set_trans(Tween.TRANS_BOUNCE)
    var horizontal_tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR).set_parallel(true)
    horizontal_tween.tween_property(self, "position:x", (destination.x + current_position.x) / 2 , 1.0)
    horizontal_tween.tween_property(self, "position:z", (destination.z + current_position.z) / 2 , 1.0)
    horizontal_tween.set_parallel(false)
    horizontal_tween.tween_property(self, "position:x", destination.x, 1.0)
    horizontal_tween.set_parallel(true)
    horizontal_tween.tween_property(self, "position:z", destination.z, 1.0)

func body_entered(body):
    if state == ITEM_STATE.ITEM and body.is_in_group("player"):
        if body.can_carry(self):
            state = ITEM_STATE.PICKUP_COLLISION
            body.begin_collect(self)
            remove_collisions()

func remove_collisions():
    collectible = false