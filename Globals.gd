extends Node

var singletons = {};
var spindata = {};

var tileImages : Array;
var blurTimeImages : Array;

signal allready;
signal resolutionchanged(landscape, portrait, ratio);

func _ready():
	load_tile_images(); #Maybe somewhere else would be better
	yield(get_tree(),"idle_frame")
	emit_signal("allready");

func register_singleton(name, obj):
	singletons[name] = obj;

func load_tile_images():
	var path = "res://Textures/symbols/normal"
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "": break
		elif !file_name.begins_with(".") and !file_name.ends_with(".import"):
			tileImages.append(load(path + "/" + file_name))
	dir.list_dir_end()

	path = "res://Textures/symbols/blur"
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "": break
		elif !file_name.begins_with(".") and !file_name.ends_with(".import"):
			blurTimeImages.append(load(path + "/" + file_name))
	dir.list_dir_end()
