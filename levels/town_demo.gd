extends Node3D

var tasks_completed = 0 : set = _set_tasks_completed
var tasks_comp_text : String

var task_scene = preload("res://task.tscn")

var counting_task
@onready var tasklist = $Tasks
@onready var dropoffs = $DropoffAreas
@onready var bakery_block = $BakeryBlock
@onready var bakery_enter = $BakeryEnterZone
@onready var win_screen = $Win_Screen
@onready var credits = $Credits

func _set_tasks_completed(value):
    tasks_completed = value
    tasks_comp_text = "Tasks Completed (%d/10)" % tasks_completed
    if tasks_completed == 10:
        tasks_comp_text = "Enter the bakery at the market..."
        bakery_block.queue_free()
    tasklist.update_toptask(tasks_comp_text)

func _ready():
    counting_task = task_scene.instantiate()
    counting_task.set_questname("Spread too Thin!")
    counting_task.set_hint_text("Tasks Completed (%d/10)" % tasks_completed)
    tasklist.add_toptask(counting_task)
    
    var dropoff_children = dropoffs.get_children()
    for drop in dropoff_children:
        var drop_task = task_scene.instantiate()
        drop_task.set_questname(drop.quest_name)
        drop_task.set_hint_text(drop.quest_hint)
        tasklist.task_container.add_child(drop_task)
        drop.item_recieved.connect(_drop_item_recieved.bind(drop_task))

    bakery_enter.body_entered.connect(_bakery_entered)
        
    await get_tree().create_timer(1.0).timeout
    tasklist.minimized = false

func _drop_item_recieved(_item, drop_task):
    drop_task.queue_free()
    tasks_completed += 1

func _bakery_entered(_body):
    if _body.is_in_group("player"):
        GameManager.change_to_bakery()
    