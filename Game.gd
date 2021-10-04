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
	print("test1");
	yield(Globals.singletons["Fader"], "done")
	print("test2");
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

var testfs = false;

func _input(ev):
	if ev is InputEventKey and ev.scancode == KEY_K and not ev.echo:
		start_fs();

func start_fs():
	if(testfs): return;
	testfs = true;
	$SlotContainer/FreeSpinsIntro.show();	
	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout")
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);	
	yield($SlotContainer/FreeSpinsIntro, "anim_end");
	$SlotContainer/AnimationPlayer.play("normal_to_fs");
	Globals.singletons["FaderBright"].tween(0,0.6,1);
	yield(get_tree().create_timer(1.0), "timeout")
	Globals.singletons["FaderBright"].tween(0.6,0.0,1);
	yield(get_tree().create_timer(0.25), "timeout")
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_color", "idle_gold");
	testfs = false;
	
func end_fs():
	$SlotContainer/AnimationPlayer.play("fs_to_normal");
