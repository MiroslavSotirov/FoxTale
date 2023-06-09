extends Node
export(Array) var tiles;
export(Array) var tilesBlur;

var assets_to_load = [];
var language_loaded : bool = false;

signal lang_downloaded (lang);

func _ready():
	Globals.register_singleton("AssetLoader", self);

func download_language(lang):
	if(JS.enabled):
		lang = lang.to_upper();

		var path = JS.get_path()+"translations/"+lang+".pck";
		prints(path);
		$HTTPRequest.download_file = "res://"+lang+".pck";
		$HTTPRequest.request(path);
		var res = yield($HTTPRequest, "request_completed");
		#result, response_code, headers, body
		if(res[0] != 0):
			prints("Error downloading language ", res[0], lang, "falling back to EN");
			download_language("EN");
			return;
			
		ProjectSettings.load_resource_pack("res://"+lang+".pck")
		language_loaded = true;
		emit_signal("lang_downloaded", lang);
		prints("LOADED NEW LANGUAGE ", lang);
	else:
		ProjectSettings.load_resource_pack("res://Translations/export/"+lang+".pck")
		language_loaded = true;
		yield(get_tree(), "idle_frame");
		emit_signal("lang_downloaded", lang);
		prints("LOADED NEW LANGUAGE ", lang);
