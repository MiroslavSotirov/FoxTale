extends Control

var in_big_win : bool = true;
var in_super_win : bool = false;
var in_mega_win : bool = false;
var in_total_win : bool = false;
var transition : bool = false;

var big_win_limit : float = 50;
var super_win_limit : float = 100;
var mega_win_limit : float = 200;

var shown = false;
var tween : Tween;
var amount : float;
var target : float;

var skippable : bool = false;

signal HideEnd;

func _ready():
	Globals.register_singleton("BigWin", self);
	VisualServer.canvas_item_set_z_index(get_canvas_item(), 20);
	yield(Globals, "allready");
	Globals.connect("skip", self, "skip");

func show_win(target, is_total=false):
	if(shown): return;
	
	#Globals.singletons[""]
	if(is_total): Globals.singletons["Audio"].change_music("Total Endless");
	else: Globals.singletons["Audio"].change_music("Big Win Endless");
	shown = true;
	in_big_win = !is_total;
	in_super_win = false;
	in_mega_win = false;
	in_total_win = is_total;
	
	amount = 0;
	self.target = target;
	$CounterText.visible = false;
	$Animation.visible = false;
	$AnimationPlayer.play("Show");
	yield($AnimationPlayer, "animation_finished");
	$Animation.visible = true;
	if(is_total): $Animation.play_anim_then_loop("start_totalwin", "loop_totalwin");
	else: $Animation.play_anim_then_loop("start_bigwin", "loop_bigwin");
	yield($Animation, "animation_complete");
	$CounterText.text = Globals.format_money(0);
	$CounterText.visible = true;
	tween = Tween.new();
	add_child(tween);
	tween.interpolate_method ( self, "set_text", 
		0, self.target, 30, 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start();
	tween.connect("tween_all_completed", self, "hide");
	skippable = true;
	
func skip():
	if(!skippable): return;
	tween.playback_speed = 10;

func set_text(v):
	amount = v;
	$CounterText.text = Globals.format_money(v);
	if(transition): return;
	
	if(in_total_win):
		pass;
	else:
		if(in_big_win):
			if(v > super_win_limit): switch_to_superwin();
		elif(in_super_win):
			if(v > mega_win_limit): switch_to_megawin();

func switch_to_superwin():
	print("switch to superwin");
	Globals.singletons["Audio"].change_music("Super Win Endless");
	transition = true;
	yield($Animation, "animation_complete");
	$Animation.play_anim_then_loop("start_superwin", "loop_superwin");
	yield($Animation, "animation_complete");
	in_big_win = false;
	in_super_win = true;
	transition = false;
	
func switch_to_megawin():
	print("switch to megawin");
	transition = true;
	Globals.singletons["Audio"].change_music("Mega Win Endless");
	yield($Animation, "animation_complete");
	$Animation.play_anim_then_loop("start_megawin", "loop_megawin");
	yield($Animation, "animation_complete");
	in_super_win = false;
	in_mega_win = true;
	transition = false;
	
func hide():
	print("HIDE");
	skippable = false;
	tween.queue_free();
	shown = false;
	yield($Animation, "animation_complete");
	if(transition): yield($Animation, "animation_complete");
	if(in_big_win): $Animation.play_anim("end_bigwin", false);
	elif(in_super_win): $Animation.play_anim("end_superwin", false);
	elif(in_mega_win): $Animation.play_anim("end_megawin", false);
	elif(in_total_win): $Animation.play_anim("end_totalwin", false);
	yield($Animation, "animation_complete");
	$AnimationPlayer.play("Hide");
	yield($AnimationPlayer, "animation_finished");
	if(Globals.in_freespins): Globals.singletons["Audio"].change_music("Free Spins Endless");
	else: Globals.singletons["Audio"].change_music("Kagura Suzu Endless");
	emit_signal("HideEnd");
