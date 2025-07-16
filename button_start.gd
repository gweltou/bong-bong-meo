extends Area2D

signal start_game


func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if (event is InputEventMouseButton 
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed):
		$AudioStreamPlayer.play()
		emit_signal("start_game")
