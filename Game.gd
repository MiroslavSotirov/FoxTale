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
	if(Globals.singletons["WinLines"].shown):
		Globals.singletons["WinLines"].hide_lines();
		
	if(Globals.singletons["WinBar"].shown):
		Globals.singletons["WinBar"].hide();
	
	round_closed = false;
	round_ended = false;
	Globals.singletons["Slot"].start_spin();
	Globals.singletons["Networking"].request_spin();
	var data = yield(Globals.singletons["Networking"], "spinreceived");
	Globals.singletons["Slot"].stop_spin(data);
	
	
	#Close it right away if we don't have any wins
	var wins = float(data["spinWin"]);
	if(wins == 0): close_round();
	
	yield(Globals.singletons["Slot"], "onstopped");
	
	if(wins > 0):
		var line_wins = calculate_line_wins(data["wins"]);
		var has_line_wins = line_wins > 0;
		if(has_line_wins):
			Globals.singletons["WinLines"].show_lines(data["wins"]);
			yield(Globals.singletons["WinLines"], "ShowEnd")
			if(line_wins > Globals.singletons["BigWin"].big_win_limit):
				Globals.singletons["BigWin"].show_wins(line_wins);
				yield(Globals.singletons["BigWin"], "HideEnd")
			
		Globals.singletons["WinBar"].show_wins(wins);
			
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
	
func calculate_line_wins(wins):
	if(wins == null): return 0;
	
	var n : float = 0;	
	
	for win in wins: 
		if(!win.has("winline")): n+=float(win["win"]); #winline 0
		elif(int(win["winline"]) > -1): n+=float(win["win"]);
			
	return n;
	
	
func check_resolution_for_changes():
	pass;

func init_data_received(data):
	pass

var testfs = false;

func _input(ev):
	if ev is InputEventKey and ev.scancode == KEY_K and not ev.echo:
		if(Globals.singletons["BigWin"].shown):
			Globals.singletons["BigWin"].skip();
		else:
			Globals.singletons["BigWin"].show_win(250);
		

func start_fs():
	if(testfs): return;
	testfs = true;
	Globals.singletons["WinLinesOverlap"].get_node("FreeSpins").visible = true;
	Globals.singletons["WinLinesOverlap"].get_node("Normal").visible = false;
	$SlotContainer/FreeSpinsIntro.show();	
	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout");
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);	
	yield($SlotContainer/FreeSpinsIntro, "anim_end");
	$SlotContainer/AnimationPlayer.play("normal_to_fs");
	Globals.singletons["FaderBright"].tween(0,0.6,1);
	yield(get_tree().create_timer(1.0), "timeout");
	Globals.singletons["FaderBright"].tween(0.6,0.0,1);
	yield(get_tree().create_timer(1), "timeout");
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_color", "idle_gold");
	testfs = false;
	
func end_fs():
	Globals.singletons["WinLinesOverlap"].get_node("FreeSpins").visible = false;
	Globals.singletons["WinLinesOverlap"].get_node("Normal").visible = true;
	$SlotContainer/AnimationPlayer.play("fs_to_normal");
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_back", "idle");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_back", "idle");

func start_bonus():
	if(testfs): return;
	testfs = true;
	$SlotContainer/BonusScene.show();	
	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout")
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);	
	testfs = false;
	
