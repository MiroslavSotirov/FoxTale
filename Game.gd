extends Node

var round_closed : bool = false;
var round_ended : bool = true;
var freespins : int = 0;
var increase_fs : bool = false;
var in_freespins : bool = false;
var fs_ended : bool = false;
var features = [];

signal ready_to_close_round;
signal fox_animation_end;

func _ready():
	Globals.singletons["Fader"].tween(1,1,0);
	Globals.register_singleton("Game", self);
	yield(Globals, "allready")
	yield(get_tree(),"idle_frame")
	JS.connect("init", Globals.singletons["Networking"], "init_received");
	Globals.singletons["Networking"].connect("initcomplete", self, "init_data_received");
	
func init_data_received():
	round_closed = true; #Init should close previous round if open
	
	Globals.singletons["Networking"].connect("spinreceived", self, "spin_data_received");
	Globals.singletons["Networking"].connect("closereceived", self, "close_round_received");
	Globals.singletons["Networking"].connect("fail", self, "error_received");
	
	JS.connect("spinstart", self, "start_spin");
	JS.connect("spindata", self, "spin_data_received");
	JS.connect("close", self, "close_round_received");	
	JS.connect("skip", self, "try_skip");	
	JS.connect("error", self, "error_received");	
	
	Globals.singletons["Audio"].change_music("Kagura Suzu Endless");
	
	$IntroContainer/Centering/CustomButton.enabled = true;
	Globals.singletons["Fader"].tween(1,0,0.5);
	
func on_play_button_pressed():
	Globals.singletons["Audio"].play("Click_Navigate");
	show_slot();
	
func show_slot():
	Globals.singletons["Fader"].tween(0.0,1.0,1.0);
	yield(Globals.singletons["Fader"], "done")
	
	var lastround = Globals.singletons["Networking"].lastround;
	update_spins_count(lastround);

	if(freespins > 0): 
		prints("FREE SPINS", freespins)
		Globals.singletons["WinBar"].show_win(lastround["cumulativeWin"], true);
		start_fs_instant();
	else:
		Globals.singletons["Audio"].change_music("Kagura Suzu Endless");
		
	if(freespins == 0):
		show_logo();
	
	$IntroContainer.queue_free();
	$SlotContainer.visible = true;
	$UIContainer.visible = true;
		
	Globals.singletons["Fader"].tween(1.0,0.0,0.5);
	yield(Globals.singletons["Fader"], "done");
	JS.output("", "elysiumgameshowui");

func _process(delta):
	if(!JS.enabled && $SlotContainer.visible):		
		if(Input.is_action_pressed("spin")): start_spin(null, false);
		if(Input.is_action_pressed("spinforce")): start_spin(null, true);
		if(Input.is_action_pressed("skip")):
			if(Globals.canSpin): start_spin();
			else: try_skip();

func start_spin(data=null, isforce = false):
	if(!Globals.canSpin): return;

	round_closed = false;
	round_ended = false;
	
	JS.output("", "elysiumgamespinstart");

	Globals.singletons["PopupTiles"].unpop_all();
	
	if(Globals.singletons["WinLines"].shown):
		Globals.singletons["WinLines"].hide_lines();
		
	if(Globals.singletons["WinBar"].shown && !in_freespins):
		Globals.singletons["WinBar"].hide();
	
	if(len(Globals.singletons["ExpandingWilds"].expanded_wilds) > 0):
		foxes_expand_anim_end();
		
	fs_ended = false;
	
	Globals.singletons["Slot"].start_spin();
	
	yield(Globals.singletons["Slot"], "onstartspin");
	
	if(JS.enabled):
		pass
	else:
		if(isforce):
			#var force = funcref(Globals.singletons["Networking"], "force_freespin");
			#Globals.singletons["Networking"].request_force(force, 'filter:"freespin"');
	#	to force an InstaWin:
			var force = funcref(Globals.singletons["Networking"], "force_bonus");
			Globals.singletons["Networking"].request_force(force, 'filter:"InstaWin"');
		else:
			Globals.singletons["Networking"].request_spin();

func spin_data_received(data):
	if("code" in data || "hasError" in data): return;
	if(!Globals.singletons["Slot"].allspinning):
		yield(Globals.singletons["Slot"], "onstartspin");
	if(JS.enabled):
		Globals.singletons["Networking"].lastround = data;
	Globals.singletons["Networking"].update_state(data)
	end_spin(data);
	
