extends Node

var round_closed : bool = false;
var round_ended : bool = true;
var freespins : int = 0;
var in_freespins : bool = false;
var features = [];

signal fox_animation_end;

func _ready():
	JS.connect("spin", self, "try_spin")
	
	Globals.register_singleton("Game", self);
	yield(Globals, "allready")
	Globals.singletons["Fader"].tween(1,1,0);
	Globals.singletons["Networking"].connect("initreceived", self, "init_data_received");
	Globals.singletons["Networking"].request_init();
	yield(Globals.singletons["Networking"], "initreceived");
	round_closed = true; #Init should close previous round if open
	Globals.singletons["Fader"].tween(1,0,0.5);
	update_spins_count(Globals.singletons["Networking"].lastround);
	
func on_play_button_pressed():
	show_slot();
	
func show_slot():
	Globals.singletons["Fader"].tween(0,1,0.5);
	if(freespins > 0): start_fs_instant();
	yield(Globals.singletons["Fader"], "done")
	if(freespins == 0):
		show_logo();

	$IntroContainer.queue_free();
	$SlotContainer.visible = true;
	$UIContainer.visible = true;
	Globals.singletons["Fader"].tween(1,0,0.5);

func _process(delta):
	if($SlotContainer.visible):		
		if(Input.is_action_pressed("spin")): try_spin(false);
		if(Input.is_action_pressed("spinforce")): try_spin(true);
		if(Input.is_action_pressed("skip")): try_skip();
		
func try_spin(isforce = false):
	if(!Globals.canSpin): return;
	if(Globals.singletons["WinLines"].shown):
		Globals.singletons["WinLines"].hide_lines();
		
	if(Globals.singletons["WinBar"].shown):
		Globals.singletons["WinBar"].hide();
	
	if(len(Globals.singletons["ExpandingWilds"].expanded_wilds) > 0):
		foxes_expand_anim_end();
		
	round_closed = false;
	round_ended = false;
	Globals.singletons["Slot"].start_spin();
	yield(Globals.singletons["Slot"], "onstartspin");
	
	if(isforce):
		#var force = funcref(Globals.singletons["Networking"], "force_freespin");
		#Globals.singletons["Networking"].request_force(force, 'filter:"freespin"');
#	to force an InstaWin:
		var force = funcref(Globals.singletons["Networking"], "force_bonus");
		Globals.singletons["Networking"].request_force(force, 'filter:"InstaWin"');
	else:
		Globals.singletons["Networking"].request_spin();
	var data = yield(Globals.singletons["Networking"], "spinreceived");
	update_spins_count(data);
	Globals.singletons["Slot"].stop_spin(data);
		
	#Close it right away if we don't have any wins
	var wins = float(data["spinWin"]);
	if(wins == 0): close_round();
	
	yield(Globals.singletons["Slot"], "onstopped");

	if(Globals.singletons["ExpandingWilds"].has_feature(data)):
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		Globals.singletons["ExpandingWilds"].expand(data);
		yield(Globals.singletons["ExpandingWilds"], "allexpanded");
	
	if(wins > 0):
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		var line_wins = calculate_line_wins(data["wins"]);
		var has_line_wins = line_wins > 0;
		if(has_line_wins):
			Globals.singletons["PopupTiles"].unpop_all();
			Globals.singletons["WinLines"].show_lines(data["wins"]);
			yield(Globals.singletons["WinLines"], "ShowEnd")
			if(line_wins > Globals.singletons["BigWin"].big_win_limit):
				Globals.singletons["BigWin"].show_win(line_wins);
				yield(Globals.singletons["BigWin"], "HideEnd")
			
		if(Globals.singletons["BonusPath"].has_feature(data)):
			start_bonus(data);
			yield(Globals.singletons["BonusPath"], "anim_end")
			Globals.singletons["BigWin"].show_win(Globals.singletons["BonusPath"].get_wins(data));
			
		#if(has_bonus):
		#	pass
		
		Globals.singletons["WinBar"].show_win(wins);

	for feature in features:
		if(feature.has_feature(data)):
			feature.activate(data);
			yield(feature, "activationend");
	
	if(!in_freespins && freespins > 0): 
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		Globals.singletons["WinBar"].hide();
		start_fs();
		yield($SlotContainer/FreeSpinsIntro, "anim_end");
		
	if(in_freespins && freespins == 0):
		end_fs();
	
	if(!round_closed && freespins == 0):
		close_round();
		yield(Globals.singletons["Networking"], "closereceived");
	prints("FS COUNT: ",freespins);
	round_ended = true;
	
