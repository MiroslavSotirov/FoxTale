extends ColorRect
var _tween : Tween;

export(Color) var default;

signal done;

func _ready():
	Globals.register_singleton(name, self);

func tween(from, to, time):
	self.visible = true;
	$Tween.stop_all();
	var cfrom = default;
	cfrom.a = from;
	var cto = default;
	cto.a = to;
	color = cfrom;
	$Tween.interpolate_property(
		self, "color", 
		cfrom, cto, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start();
	
func _tween_completed(obj, key):
	self.visible = self.color.a > 0;
	emit_signal("done")
