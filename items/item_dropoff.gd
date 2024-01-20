extends Area3D

@export var dropoff_loc : Marker3D
@export var item_required : Item

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_item(item_required):
			print(body.items)
			body.dropoff_item(item_required, self)
			DialogueManager.start_dialogue(self, 
				global_position + DialogueManager.BUBBLE_OFFSET, ["delivered!"])
	

