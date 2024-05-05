extends Sprite2D

signal updated

var old_position : Vector2
var target_position : Vector2
var old_time : float
var target_time : float

var moving = false

func move_to(target : Vector2, time : float):
	old_position = position
	target_position = target
	old_time = Time.get_ticks_msec()
	target_time = old_time + time*1000
	moving = true

func _process(delta):
	if !moving:
		return
	
	var progress = (Time.get_ticks_msec()-old_time) / (target_time-old_time)
	
	if progress >= 1:
		position = target_position
		moving = false
		updated.emit()
		return
	
	position = lerp(old_position, target_position, progress)
	updated.emit()
