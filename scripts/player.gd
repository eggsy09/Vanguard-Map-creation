extends CharacterBody2D

const SPEED := 190.0
var full_square := false
var show_frame := true
var facing := 2
var ticks := 0.0
var sprite: Sprite2D
var collider: CollisionShape2D
var frozen := false

func _ready() -> void:
	add_to_group("test_player")
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	sprite = Sprite2D.new()
	sprite.name = "LPC64x64Sprite"
	sprite.texture = preload("res://assets/derived/sample_walk.png")
	sprite.hframes = 8
	sprite.vframes = 4
	sprite.frame = facing*8
	sprite.position = Vector2(0,-32)
	add_child(sprite)
	collider = CollisionShape2D.new()
	collider.name = "FeetOrFull64Collision"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24,16)
	collider.shape = shape
	collider.position = Vector2(0,-8)
	add_child(collider)

func _physics_process(delta: float) -> void:
	if frozen:
		return
	var v := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if v.length_squared()>0:
		if absf(v.x)>absf(v.y):
			facing = 3 if v.x>0 else 1
		else:
			facing = 2 if v.y>0 else 0
		ticks += delta*10.0
		velocity = v.normalized()*SPEED
	else:
		velocity = Vector2.ZERO
		ticks = 0
	sprite.frame = facing*8 + int(ticks)%8
	move_and_slide()
	queue_redraw()

func set_full_square(value: bool) -> bool:
	var size := Vector2(64,64) if value else Vector2(24,16)
	var offset := Vector2(0,-32) if value else Vector2(0,-8)
	var shape := RectangleShape2D.new()
	shape.size = size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0,global_position+offset)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	if not get_world_2d().direct_space_state.intersect_shape(query).is_empty():
		return false
	full_square = value
	collider.shape = shape
	collider.position = offset
	queue_redraw()
	return true

func _draw() -> void:
	if show_frame:
		draw_rect(Rect2(-32,-64,64,64),Color(1,.85,.25,.9),false,1)
		var size := Vector2(64,64) if full_square else Vector2(24,16)
		draw_rect(Rect2(-size.x/2,-size.y,size.x,size.y),Color(.15,1,.65,.35),true)
		draw_rect(Rect2(-size.x/2,-size.y,size.x,size.y),Color(.15,1,.65,1),false,1)
