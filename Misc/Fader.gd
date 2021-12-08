extends Control
var _tween : Tween;

export(Color) var default;

signal done;

func _ready():
	Globals.register_singleton(name, self);

func tween(from, to, time):
	self.visible = true;
	$Tween.remove_all();
	var cfrom = default;
	cfrom.a = from;
	var cto = default;
	cto.a = to;
	modulate = cfrom;
	$Tween.interpolate_property(
		self, "modulate", 
		cfrom, cto, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start();
	
func _tween_completed(obj, key):
	self.visible = self.modulate.a > 0;
	emit_signal("done")
