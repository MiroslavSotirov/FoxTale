extends Node

signal spin (data);

var enabled : bool;

func _ready():
	enabled = OS.has_feature('JavaScript');
	JSON.parse("{\"type\":\"spin\",\"data\":\"\"}");
	if(!enabled): return;
	
	JavaScript.eval("""
		window.ElysiumGame = {
			GameOutputEvent : "reserved",
			GameKeepAliveEvent : new Event('elysiumgamekeepalive'),
			GameReadyEvent : new Event('elysiumgameready'),
			GameInputArray : [],
			GameInputProcessedEvent : "reserved"
		}
	""",true);
	JavaScript.eval("""window.dispatchEvent(window.ElysiumGame.GameReadyEvent)""", true);
	
func _process(delta):
	if(!enabled): return;
	JavaScript.eval("""window.dispatchEvent(window.ElysiumGame.GameKeepAliveEvent)""", true);
	
	for i in range(JavaScript.eval("""window.ElysiumGame.GameInputArray.length""", true)):
		_process_js_input();
		

func output(data):
	if(!enabled): return;
	JavaScript.eval("""
		window.ElysiumGame.GameOutputEvent = new CustomEvent('elysiumgameoutput', { data: %s });
		window.dispatchEvent(window.ElysiumGame.GameOutputEvent)
	""" % data, true);
		
func _process_js_input():
	var input = JavaScript.eval("""
		window.ElysiumGame.GameInputArray.shift()
	""", true);
	prints("Received input from JS", input);
	var data = JSON.parse(input);
	if(data.error > 0):
		JavaScript.eval("""
			window.ElysiumGame.GameInputProcessedEvent = new CustomEvent('elysiumgameinputprocessed', { input: %s, success: false });
			window.dispatchEvent(window.ElysiumGame.GameInputProcessedEvent)
		""" % input, true);
		prints("Failed to process JS input!");
	else:
		emit_signal(data.result["type"], data.result["data"]);
		JavaScript.eval("""
			window.ElysiumGame.GameInputProcessedEvent = new CustomEvent('elysiumgameinputprocessed', { input: %s, success: true });
			window.dispatchEvent(window.ElysiumGame.GameInputProcessedEvent)
		""" % input, true);
		prints("Input from JS processed");
