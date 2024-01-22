extends Sprite3D

@export dialogue_influence : Area3D
@export speech_pos : Marker3D
@export speech : Array[String]

func _ready():
    if dialogue_influence and speech:
        dialogue_influence.body_entered.connect(begin_dialogue)
        dialogue_influence.body_exited.connect(dialogue_interrupt)
        if not speech_pos:
            speech_pos = Marker3D.new()
            speech_pos.global_position = global_position

func begin_dialogue(body):
    DialogueManager.begin_dialogue(self, speech_pos, speech)

func dialogue_interrupt(body):
    DialogueManager.abrupt_end_dialogue(self)

