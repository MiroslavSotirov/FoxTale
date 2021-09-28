extends Node

var round_closed : bool = false;
var round_ended : bool = true;
var features = [];

func _ready():
	Globals.register_singleton("Game", self);
	yield(Globals, "allready")
	Globals.singletons["Fader"].tween(1,1,0);
	Globals.singletons["Networking"].connect("initreceived", self, "init_data_received");
	Globals.singletons["Networking"].request_init();
	yield(Globals.singletons["Networking"], "initreceived");
	round_closed = true; #Init should close previous round if open
	Globals.singletons["Fader"].tween(1,0,0.5);
	
func on_play_button_pressed():
	show_slot();
	
func show_slot():
	Globals.singletons["Fader"].tween(0,1,0.5);
	yield(Globals.singletons["Fader"], "done")
	$IntroContainer.queue_free();
	$SlotContainer.visible = true;
	$UIContainer.visible = true;
	Globals.singletons["Fader"].tween(1,0,0.5);

func _process(delta):
	if($SlotContainer.visible):		
		if(Input.is_action_pressed("spin")): try_spin();
			
func try_spin():
	if(!Globals.canSpin): return;
	round_closed = false;
	round_ended = false;
	Globals.singletons["Slot"].start_spin();
	Globals.singletons["Networking"].request_spin();
	var data = yield(Globals.singletons["Networking"], "spinreceived");
	Globals.singletons["Slot"].stop_spin(data);
	
	#Close it right away if we don't have any wins
	if(int(data["spinWin"]) == 0): close_round();
	
	yield(Globals.singletons["Slot"], "onstopped");
	
	for feature in features:
		if(feature.has_feature(data)):
			feature.activate(data);
			yield(feature, "activationend");
	
	if(!round_closed):
		close_round();
		yield(Globals.singletons["Networking"], "closereceived");
		
	round_ended = true;
	
func close_round():
	Globals.singletons["Networking"].request_close();
	yield(Globals.singletons["Networking"], "closereceived");
	round_closed = true;
	
func check_resolution_for_changes():
	pass;

func init_data_received(data):
	pass