func end_spin(data):
	print("End spin");
	update_spins_count(data);
	Globals.singletons["Slot"].stop_spin(data);
		
	#Close it right away if we don't have any wins
	var wins = float(data["spinWin"]);
	if(wins == 0): close_round();
	
	yield(Globals.singletons["Slot"], "onstopped");

	if(Globals.singletons["ExpandingWilds"].has_feature(data)):
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		JS.output("expandingwild", "elysiumgamefeature");
		Globals.singletons["ExpandingWilds"].expand(data);
		yield(Globals.singletons["ExpandingWilds"], "allexpanded");
	
	if(wins > 0):
		var hasPathBonus = Globals.singletons["BonusPath"].has_feature(data);
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");

		var line_wins = calculate_line_wins(data["wins"]);
		var has_line_wins = line_wins > 0;

		if(has_line_wins):
			JS.output("linewin", "elysiumgamefeature");
			Globals.singletons["PopupTiles"].unpop_all();
			Globals.singletons["WinLines"].show_lines(data["wins"]);
			yield(Globals.singletons["WinLines"], "ShowEnd")
			if(line_wins > Globals.singletons["BigWin"].big_win_limit):
				JS.output("bigwin", "elysiumgamefeature");
				Globals.singletons["BigWin"].show_win(line_wins);
				yield(Globals.singletons["BigWin"], "HideEnd")
				Globals.singletons["WinBar"].set_text(float(line_wins), false);
			elif(in_freespins):
				Globals.singletons["FsWinbar"].show_win(wins, false);
				yield(Globals.singletons["FsWinbar"], "CountEnd")
				if(!Globals.singletons["WinBar"].shown):
					Globals.singletons["WinBar"].set_text(float(line_wins));
				Globals.singletons["FsWinbar"].hide(true);
				
		if(hasPathBonus):
			if(has_line_wins): 
				yield(get_tree().create_timer(0.5), "timeout");
				Globals.singletons["WinLines"].hide_lines();
			JS.output("pathbonus", "elysiumgamefeature");
			start_bonus(data);
			yield(Globals.singletons["BonusPath"], "anim_end")
	
		if(in_freespins):
			Globals.singletons["WinBar"].show_win(data["cumulativeWin"], true);
		else:
			Globals.singletons["WinBar"].show_win(wins, false);

	for feature in features:
		if(feature.has_feature(data)):
			feature.activate(data);
			yield(feature, "activationend");
			
	if(increase_fs):
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		increase_fs = false;
		JS.output("freespinsinfreespins", "elysiumgamefeature");
		increase_fs();
		yield($SlotContainer/FreeSpinsIntro, "anim_end");
		$SlotContainer/Slot/FreeSpinsOverlap/Text/CounterText.text = str(freespins);
	
	if(!in_freespins && freespins > 0): 
		if(Globals.singletons["PopupTiles"].remaining_tile_count > 0): 
			yield(Globals.singletons["PopupTiles"], "popuptilesend");
		Globals.singletons["WinBar"].hide();
		JS.output("freespins", "elysiumgamefeature");
		start_fs();
		yield($SlotContainer/FreeSpinsIntro, "anim_end");
		$SlotContainer/Slot/FreeSpinsOverlap/Text/CounterText.text = str(freespins);
		
	if(in_freespins && freespins == 0):
		end_fs();
		if("cumulativeWin" in data && float(data["cumulativeWin"]) > 0.0):
			Globals.singletons["BigWin"].show_win(data["cumulativeWin"], true);
			Globals.singletons["WinBar"].hide();
			yield(Globals.singletons["BigWin"], "HideEnd")
			Globals.singletons["WinBar"].show_win(data["cumulativeWin"], true);
		
	if(!round_closed && freespins == 0):
		close_round();
		yield(self, "ready_to_close_round");
		
	prints("FS COUNT: ",freespins);
	round_ended = true;
	
	JS.output("", "elysiumgameroundend");
	
func close_round(_data=null):
	if(freespins > 0): return;
	if(JS.enabled): JS.output("", "elysiumgameclose");
	else: Globals.singletons["Networking"].request_close();
	
func close_round_received(_data=null):
	round_closed = true;
	emit_signal("ready_to_close_round");

func update_spins_count(data):
	if(data.has("freeSpinsRemaining")):
		increase_fs = in_freespins && data["freeSpinsRemaining"] > freespins
		freespins = int(data["freeSpinsRemaining"]);

		if(freespins == 0):
			$SlotContainer/Slot/FreeSpinsOverlap/Text/CounterText.text = "";
		elif(!increase_fs):
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

