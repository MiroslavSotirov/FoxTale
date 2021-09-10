extends Node

var singletons = {};

signal allready;
signal resolutionchanged(landscape, portrait, ratio);

func _ready():
	yield(get_tree(),"idle_frame")
	emit_signal("allready");

func register_singleton(name, obj):
	singletons[name] = obj;
