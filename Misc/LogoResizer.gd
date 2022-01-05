extends Node2D

export (Vector2) var scaleoffset : Vector2;
export (Vector2) var yoffset : Vector2;

func _ready():
	Globals.connect("resolutionchanged", self, "on_resolution_changed");
	
func on_resolution_changed(landscape, portrait, screenratio, zoom):
	position.y = lerp(yoffset.x, yoffset.y, clamp(screenratio, 0, 1));
	scale = Vector2.ONE * lerp(scaleoffset.x, scaleoffset.y, clamp(screenratio, 0, 1));