#func _input(ev):
#	if ev is InputEventKey and ev.scancode == KEY_F and not ev.echo:
#		if(!in_freespins): 
#			start_fs();
#
#	if ev is InputEventKey and ev.scancode == KEY_K and not ev.echo:
#		#increase_fs();
#		if(!Globals.singletons["BonusPath"].shown):
#			Globals.singletons["BonusPath"].activate(50);
	
func start_fs_instant():
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/AnimationPlayer.play("normal_to_fs");
	
	in_freespins = true;
	
func start_fs():
	in_freespins = true;
	Globals.singletons["WinLines"].hide_lines();
	$SlotContainer/FreeSpinsIntro.show();
	$SlotContainer/AnimationPlayer.play("to_transparent");
	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout");
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);	
	yield($SlotContainer/FreeSpinsIntro, "anim_end");
	$SlotContainer/AnimationPlayer.play("normal_to_fs");
	Globals.singletons["FaderBright"].tween(0,0.6,1);
	yield(get_tree().create_timer(1.0), "timeout");
	Globals.singletons["FaderBright"].tween(0.6,0.0,1);
	yield(get_tree().create_timer(1), "timeout");
	Globals.singletons["Audio"].play("Magic Fox")
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_color", "idle_gold");
	
func increase_fs():
	$SlotContainer/FreeSpinsIntro.show_fast();	
	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout");
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);	
	yield($SlotContainer/FreeSpinsIntro, "anim_end");
	
func end_fs():
	if(len(Globals.singletons["ExpandingWilds"].expanded_wilds) == 0):
		$SlotContainer/AnimationPlayer.play("fs_to_normal");
		$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_back", "idle");
		$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_back", "idle");
	else:
		$SlotContainer/AnimationPlayer.play("fs_to_fox");

	fs_ended = true;
	in_freespins = false;
	Globals.singletons["Audio"].change_music("Kagura Suzu Endless");
	
func start_bonus(data):
	for feature in data["features"]:
		if(feature["type"] == "InstaWin"):
			Globals.singletons["BonusPath"].activate(feature["data"]["amount"]);

	Globals.singletons["FaderBright"].tween(0.0,1.0,1);
	yield(get_tree().create_timer(1), "timeout")
	Globals.singletons["FaderBright"].tween(1.0,0.0,1);
	
func try_skip(data=null):
	Globals.emit_signal("skip");
	
func error_received(data):
	if(Globals.singletons["Slot"].spinning):
		if(!Globals.singletons["Slot"].allspinning):
			yield(Globals.singletons["Slot"], "onstartspin");
		Globals.singletons["Slot"].stop_spin();
		yield(Globals.singletons["Slot"], "onstopped");
	yield(get_tree(), "idle_frame");
	round_closed = true;
	round_ended = true;
	JS.output("", "elysiumgameroundend");
		
func show_logo():
	var logo = $SlotContainer/Slot/NormalOverlap/Logo;
	logo.set_timescale(1);
	Globals.singletons["Audio"].play("Fox Tale")
	logo.play_anim("popup", false);
	yield(logo, "animation_complete");
	logo.set_timescale(0.25);
	logo.play_anim("idle", true);

func foxes_expand_anim_start():
	yield(get_tree(), "idle_frame");
	if(in_freespins): return emit_signal("fox_animation_end");
	$SlotContainer/AnimationPlayer.play("normal_to_fs_fox");
	Globals.singletons["Audio"].play("Magic Fox")
	$SlotContainer/Slot/Overlay/FoxLeft.set_timescale(2,false);
	$SlotContainer/Slot/Overlay/FoxRight.set_timescale(2,false);
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_color", "idle_gold");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_color", "idle_gold");
	yield(get_tree().create_timer(0.5), "timeout");
	emit_signal("fox_animation_end");
	
func foxes_expand_anim_end():
	yield(get_tree(), "idle_frame")	
	if(in_freespins): return emit_signal("fox_animation_end");
	$SlotContainer/AnimationPlayer.play("fs_to_normal_fox");
	Globals.singletons["Audio"].play("Magic Fox")
	$SlotContainer/Slot/Overlay/FoxLeft.play_anim_then_loop("convert_back", "idle");
	$SlotContainer/Slot/Overlay/FoxRight.play_anim_then_loop("convert_back", "idle");
	yield($SlotContainer/Slot/Overlay/FoxRight, "animation_complete");
	emit_signal("fox_animation_end");
