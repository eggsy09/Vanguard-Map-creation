extends Node2D

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	for node in get_tree().get_nodes_in_group("solid_polygons"):
		var pts := PackedVector2Array()
		for p in node.polygon:
			pts.append(to_local(node.to_global(p)))
		draw_colored_polygon(pts,Color(1,.15,.2,.23))
		pts.append(pts[0])
		draw_polyline(pts,Color(1,.2,.23,.85),1.2)
	for layer in get_tree().get_nodes_in_group("river_collision"):
		for cell in layer.get_used_cells():
			var top := to_local(layer.to_global(layer.map_to_local(cell)))-Vector2(8,8)
			draw_rect(Rect2(top,Vector2(16,16)),Color(.95,.1,.15,.2))
	for node in get_tree().get_nodes_in_group("door_shapes"):
		var size: Vector2 = node.shape.size
		var at := to_local(node.global_position)-size/2
		draw_rect(Rect2(at,size),Color(.1,1,.6,.16))
		draw_rect(Rect2(at,size),Color(.1,1,.6,.9),false,1.5)
