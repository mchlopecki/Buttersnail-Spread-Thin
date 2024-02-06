extends Sprite3D

@export var dialogue_influence : Area3D
@export var speech_pos : Marker3D
@export var speech : Array[String]

func _ready():
    if dialogue_influence and speech:
        dialogue_influence.body_entered.connect(start_dialogue)
        dialogue_influence.body_exited.connect(dialogue_interrupt)
        if not speech_pos:
            speech_pos = Marker3D.new()
            speech_pos.global_position = global_position

func start_dialogue(_body):
    DialogueManager.start_dialogue(self, speech_pos.global_position, speech)

func dialogue_interrupt(_body):
    DialogueManager.abrupt_end_dialogue(self)

func change_dialogue():
    pass
