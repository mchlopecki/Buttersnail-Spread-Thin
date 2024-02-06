extends Node3D

@export var baker : Node3D
@export var toast : Node3D
@onready var win_screen = $WinScreen
@onready var player = $ButterSnail

func _ready():
    player.force_control = true

    DialogueManager.start_dialogue(self, baker.position + Vector3(0.0,1.0,0.0), ["Ok buttersnail!", "BUTTER", "THAT", "TOAST!!!"])
    await DialogueManager.dialogue_finished
    player.force_control = false

func _process(delta):
    var but_cont = toast.get_node_or_null("ButterContainer")
    if but_cont:
        print(but_cont.blob_count)
        if but_cont.blob_count > 100:
            toast_covered()

func toast_covered():
    win_screen.show()
