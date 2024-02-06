extends Area3D

@export var dropoff_loc : Marker3D
@export var item_required : Item

@export var quest_name : String
@export var quest_hint : String
var quest_show = false : set = set_quest_vis

signal item_recieved
signal show_quest

func set_quest_vis(value):
	quest_show = value
	if quest_show:
		show_quest.emit(quest_name, quest_hint)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_item(item_required):
			if body.dropoff_item(item_required, self):
				# DialogueManager.start_dialogue(self, 
				# 	global_position + DialogueManager.BUBBLE_OFFSET, ["delivered!"])
				item_recieved.emit(item_required)
	

