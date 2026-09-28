extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const OverlayScript = preload("res://scripts/collision_overlay.gd")
var world: Node2D
var player: CharacterBody2D
var camera: Camera2D
var overlay: Node2D
var status: Label
var overview := false
var inside := false
var current_house: Dictionary = {}
var doors: Array
var room: Node2D
var toast := ""
var toast_until := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world = preload("res://scenes/Havenreach.tscn").instantiate()
	add_child(world)
	doors = world.get_meta("doorways")
	player = CharacterBody2D.new()
	player.name = "SampleCharacter64x64"
	player.set_script(PlayerScript)
	world.get_node("Scenery").add_child(player)
	player.position = Vector2(936,1440)
	camera = Camera2D.new()
	camera.name = "PlaytestCamera"
	add_child(camera)
	camera.position = player.global_position
	overlay = Node2D.new()
	overlay.name = "ActualCollisionOverlay"
	overlay.set_script(OverlayScript)
	overlay.z_index = 100
	overlay.visible = false
	add_child(overlay)
	make_room()
	make_ui()

func make_room() -> void:
	room = Node2D.new()
	room.name = "DoorTestInterior"
	room.position = Vector2(3000,0)
	add_child(room)
	var floor := Polygon2D.new()
	floor.z_index = -20
	floor.color = Color("#635b50")
	floor.polygon = PackedVector2Array([Vector2(0,0),Vector2(640,0),Vector2(640,512),Vector2(0,512)])
	room.add_child(floor)
	var info := Label.new()
	info.text = "HOUSE INTERIOR TEST ROOM\nPress E to return to the same doorway"
	info.position = Vector2(80,60)
	info.add_theme_font_size_override("font_size",19)
	room.add_child(info)
	for box in [Rect2(0,0,640,24),Rect2(0,0,24,512),Rect2(616,0,24,512),Rect2(0,488,640,24)]:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		room.add_child(body)
		var cp := CollisionPolygon2D.new()
		cp.polygon = PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])
		body.add_child(cp)
		cp.add_to_group("solid_polygons")
		var visible_wall := Polygon2D.new()
		visible_wall.polygon = cp.polygon
		visible_wall.color = Color("#292d31")
		room.add_child(visible_wall)

func make_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "Instructions"
	add_child(ui)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,16)
	panel.custom_minimum_size = Vector2(920,112)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.035,.06,.08,.91)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",style)
	ui.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "HAVENREACH  /  GODOT COLLISION PLAYTEST"
	title.add_theme_font_size_override("font_size",20)
	column.add_child(title)
	var controls := Label.new()
	controls.text = "WASD / arrows: move   E: enter / leave house   R: reset\nF1: collisions   F2: sprite outline   F3: 64×64 body test   F4: whole map"
	controls.add_theme_font_size_override("font_size",16)
	column.add_child(controls)
	status = Label.new()
	status.add_theme_font_size_override("font_size",16)
	status.modulate = Color(.55,.95,.76)
	column.add_child(status)

func _process(_delta: float) -> void:
	if overview and not inside:
		camera.position = Vector2(1000,1000)
		var vp := get_viewport_rect().size
		var factor := minf(vp.x/2080.0,vp.y/2080.0)
		camera.zoom = Vector2.ONE*factor
	else:
		camera.zoom = Vector2.ONE
		if inside:
			camera.position = Vector2(3320,256)
		else:
			var half := get_viewport_rect().size/2
			camera.position = Vector2(clampf(player.global_position.x,half.x,2000-half.x),clampf(player.global_position.y-30,half.y,2000-half.y))
	if not inside:
		player.global_position = player.global_position.clamp(Vector2(10,64),Vector2(1990,1990))
	var body := "64×64 full body" if player.full_square else "24×16 feet"
	var near := nearest_door()
	var hint := "" if near.is_empty() else "  |  E: enter " + str(near["name"])
	if inside:hint = "  |  E: return outside " + str(current_house["name"])
	status.text = "Sprite frame: 64×64 px   Collision: " + body + hint
	if Time.get_ticks_msec()/1000.0 < toast_until:
		status.text = toast

func nearest_door() -> Dictionary:
	if inside:return {}
	for h in doors:
		var p := Vector2(h["door"][0],h["door"][1])
		if absf(player.global_position.x-p.x)<40 and player.global_position.y>=p.y and player.global_position.y<p.y+92:
			return h
	return {}

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.physical_keycode:
		KEY_F1:overlay.visible = not overlay.visible
		KEY_F2:player.show_frame = not player.show_frame;player.queue_redraw()
		KEY_F3:
			if not player.set_full_square(not player.full_square):
				toast = "Move into open space before changing the collision size."
				toast_until = Time.get_ticks_msec()/1000.0+3
		KEY_F4:overview = not overview
		KEY_R:
			inside = false
			player.global_position = Vector2(936,1440)
		KEY_E:
			if inside:
				player.global_position = Vector2(current_house["front"][0],current_house["front"][1])
				inside = false
			else:
				var h := nearest_door()
				if not h.is_empty():
					current_house = h
					inside = true
					player.global_position = Vector2(3320,400)
