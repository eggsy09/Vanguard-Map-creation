extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var vp := SubViewport.new()
	vp.size=Vector2i(2000,2000)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var town: Node2D = load("res://scenes/Havenreach.tscn").instantiate()
	vp.add_child(town)
	var player := CharacterBody2D.new()
	player.set_script(load("res://scripts/player.gd"))
	town.get_node("Scenery").add_child(player)
	player.position=Vector2(952,1170)
	player.show_frame=false
	player.frozen=true
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("res://docs/havenreach-godot.png")
	var overlay := Node2D.new()
	overlay.set_script(load("res://scripts/collision_overlay.gd"))
	overlay.z_index=100
	vp.add_child(overlay)
	player.show_frame=true
	player.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("res://docs/havenreach-collisions.png")
	overlay.visible=false
	player.show_frame=false
	player.queue_redraw()
	DirAccess.make_dir_recursive_absolute("res://docs/water-frames")
	for i in 16:
		await create_timer(0.125).timeout
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().get_region(Rect2i(1568,0,432,896)).save_png("res://docs/water-frames/%02d.png"%i)
	print("Captured actual Godot map, collision overlay, and animated water frames")
	quit()
