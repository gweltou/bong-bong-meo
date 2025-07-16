extends Area2D
class_name Bubble

signal pop

@onready var angle = randf() * PI * 2.0
var radius : int
var popped := false
var speed := 1.0
var catchable := true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	radius = $AnimatedSprite2D.get_sprite_frames().get_frame_texture("default", 0).get_width()
	radius *= scale.x * 0.5
	$AnimatedSprite2D.frame = randi() % $AnimatedSprite2D.sprite_frames.get_frame_count("default")
	$AnimatedSprite2D.play("default")


func respawn(x: float, y: float) -> void:
	#$CollisionShape2D.disabled = false
	popped = false
	visible = true
	catchable = true
	global_position = Vector2(x, y)
	$AnimatedSprite2D.play("default")


func force_pop(time_offset=0.0) -> void:
	catchable = false
	await get_tree().create_timer(time_offset).timeout
	emit_signal("pop")
	$AnimatedSprite2D.play("explode")


func _process(delta: float) -> void:
	angle += (randf()-0.5) * PI * 0.1
	var vel = randf() * speed
	global_position += Vector2(vel * cos(angle), vel * sin(angle))


func _on_animated_sprite_2d_animation_finished() -> void:
	popped = true
	visible = false


func _on_body_entered(_body: Node2D) -> void:
	if not catchable:
		return
	force_pop(0.0)
