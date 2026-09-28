extends Sprite2D
## Original LPC door panels open as the test character approaches.
@export var threshold := Vector2.ZERO
var openness := 0.0
func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("test_player") as Node2D
	var target := 0.0
	if player and player.global_position.distance_to(threshold)<145:
		target=3.0
	openness=move_toward(openness,target,delta*10.0)
	region_rect.position.x=roundi(openness)*64
