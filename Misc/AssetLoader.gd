extends Node
export(Array) var tiles;
export(Array) var tilesBlur;

var assets_to_load = [];
var language_loaded : bool = false;

signal lang_downloaded (lang);

func _ready():
	Globals.register_singleton("AssetLoader", self);

func dir_contents(path):
	var dir = Directory.new()
	print('looking at: ', path)
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func download_language(lang):
	if(JS.enabled):
		lang = lang.to_upper();

		var path = JS.get_path()+"translations/"+lang+".pck";
		prints(path);
		prints("-----------------------------4---------------------------");
		$HTTPRequest.download_file = "res://"+lang+".pck";
		$HTTPRequest.request(path);
		var res = yield($HTTPRequest, "request_completed");
		#result, response_code, headers, body
		if(res[0] != 0):
			prints("Error downloading language ", res[0], lang, "falling back to EN");
			download_language("EN");
			return;
			
#		ProjectSettings.load_resource_pack("res://"+lang+".pck")
		var wasLoaded = ProjectSettings.load_resource_pack("res://EN.pck")
		print("was loaded: ", wasLoaded);
		language_loaded = true;
		dir_contents('./');
		dir_contents('./tmp');
		dir_contents('./home');
		dir_contents('./proc');
		dir_contents('./userfs');
		dir_contents('./http:');
		
		emit_signal("lang_downloaded", lang);

		prints("LOADED NEW LANGUAGE ", lang);
	else:
		prints("+++++++++++++++++++++++++++++2---------------------------");
		ProjectSettings.load_resource_pack("res://Translations/export/"+lang+".pck")
		language_loaded = true;
		yield(get_tree(), "idle_frame");
		emit_signal("lang_downloaded", lang);
		prints("LOADED NEW LANGUAGE ", lang);
		dir_contents('./');
		
	


