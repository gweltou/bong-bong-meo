extends Node2D

@onready var width: int = get_viewport_rect().size.x
@onready var height: int = get_viewport_rect().size.y
var top_boundary: float
var bottom_boundary: float
var bubbles = []

var player_score := 0
var remaining_time := 60.0
var playing := false

var bubble_factory = preload("res://bubble.tscn")
var respawn_bubble := false
var cursor_active := true



func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	$LabelScore.text = str(player_score)
	$LabelStart.text = ""
	$LabelTime.text = str(int(remaining_time))
	
	# Connecting signals
	$ButtonStart.connect("start_game", _on_start_game)
	$Chaviette.connect("fly", _on_cat_flying)
	$Chaviette.connect("rotation_bonus", _on_cat_rotation_bonus)
	$Chaviette.connect("hold_bonus", _on_cat_hold_bonus)
	
	# Spawn menu screen bubbles
	top_boundary = $Camera.position.y - height/2
	for i in range(1000):
		var b: Bubble = bubble_factory.instantiate()
		var s = randf_range(0.04, 0.12)
		b.speed = 0.6
		b.scale = Vector2(s, s)
		b.global_position = Vector2(randi() % width, top_boundary + randi() % height)
		b.connect("pop", _on_bubble_popped)
		bubbles.append(b)
		$bubbles.add_child(b)
	for i in range(32):
		var b: Bubble = bubble_factory.instantiate()
		var s = randf_range(0.1, 0.3)
		b.scale = Vector2(s, s)
		b.global_position = Vector2(randi() % width, top_boundary + randi() % height)
		b.connect("pop", _on_bubble_popped)
		bubbles.append(b)
		$bubbles.add_child(b)
	bottom_boundary = height


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if cursor_active:
		$Cursor.position = get_global_mouse_position()
	
	if playing:
		remaining_time -= delta
		$LabelTime.text = str(int(remaining_time))
		if remaining_time <= 0.0:
			_on_game_timeout()
	
	# Bubble wrapping
	for b: Bubble in bubbles:
		if b.popped and respawn_bubble:
			# Respawn bubble
			var loc = randi_range(0, 2)
			if loc == 0:
				b.respawn(randi_range(0, width-1), bottom_boundary + b.radius)
			elif loc == 1:
				b.respawn(-b.radius, top_boundary + randi_range(0, height-1))
			elif loc == 2:
				b.respawn(width+b.radius, top_boundary + randi_range(0, height-1))
			
		if b.global_position.x < -b.radius:
			b.global_position.x = width + b.radius
		elif b.global_position.x - b.radius > width:
			b.global_position.x = -b.radius
		if b.global_position.y < top_boundary - b.radius:
			b.global_position.y = bottom_boundary + b.radius
		elif  b.global_position.y - b.radius > bottom_boundary:
			b.global_position.y = top_boundary - b.radius


func _on_start_game() -> void:
	# Explode menu screen bubbles
	for b in bubbles:
		b.force_pop(randf()*0.4)
	# Hide mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cursor_active = false
	
	await get_tree().create_timer(1.0).timeout
	for b in bubbles:
		b.queue_free()
	bubbles = []
	
	bottom_boundary = height
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($Camera, "position", Vector2(320, 240), 1)
	
	# Spawn gameplay bubbles
	for i in range(128):
		var b: Bubble = bubble_factory.instantiate()
		var s = randf_range(0.1, 0.2)
		b.scale = Vector2(s, s)
		b.global_position = Vector2(randi() % width, top_boundary + randi() % int(bottom_boundary-top_boundary))
		bubbles.append(b)
		b.connect("pop", _on_bubble_popped)
		$bubbles.add_child(b)
	
	await get_tree().create_timer(1.0).timeout
	top_boundary = 0
	respawn_bubble = true
	$LabelStart.text = "Ready"
	$Chaviette.follow_mouse = true
	await get_tree().create_timer(1.0).timeout
	$LabelStart.text = "Steady"
	await get_tree().create_timer(1.0).timeout
	$LabelStart.text = "Go!"
	playing = true
	await get_tree().create_timer(1.0).timeout
	$Shower.emitting = true
	$Chaviette.active = true
	$LabelStart.visible = false
	

func _on_bubble_popped() -> void:
	$AudioPop.play()
	if playing and $Chaviette.active:
		player_score += 1
		$LabelScore.text = str(player_score)
		
		if randf() < 0.01:
			var sample = randi_range(0, 2)
			$Chaviette/AudioStreamPlayer2D.stream = $Chaviette.audio_list[sample]
			$Chaviette/AudioStreamPlayer2D.play()


func _on_cat_rotation_bonus(rotation: float) -> void:
	if not playing:
		return
	var n_turn = 0
	while rotation > 2*PI:
		rotation -= 2*PI
		n_turn += 1
	var score = n_turn * 4
	player_score += score
	$LabelScore.text = str(player_score)
	var bonus = preload("res://bonus.tscn").instantiate()
	bonus.get_node("Node2D/Label").text = str(score)
	bonus.global_position = $Chaviette.get_node("Cat").global_position
	add_child(bonus)


func _on_cat_hold_bonus(time: float) -> void:
	if not playing:
		return
	var score = round(time * player_score)
	player_score += score
	$LabelScore.text = str(player_score)
	var bonus = preload("res://bonus.tscn").instantiate()
	bonus.get_node("Node2D/Label").text = str(score)
	bonus.global_position = $Chaviette.get_node("Cat").global_position
	add_child(bonus)


func _on_cat_flying() -> void:
	playing = false
	$LabelStart.label_settings.font_size = 72
	$LabelStart.text = "Careful!"
	$LabelStart.visible = true
	$AnimationPlayer.play("fadeout")
	$LabelTime.visible = false
	$LabelScore.visible = false
	await $AnimationPlayer.animation_finished
	get_tree().call_deferred("change_scene_to_file", "res://game_over_fly.tscn")


func _on_game_timeout() -> void:
	playing = false
	$AnimationPlayer.play("fadeout")
	await get_tree().create_timer(0.1).timeout
	$LabelStart.label_settings.font_size = 80
	$LabelStart.text = "Timeout"
	$LabelStart.visible = true
	$LabelTime.visible = false
	await $AnimationPlayer.animation_finished
	get_tree().call_deferred("change_scene_to_file", "res://game_over_timeout.tscn")


func _on_shower_area_body_entered(body: Node2D) -> void:
	if playing:
		$Chaviette.drip()


func _on_drown_area_body_entered(body: Node2D) -> void:
	if playing:
		$AnimationPlayer.play("fadeout")
		await $AnimationPlayer.animation_finished
		get_tree().call_deferred("change_scene_to_file", "res://game_over_drown.tscn")
