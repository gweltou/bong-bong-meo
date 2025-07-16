extends CharacterBody2D

signal fly
signal rotation_bonus(angle: float)
signal hold_bonus(time: float)

@export var audio_list: Array[AudioStream]

@onready var prev_cat_pos: Vector2 = $Cat/Tail.global_position
var idle_time = 3.0 # Timer before active
var cat_dpos := 0.0
var active = false # Cat can be sent flying if true
var follow_mouse = false
var flying = false
var eyes_opened := true
var last_angle := 0.0
var last_d_angle := 0.0
var cumul_angle := 0.0
var hold_time := 0.0


func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Eyes blink
	if eyes_opened and randf() < 0.002:
		eyes_opened = false
		$Cat/eyes.visible = false
		await get_tree().create_timer(0.16).timeout
		eyes_opened = true
		$Cat/eyes.visible = true


func _physics_process(delta: float) -> void:
	if follow_mouse:
		global_position = get_global_mouse_position()
	
	if not active:
		return
	
	# Calculate the cat velocity, send the cat flying
	cat_dpos = $Cat/Tail.global_position.distance_squared_to(prev_cat_pos)
	prev_cat_pos = $Cat/Tail.global_position
	if cat_dpos > 2000 and cat_dpos < 10000 and active and not flying:
		# Send the cat flying
		emit_signal("fly")
		$Cat/cat_joint.queue_free()
		$AudioStreamPlayer2D.stream = audio_list[3]
		$AudioStreamPlayer2D.play()
		flying = true
	
	var angle = $Cat/Tail.global_position.angle_to_point(global_position)
	if angle > PI/4 and angle < 3*PI/4:
		hold_time += delta
	else:
		# Reset hold time
		if hold_time > 1.0:
			emit_signal("hold_bonus", hold_time)
		hold_time = 0.0
		
	# Check the number of turns
	var d_angle := 0.0
	if angle > 0 and last_angle < 0:
		var angle_vel_cw = angle - (last_angle + 2*PI)
		var angle_vel_ccw = angle - last_angle
		d_angle = angle_vel_cw if abs(angle_vel_cw) < abs(angle_vel_ccw) else angle_vel_ccw
	elif angle < 0 and last_angle > 0:
		var angle_vel_cw = (angle + 2*PI) - last_angle
		var angle_vel_ccw = angle - last_angle
		d_angle = angle_vel_cw if abs(angle_vel_cw) < abs(angle_vel_ccw) else angle_vel_ccw
	else:
		d_angle = angle - last_angle
	
	if cumul_angle == 0.0 or (sign(cumul_angle) == sign(d_angle)):
		cumul_angle += d_angle
	else:
		# Reset cat rotation counter
		if cumul_angle >= 3 * 2*PI:
			emit_signal("rotation_bonus", cumul_angle)
			$AudioStreamPlayer2D.stream = audio_list[1]
			$AudioStreamPlayer2D.play()
		cumul_angle = 0.0
	last_angle = angle
	last_d_angle = d_angle


func drip():
	$AudioStreamPlayer2D.stream = audio_list[4]
	$AudioStreamPlayer2D.play()
	$Cat/Dripping.emitting = true
	await get_tree().create_timer(3.0).timeout
	$Cat/Dripping.emitting = false
