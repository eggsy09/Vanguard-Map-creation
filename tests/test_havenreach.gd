extends SceneTree
var failures: Array[String] = []
var game: Node2D
var space: PhysicsDirectSpaceState2D
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print("PASS " if ok else "FAIL ",message)
	if not ok: failures.append(message)
func clear_at(foot: Vector2, size: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = size
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0,foot-Vector2(0,size.y/2))
	q.collision_mask = 1
	return space.intersect_shape(q,1).is_empty()
func press_e() -> void:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_E
	e.pressed = true
	game._unhandled_key_input(e)
func run() -> void:
	game = load("res://scenes/Playtest.tscn").instantiate()
	root.add_child(game)
	game.player.frozen = true
	await physics_frame
	await physics_frame
	space = game.get_world_2d().direct_space_state
	check(game.world.get_meta("world_size")==Vector2i(2000,2000),"Exact 2000 x 2000 town")
	check(game.doors.size()==5 and get_nodes_in_group("door_shapes").size()==5,"Five native doorway areas")
	check(game.player.sprite.texture.get_size()/Vector2(8,4)==Vector2(64,64),"Exact 64 x 64 character frames")
	check(clear_at(Vector2(936,1440),Vector2(64,64)),"Spawn clear for full 64 x 64 body")
	var anims: Array[Node] = game.world.find_children("*","AnimatedSprite2D",true,false)
	check(anims.size()==21,"Waterfall and 20 river animations")
	for a in anims:
		check(a.sprite_frames.get_frame_count("default")==4 and a.is_playing(),"Playing four-frame animation "+str(a.get_parent().name))
	for h in game.doors:
		var door := Vector2(h["door"][0],h["door"][1])
		var front := Vector2(h["front"][0],h["front"][1])
		var approach_ok := true
		# Full body reaches the visible threshold, including its whole height.
		for y in range(int(front.y),int(door.y+32)-1,-2):
			if not clear_at(Vector2(door.x,y),Vector2(64,64)):approach_ok=false
		check(approach_ok,"64 x 64 approach clear: "+str(h["name"]))
		game.player.global_position = front
		await create_timer(0.4).timeout
		var panels: Sprite2D = game.world.get_node(str(h["id"])+"_OpeningDoorPanels")
		check(panels.region_rect.position.x==192,"Door panels open: "+str(h["name"]))
		press_e()
		check(game.inside and game.current_house["id"]==h["id"],"Enter correct house: "+str(h["name"]))
		press_e()
		check(not game.inside and game.player.global_position==front,"Return to same door: "+str(h["name"]))
	check(not clear_at(Vector2(1800,700),Vector2(24,16)),"River water blocks movement")
	var bridge_ok := true
	for x in range(1640,1961,8):
		if not clear_at(Vector2(x,1032),Vector2(64,64)):bridge_ok=false
	check(bridge_ok,"Full 64 x 64 character crosses east bridge")
	check(not clear_at(Vector2(418,460),Vector2(24,16)),"House masonry blocks movement")
	# Exercise the actual CharacterBody2D solver, not only shape queries.
	game.player.global_position = Vector2(416,548)
	var hit = game.player.move_and_collide(Vector2(0,-120))
	check(hit!=null and game.player.global_position.y>498,"CharacterBody2D stops at house wall")
	game.player.global_position=Vector2(936,1440)
	check(game.player.set_full_square(true),"Full 64 x 64 collision toggle works")
	# Rasterize real physics into a graph and prove every destination reachable.
	var free: Dictionary = {}
	var size := Vector2(64,64)
	for y in range(64,1985,8):
		for x in range(32,1985,8):
			var p := Vector2i(x,y)
			if clear_at(Vector2(p),size):free[p]=true
	var start := Vector2i(928,1440)
	var queue: Array[Vector2i] = [start]
	var visited := {start:true}
	var cursor := 0
	while cursor<queue.size():
		var at := queue[cursor];cursor+=1
		for offset in [Vector2i(8,0),Vector2i(-8,0),Vector2i(0,8),Vector2i(0,-8)]:
			var n: Vector2i = at+offset
			if free.has(n) and not visited.has(n):
				visited[n]=true;queue.append(n)
	var targets: Array = []
	for h in game.doors:targets.append({"label":h["name"],"point":h["front"]})
	for p in game.world.get_meta("entrances"):targets.append({"label":"Town entrance "+str(p),"point":p})
	for target in targets:
		var p := Vector2(target["point"][0],maxf(64,target["point"][1]))
		var reached := false
		var closest := Vector2(-999,-999)
		for near in visited:
			if Vector2(near).distance_to(p)<closest.distance_to(p):closest=Vector2(near)
			if Vector2(near).distance_to(p)<24:reached=true;break
		if not reached:print("Closest reachable: ",closest," target ",p)
		check(reached,"Full-body route reachable: "+str(target["label"]))
	print("RESULT: ",failures.size()," failures; ",visited.size()," reachable physics samples")
	quit(0 if failures.is_empty() else 1)
