extends Sprite3D

@onready var sub_viewport = $BubbleViewport
@onready var sub_cam_2d = $BubbleViewport/Camera2D
@onready var center_container = $BubbleViewport/Camera2D/CenterContainer
@onready var bubble_margin = $BubbleViewport/Camera2D/CenterContainer/OuterMargin
@onready var label = $BubbleViewport/Camera2D/CenterContainer/OuterMargin/TextMargin/Label
@onready var letter_timer = $LetterDisplayTimer
@onready var end_timer = $EndTimer

const MAX_WIDTH = 512

var text = ""
var letter_idx = 0

@export var letter_time := 0.03
@export var space_time := 0.06
@export var punctuation_time := 0.2

signal finished_displaying
signal size_calculated
signal message_timout

func _ready():
    sub_viewport.set_update_mode(SubViewport.UPDATE_WHEN_PARENT_VISIBLE)

func display_text(text_to_display: String):
    text = text_to_display
    label.text = text_to_display

    await bubble_margin.resized
    bubble_margin.custom_minimum_size.x = min(bubble_margin.size.x, MAX_WIDTH)
    if bubble_margin.size.x > MAX_WIDTH:  
        label.autowrap_mode = TextServer.AUTOWRAP_WORD
        await bubble_margin.resized
        await bubble_margin.resized # awaits both x and y resize
        bubble_margin.custom_minimum_size.y = bubble_margin.size.y
    size_calculated.emit()

    label.text = ""
    _display_letter()

func _display_letter():
    label.text += text[letter_idx]

    letter_idx += 1
    if letter_idx >= text.length():
        finished_displaying.emit()
        return

    match text[letter_idx]:
        "!",".",",","?":
            letter_timer.start(punctuation_time)
        " ":
            letter_timer.start(space_time)
        _:
            letter_timer.start(letter_time)

func _on_letter_display_timer_timeout():
    _display_letter()


func _on_end_timer_timeout():
    message_timout.emit()	
