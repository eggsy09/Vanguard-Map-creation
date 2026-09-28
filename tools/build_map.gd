extends SceneTree

var world: Node2D
var sorted: Node2D

func _initialize() -> void:
	call_deferred("build")

func owned(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = world

func texture_for(key: String) -> Texture2D:
	var path := "res://assets/lpc/" + key + ".png"
	if not ResourceLoader.exists(path):
		path = "res://assets/derived/" + key + ".png"
	return load(path)

func build() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/havenreach.json"))
	world = Node2D.new()
	world.name = "Havenreach"
	world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.set_meta("world_size", Vector2i(2000, 2000))
	world.set_meta("doorways", d["houses"])
	world.set_meta("entrances", d["entrances"])
	root.add_child(world)
	var z := -100
	for spec in d["layers"]:
		var layer := TileMapLayer.new()
		layer.name = spec["name"]
		layer.z_index = z
		z += 1
		var ts := TileSet.new()
		ts.tile_size = Vector2i(16,16)
		var atlas := TileSetAtlasSource.new()
		atlas.texture = texture_for(spec["texture"])
		atlas.texture_region_size = Vector2i(16,16)
		ts.add_source(atlas,0)
		layer.tile_set = ts
		for cell in spec["cells"]:
			var ac := Vector2i(cell[2],cell[3])
			if not atlas.has_tile(ac):
				atlas.create_tile(ac)
			layer.set_cell(Vector2i(cell[0],cell[1]),0,ac)
		owned(layer,world)
	var water := TileMapLayer.new()
	water.name = "NativeRiverCollision"
	water.visible = false
	var wts := TileSet.new()
	wts.tile_size = Vector2i(16,16)
	wts.add_physics_layer()
	wts.set_physics_layer_collision_layer(0,1)
	wts.set_physics_layer_collision_mask(0,2)
	var wa := TileSetAtlasSource.new()
	var blank := Image.create(16,16,false,Image.FORMAT_RGBA8)
	wa.texture = ImageTexture.create_from_image(blank)
	wa.texture_region_size = Vector2i(16,16)
	wts.add_source(wa,0)
	wa.create_tile(Vector2i.ZERO)
	var td := wa.get_tile_data(Vector2i.ZERO,0)
	td.set_collision_polygons_count(0,1)
	td.set_collision_polygon_points(0,0,PackedVector2Array([Vector2(-8,-8),Vector2(8,-8),Vector2(8,8),Vector2(-8,8)]))
	water.tile_set = wts
	for cell in d["water_cells"]:
		water.set_cell(Vector2i(cell[0],cell[1]),0,Vector2i.ZERO)
	owned(water,world)
	water.add_to_group("river_collision",true)
	sorted = Node2D.new()
	sorted.name = "Scenery"
	sorted.y_sort_enabled = true
	owned(sorted,world)
	for obj in d["sprites"]:
		var holder := Node2D.new()
		holder.name = str(obj["name"]).replace(" ","")
		var at := Vector2(obj["x"],obj["y"])
		var foot := at
		if obj.has("foot"):
			foot = Vector2(obj["foot"][0],obj["foot"][1])
		holder.position = foot
		holder.z_index = int(obj["z"])
		owned(holder,sorted)
		var tex := texture_for(obj["texture"])
		if obj.has("animation"):
			var anim := AnimatedSprite2D.new()
			anim.centered = false
			anim.position = at-foot
			var frames := SpriteFrames.new()
			frames.set_animation_speed("default",obj["animation"]["fps"])
			var r: Array = obj["region"]
			for i in int(obj["animation"]["frames"]):
				var frame := AtlasTexture.new()
				frame.atlas = tex
				frame.region = Rect2(r[0]+i*obj["animation"]["step"],r[1],r[2],r[3])
				frames.add_frame("default",frame)
			anim.sprite_frames = frames
			anim.autoplay = "default"
			anim.frame = int(obj["animation"].get("phase",0))
			owned(anim,holder)
		else:
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.centered = false
			sprite.position = at-foot
			if obj.has("region"):
				var r: Array = obj["region"]
				sprite.region_enabled = true
				sprite.region_rect = Rect2(r[0],r[1],r[2],r[3])
			owned(sprite,holder)
	var solids := Node2D.new()
	solids.name = "NativeCollisionPolygons"
	owned(solids,world)
	for spec in d["solids"]:
		var body := StaticBody2D.new()
		body.name = str(spec["name"]).replace(" ","")
		body.collision_layer = 1
		body.collision_mask = 2
		owned(body,solids)
		var shape := CollisionPolygon2D.new()
		var points := PackedVector2Array()
		for p in spec["points"]:
			points.append(Vector2(p[0],p[1]))
		shape.polygon = points
		owned(shape,body)
		shape.add_to_group("solid_polygons",true)
	for h in d["houses"]:
		var panels := Sprite2D.new()
		panels.name = str(h["id"])+"_OpeningDoorPanels"
		panels.set_script(load("res://scripts/door_panels.gd"))
		panels.threshold = Vector2(h["door"][0],h["door"][1]+20)
		panels.texture = texture_for("arched_doors")
		panels.centered = false
		panels.region_enabled = true
		panels.region_rect = Rect2(0,32,64,64)
		panels.position = panels.threshold-Vector2(32,64)
		panels.z_index = 1
		owned(panels,world)
		var area := Area2D.new()
		area.name = str(h["id"]) + "_Door"
		area.collision_layer = 4
		area.collision_mask = 2
		area.set_meta("house_id",h["id"])
		owned(area,world)
		var box := RectangleShape2D.new()
		box.size = Vector2(h["trigger"][2],h["trigger"][3])
		var cs := CollisionShape2D.new()
		cs.shape = box
		cs.position = Vector2(h["trigger"][0],h["trigger"][1])+box.size/2
		owned(cs,area)
		cs.add_to_group("door_shapes",true)
	var packed := PackedScene.new()
	var result := packed.pack(world)
	if result != OK:
		push_error("Pack failed")
		quit(1)
		return
	var saved := ResourceSaver.save(packed,"res://scenes/Havenreach.tscn")
	print("BAKED NATIVE GODOT SCENE: ",saved,"; houses=",d["houses"].size(),"; colliders=",d["solids"].size())
	quit(saved)