func close_round():
	if(freespins > 0): return;
	Globals.singletons["Networking"].request_close();
	yield(Globals.singletons["Networking"], "closereceived");
	round_closed = true;

func update_spins_count(data):
	if(data.has("freeSpinsRemaining")): 
		freespins = data["freeSpinsRemaining"];
		if(freespins == 0):
			$SlotContainer/Slot/FreeSpinsOverlap/Text/CounterText.text = "";
		else:
			$SlotContainer/Slot/FreeSpinsOverlap/Text/CounterText.text = str(freespins);
	else: 
		freespins = 0;
		$SlotContainer/Slot/FreeSpinsOverlap/Text/CounterText.text = "";

func calculate_line_wins(wins):
	if(wins == null): return 0;
	
	var n : float = 0;	
	
	for win in wins: 
		if(win["index"].findn("freespin")>-1): continue;
		if(!win.has("winline")): n+=float(win["win"]); #winline 0
		elif(int(win["winline"]) > -1): n+=float(win["win"]);
			
	return n;	
	
func check_resolution_for_changes():
	pass;

func init_data_received(data):
	pass

func _input(ev):
	if ev is InputEventKey and ev.scancode == KEY_K and not ev.echo:
		if(!Globals.singletons["BonusPath"].shown):
			Globals.singletons["BonusPath"].activate(25);
	
func start_fs_instant():
	Globals.singletons["WinlinesOverlap"].get_node("FreeSpins").visible = true;
	Globals.singletons["WinlinesOverlap"].get_node("Normal").visible = false;
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/AnimationPlayer.play("normal_to_fs");
	$SlotContainer/Slot/FreeSpinsOverlap/Text/CounterText.text = str(freespins);
	in_freespins = true;
	
func start_fs():
	Globals.singletons["WinlinesOverlap"].get_node("FreeSpins").visible = true;
	Globals.singletons["WinlinesOverlap"].get_node("Normal").visible = false;
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
	$SlotContainer/Slot/FreeSpinsOverlap/Text/CounterText.text = str(freespins);
	in_freespins = true;
	
func end_fs():
	Globals.singletons["WinlinesOverlap"].get_node("FreeSpins").visible = false;
	Globals.singletons["WinlinesOverlap"].get_node("Normal").visible = true;
	$SlotContainer/AnimationPlayer.play("fs_to_normal");
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_back", "idle");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_back", "idle");
	in_freespins = false;
	
func start_bonus(data):
	for feature in data["features"]:
		if(feature["data"]["type"] == "bonus"):
			Globals.singletons["BonusPath"].activate(feature["data"]["amount"]);

	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout")
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);
	
func try_skip():
	Globals.emit_signal("skip");
	
func show_logo():
	var logo = $SlotContainer/Slot/NormalOverlap/Logo;
	logo.set_timescale(1);
	logo.play_anim("popup", false);
	yield(logo, "animation_complete");
	logo.set_timescale(0.25);
	logo.play_anim("idle", true);

func foxes_expand_anim_start():
	yield(get_tree(), "idle_frame")
	if(in_freespins): return emit_signal("fox_animation_end");
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_color", "idle_gold");
	yield($SlotContainer/Slot/Overlay/FoxRight, "animation_complete");
	emit_signal("fox_animation_end");
	
func foxes_expand_anim_end():
	yield(get_tree(), "idle_frame")
	if(in_freespins): return emit_signal("fox_animation_end");
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_back", "idle");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_back", "idle");
	yield($SlotContainer/Slot/Overlay/FoxRight, "animation_complete");
	emit_signal("fox_animation_end");
