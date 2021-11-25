extends Control

export (Vector2) var zoomamount : Vector2;
export (Vector2) var yoffset : Vector2;

func _ready():
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):
	zoom = zoom * lerp(1, 0.2, clamp(inverse_lerp(0.0, 1, screenratio), 0, 1));
	rect_scale = Vector2.ONE * lerp(zoomamount.x, zoomamount.y, zoom);
	rect_pivot_offset = rect_size/2;
	zoom = clamp(1.0-zoom, 0.0, 1.0);
	prints(zoom, screenratio)
	set_global_position(lerp(yoffset.x, yoffset.y, zoom) * Vector2.UP)
