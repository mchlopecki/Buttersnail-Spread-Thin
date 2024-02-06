extends Node3D

@export var tut_guy : Node
@export var trash : Item
@export var advance_scene_zone : Area3D
@export var tut_glow : Resource
@export var tut_can_glow : Resource
@export var trash_highlight : Node

@onready var blackout_img = $Blackout
@onready var comic_first = $Comic1
@onready var comic_second = $Comic2

func _ready():
    DialogueManager.connect("dialogue_finished", _check_tut_guy_spoke)
    trash.collectible = false
    advance_scene_zone.body_entered.connect(_advance_game)
    tut_guy.material_overlay = tut_glow
    trash.collision_removed.connect(_trash_picked_up)

func _trash_deposited(item):
    if tut_guy:
        DialogueManager.abrupt_end_dialogue(tut_guy)
        var trash_tween = get_tree().create_tween().bind_node(item).set_trans(Tween.TRANS_CUBIC)
        trash_tween.tween_property(item, "scale", Vector3(0.25,0.25,0.25), 1.0)
        await item.item_deposited
        trash_highlight.material_overlay = null
        trash_highlight.set_surface_override_material(1, null)
        item.queue_free()
        tut_guy.billboard = BaseMaterial3D.BILLBOARD_DISABLED
        var tut_guy_tween = get_tree().create_tween().bind_node(tut_guy).set_parallel(true)
        tut_guy_tween.tween_property(tut_guy, "rotation:y", 360 * 8, 5.0)
        tut_guy_tween.tween_property(tut_guy, "position:y", 8.0, 5.0)
        tut_guy_tween.set_parallel(false)
        DialogueManager.start_dialogue(self, tut_guy.position, ["Good luck on your adventure!!!"])
        tut_guy_tween.tween_callback(_tut_tween_finished)

func _tut_tween_finished():
    if tut_guy:
        DialogueManager.abrupt_end_dialogue(self)
        tut_guy.queue_free()

func _check_tut_guy_spoke(speaker):
    if speaker == tut_guy:
        trash.collectible = true
        tut_guy.material_overlay = null
        trash.material_overlay = tut_glow

func _trash_picked_up(_player):
    tut_guy.dialogue_influence.body_entered.disconnect(tut_guy.start_dialogue)
    trash.material_overlay = null
    trash_highlight.material_overlay = tut_can_glow
    trash_highlight.set_surface_override_material(1, tut_can_glow)

func _advance_game(player):
    player.force_direction = Vector3.MODEL_REAR
    player.force_control = true
    player.second_spring_arm.spring_length = 0.0
    await advance_scene_zone.body_exited
    blackout_img.visible = true
    var blackout_tween = get_tree().create_tween().bind_node(blackout_img).set_trans(Tween.TRANS_CUBIC)
    blackout_tween.tween_property(blackout_img, "modulate", Color(0.0,0.0,0.0,1.0), 2.0)
    await get_tree().create_timer(2.0).timeout
    comic_first.show()
    blackout_img.hide()
    await get_tree().create_timer(6.0).timeout
    comic_first.hide()
    comic_second.show()
    await get_tree().create_timer(6.0).timeout
    GameManager.change_to_town()

