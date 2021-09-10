extends Node

var _tween : Tween;

signal done;

func _ready():
	Globals.register_singleton(name, self);

func _process(delta):
	pass
	
func tween(from, to, time):
	self.visible = true;
	$Tween.stop_all();
	$Tween.interpolate_property(
		self, "color", 
		Color(0,0,0,from), Color(0,0,0,to), time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start();
	
func _tween_completed():
	self.visible = self.color.a > 0;
	emit_signal("done")
