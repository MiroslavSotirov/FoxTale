extends Node
export(Array) var tiles;
export(Array) var tilesBlur;

var assets_to_load = [];

signal all_loaded;

func _ready():
	Globals.register_singleton("AssetLoader", self);
	#download_file("http://18.157.77.77:3000/test/EN.pck");

func download_file(file):
	#$HTTPRequest.download_file = "res://EN.pck";
	#$HTTPRequest.request(file);
	#var res = yield($HTTPRequest, "request_completed");
	#result, response_code, headers, body
	#var test = load("res://Translations/test.tscn")

	#ProjectSettings.load_resource_pack("res://EN.pck")
	#test = load("res://Translations/test.tscn")

	#var test = load("res://test.scn");
	#add_child(test.Instance());
	#print(res[3]); 
	pass;
