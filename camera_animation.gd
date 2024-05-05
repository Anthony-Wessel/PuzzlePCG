extends Camera2D

@export var start_zoom : Vector2
@export var end_zoom : Vector2

var start_time : float
var end_time : float

var moving = false

func zoom_out():
	start_time = Time.get_ticks_msec()
	end_time = Time.get_ticks_msec()+950
	
	moving = true
	
func _process(delta):
	if moving:
		var progress = (Time.get_ticks_msec()-start_time) / (end_time-start_time)
		progress = clamp(progress, 0, 1)
		zoom = lerp(start_zoom, end_zoom, progress)
