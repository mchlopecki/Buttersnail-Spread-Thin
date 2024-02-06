extends Area3D

var wind_direction : Vector3 : set = _set_wind_dir
var wind_angle := 0.0 : set = _set_wind_angle
var wind_angle_start = 0.0
var wind_angle_end = 0.0
var wind_angle_tween_weight  = 0.0
@export var wind_magnitude := 0.0 : set = _set_wind_mag
var wind_mag_temp := 0.0
@export var particle_min_speed = 1.0
@export var particle_speed_scale := 0.3
@export var particle_speed_spread := 1.2
@export var wind_trans_length := 3.0

@onready var wind_particles := $WindParticles
@export var box_extents := Vector3(18,0.5,18)
@onready var wind_change_delay := $WindChangeDelay

func _ready():
    change_direction()
    wind_particles.process_material.emission_box_extents = box_extents

func _set_wind_angle(value):
    wind_angle = value
    wind_direction = Vector3.FORWARD.rotated(Vector3.UP, value)


func _set_wind_mag(value : float):
    wind_magnitude = value
    if wind_particles:
        wind_particles.process_material.initial_velocity_min = max(value * particle_speed_scale, particle_min_speed)
        wind_particles.process_material.initial_velocity_max = max(value * particle_speed_spread * particle_speed_scale, particle_min_speed)

func _set_wind_dir(value : Vector3):
    wind_direction = value
    if wind_particles:
        wind_particles.process_material.direction = value

func change_direction():
    wind_mag_temp = wind_magnitude
    wind_angle_tween_weight = 0.0
    wind_angle_start = wind_angle
    wind_angle_end = _new_angle()
    var wind_tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_parallel(true)
    wind_tween.tween_callback(_delay_wind_change).set_delay(wind_trans_length)
    wind_tween.tween_property(self, "wind_magnitude", 0.0, (wind_trans_length - 1.0) / 2.0)
    wind_tween.tween_property(self, "wind_angle_tween_weight", 1.0, wind_trans_length)

    wind_tween.set_parallel(false)
    wind_tween.tween_interval(wind_trans_length - 0.5)
    wind_tween.tween_property(self, "wind_magnitude", wind_mag_temp, 0.5)

func _delay_wind_change():
    wind_change_delay.start(randf_range(5.0,10.0))

func _new_angle():
    return randf_range(0.0,2 * PI)

func _on_wind_change_delay_timeout():
    change_direction()

func _process(delta):
    wind_angle = lerp_angle(wind_angle_start, wind_angle_end, wind_angle_tween_weight)

    var bods = get_overlapping_bodies()
    for bod in bods:
        if bod.is_in_group("player"):
            bod.external_forces.append(wind_direction * wind_magnitude)
