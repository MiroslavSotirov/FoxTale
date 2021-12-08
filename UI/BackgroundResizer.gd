extends Node2D

export(float) var size : float = 3080;
export(float) var min_scale : float = 1;
func _ready():
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	global_position = get_parent().rect_pivot_offset;
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):
	global_position = get_parent().rect_pivot_offset;
	var vr = get_viewport_rect().size;
	var res = max(vr.x, vr.y);
	global_scale = Vector2.ONE * max(res/size, min_scale);
