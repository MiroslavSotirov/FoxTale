extends Node

export (Vector2) var zoomamount : Vector2;

func _ready():
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):
	zoom = zoom * lerp(1, 0.3, clamp(inverse_lerp(0.0, 1, screenratio), 0, 1));
	self.rect_scale = Vector2.ONE * lerp(zoomamount.x, zoomamount.y, zoom);
