extends Node

signal initreceived (data);
signal spinreceived (data);
signal fail(errorcode);

func _ready():
	Globals.register_singleton("Networking", self);
	
func request_init():
	do_request();
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("initreceived", null);
	
func request_spin():
	do_request();
	yield(get_tree().create_timer(1.0), "timeout")
	emit_signal("spinreceived", null);

func do_request():
	pass
