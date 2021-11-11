extends Node

signal init (data);
signal spinstart (data);
signal spindata (data);
signal close (data);
signal set_stake (stake);

var enabled : bool;

func _ready():
	enabled = OS.has_feature('JavaScript');
	if(!enabled): return;
	
	Globals.connect("configure_bets", self, "output_bets");
	
	JavaScript.eval("""
		if(window.Elysium == null) window.Elysium = {};
		window.Elysium.Game = {
			OutputEvent : "reserved",
			KeepAliveEvent : new Event('elysiumgamekeepalive'),
			ReadyEvent : new Event('elysiumgameready'),
			InputArray : [],
			InputProcessedEvent : "reserved"
		}
	""",true);
	
	var paramsstring = JavaScript.eval("""JSON.stringify(Array.from((new URLSearchParams(window.location.search)).entries()))""", true);
	var params = JSON.parse(paramsstring).result;
	prints("Parameters:",params);
	process_params(params);
	
	JavaScript.eval("""window.dispatchEvent(window.Elysium.Game.ReadyEvent)""", true);
	
func _process(delta):
	if(!enabled): return;
	JavaScript.eval("""window.dispatchEvent(window.Elysium.Game.KeepAliveEvent)""", true);
	
	for i in range(JavaScript.eval("""window.Elysium.Game.InputArray.length""", true)):
		_process_js_input();
		
func process_params(params):
	yield(Globals,"allready");
	for param in params:
		if(param[0] == "token"):
			Globals.singletons["Networking"].set_token(param[1]);
		elif(param[0]=="language"):
			Globals.set_language(param[1]);
		elif(param[0]=="mode"):
			Globals.singletons["Networking"].set_mode(param[1]);
		elif(param[0]=="wallet"):
			Globals.singletons["Networking"].set_wallet(param[1]);
		elif(param[0]=="currency"):
			Globals.set_currency(param[1]);
		elif(param[0]=="operator"):
			Globals.singletons["Networking"].set_operator(param[1]);
		elif(param[0]=="debug"):
			Globals.set_debug(param[1]);
		elif(param[0]=="jurisdiction"):
			Globals.set_jurisdiction(param[1]);
		
func output(data, event="elysiumgameoutput"):
		if(!enabled): return;
		prints(data, event);
		JavaScript.eval("""
			window.Elysium.Game.OutputEvent = new CustomEvent("%s", { data: `%s` });
			window.dispatchEvent(window.Elysium.Game.OutputEvent)
		""" % [event, data], true);
		
func _process_js_input():
	var input = JavaScript.eval("""
		window.Elysium.Game.InputArray.shift()
	""", true);
	prints("Received input from JS", input);
	var data = JSON.parse(input);
	if(data.error > 0):
		JavaScript.eval("""
			window.Elysium.Game.InputProcessedEvent = new CustomEvent('elysiumgameinputprocessed', { input: '%s', success: false });
			window.dispatchEvent(window.Elysium.Game.InputProcessedEvent)
		""" % input, true);
		prints("Failed to process JS input!");
	else:
		prints(data.result["type"], data.result["data"]);
		emit_signal(data.result["type"], data.result["data"]);
		JavaScript.eval("""
			window.Elysium.Game.InputProcessedEvent = new CustomEvent('elysiumgameinputprocessed', { input: '%s', success: true });
			window.dispatchEvent(window.Elysium.Game.InputProcessedEvent)
		""" % input, true);
		prints("Input from JS processed");
		
func play_sound(sfx):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.play("%s");
	""" % sfx, true);
	
func stop_sound(sfx):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.stop("%s");
	""" % sfx, true);

func loop_sound(sfx):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.loop("%s");
	""" % sfx, true);
	
func pause_sound(sfx):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.pause("%s");
	""" % sfx, true);

func fade_sound(sfx, from, to, duration):
	if(!enabled): return;
	JavaScript.eval("""
		window.Elysium.SoundEngine.fade("%s", %s, %s, %s);
	""" % [sfx, from, to, duration], true);
	
func output_bets(bets, defaultbet, multiplier):
	output(
		JSON.print({"bets":bets, "defaultbet":defaultbet, "multiplier":multiplier}), 
		"elysiumgamestakes"
	);

func get_path():
	if(!enabled): return null;
	var path = JavaScript.eval("""
		window.location.origin+window.location.pathname;
	""", true);
	if(path.ends_with(".html")):
		path = path.replace(path.split("/", false)[-1], "");
	return path;
