extends MarginContainer

@onready var quest_label = $VBoxContainer/MarginContainer/Title
@onready var hint_label = $VBoxContainer/MarginContainer2/Hint

func set_questname(value):
    if not is_node_ready():
        await ready
    quest_label.text = value

func set_hint_text(value):
    if not is_node_ready():
        await ready
    hint_label.text = value
