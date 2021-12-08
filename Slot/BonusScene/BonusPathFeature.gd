extends Control

signal _show_mult_end;
signal anim_end;

var current_layer = 1;
var layer_wins = [];
var _lasttori;
var shown = false;
var counter_text;
var left_hovered : bool = false;
var right_hovered : bool = false;
var center_counter_shown : bool = false;
var center_counter_amount : int;

func _ready():
	VisualServer.canvas_item_set_z_index(get_canvas_item(), 20)
	counter_text = $Centering/CounterText;
	Globals.register_singleton("BonusPath", self);
	yield(Globals, "allready")
	pass;
	
func has_feature(data):
	if(!data.has("features")): return false;
	for feature in data["features"]:
		if(feature["type"] == "InstaWin"): return true;
	return false;

func get_wins():
	var data = Globals.singletons["Networking"].lastround;
	if(data == null || !("wins" in data)): return 0;
	for win in data["wins"]:
		if(!win.has("winline")): continue;
		if(int(win["winline"]) == -1): return float(win["win"]);
	return 0; #DEBUG

func activate(totalmultiplier):
	Globals.singletons["Audio"].change_music("Bonus Theme Endless");
	#15 18 21 24 27 30 35 40
	shown = true;
	var steps = 2;
	if(totalmultiplier >= 30):
		steps = 3;
	elif(totalmultiplier >= 20):
		steps = 2;

	layer_wins.clear();
	if(steps == 1):
		layer_wins.append(totalmultiplier);
	elif(steps == 2):
		var firststep = floor(totalmultiplier/3);
		layer_wins.append(firststep);
		var secondstep = totalmultiplier - firststep;
		layer_wins.append(secondstep);
	elif(steps == 3):
		var firststep = floor(totalmultiplier/6);
		layer_wins.append(firststep);
		var secondstep = floor((totalmultiplier/6)*2);
		layer_wins.append(secondstep);
		var thirdstep = totalmultiplier - (firststep+secondstep);
		layer_wins.append(thirdstep);
	
	current_layer = 1;
	center_counter_amount = 0;
	center_counter_shown = false;
	
	$Centering/Layer1/ToriLeft.reset_pose();
	$Centering/Layer1/ToriRight.reset_pose();
	$Centering/Layer2/ToriLeft.reset_pose();
	$Centering/Layer2/ToriRight.reset_pose();
	$Centering/Layer3/ToriLeft.reset_pose();
	$Centering/Layer3/ToriRight.reset_pose();
	$Centering/Layer1/ToriLeft.play_anim($Centering/Layer1/ToriLeft.startanimation, true);
	$Centering/Layer1/ToriRight.play_anim($Centering/Layer1/ToriRight.startanimation, true);
	$Centering/Layer2/ToriLeft.play_anim($Centering/Layer2/ToriLeft.startanimation, false);
	$Centering/Layer2/ToriRight.play_anim($Centering/Layer2/ToriRight.startanimation, false);
	$Centering/Layer3/ToriLeft.play_anim($Centering/Layer3/ToriLeft.startanimation, false);
	$Centering/Layer3/ToriRight.play_anim($Centering/Layer3/ToriRight.startanimation, false);
	$Centering/Layer1/Particles.emitting = true;

	get_node("../AnimationPlayer").play("to_transparent");
	
	$Centering/Text.visible = false;
	$Centering/AnimationPlayer.play("Show");
	yield(get_tree().create_timer(1.0), "timeout")
	Globals.singletons["Audio"].play("Pick A Path")
	$Centering/Text.play_anim_then_loop("popup", "loop");
	$Centering/Text.visible = true;
	yield($Centering/Text, "animation_complete")
	$Centering/Text.play_anim("loop", true);
	$Centering/AnimationPlayer.play("ShowButton");
	$Centering/CustomButton.pressed = false;

func on_play_button_pressed():
	$Centering/AnimationPlayer.play("HideButton");
	Globals.singletons["Audio"].play("Click_Navigate");
	yield($Centering/AnimationPlayer, "animation_finished")
	$LeftButton.visible = true;
	$RightButton.visible = true;
	$LeftButton.enabled = true;
	$RightButton.enabled = true;
	$LeftButton.pressed = false;
	$RightButton.pressed = false;
	if(left_hovered): 
		$Centering/Layer1/ToriLeft.play_anim("float", true);
		$Centering/Layer1/ToriRight.play_anim("Idle", false, 0);
	if(right_hovered): 
		$Centering/Layer1/ToriRight.play_anim("float", true);
		$Centering/Layer1/ToriLeft.play_anim("Idle", false, 0);
		
func right_button_pressed():
	$LeftButton.enabled = false;
	$RightButton.enabled = false;
	_lasttori = $Centering/Layer1/ToriRight;
	if(current_layer == 2): _lasttori = $Centering/Layer2/ToriRight;
	if(current_layer == 3): _lasttori = $Centering/Layer3/ToriRight;
	$Centering/Text.play_anim("close", false);
	var last_layer = len(layer_wins) > current_layer;
	show_multiplier(true, last_layer);
	yield(self, "_show_mult_end");
	if(last_layer): go_to_next_stage();
	else: last_layer_end();
	
func left_button_pressed():
	$LeftButton.enabled = false;
	$RightButton.enabled = false;
	_lasttori = $Centering/Layer1/ToriLeft;
	if(current_layer == 2): _lasttori = $Centering/Layer2/ToriLeft;
	if(current_layer == 3): _lasttori = $Centering/Layer3/ToriLeft;
	$Centering/Text.play_anim("close", false);
	var not_last_layer = len(layer_wins) > current_layer;
	show_multiplier(false, not_last_layer);
	yield(self, "_show_mult_end");
	if(not_last_layer): go_to_next_stage();
	else: last_layer_end();
	
func left_button_hover():
	left_hovered = true;
	if(!$LeftButton.enabled): return;
	if(current_layer == 1): $Centering/Layer1/ToriLeft.play_anim("Hover", true);
	elif(current_layer == 2): $Centering/Layer2/ToriLeft.play_anim("Hover", true);
	elif(current_layer == 3): $Centering/Layer3/ToriLeft.play_anim("Hover", true);
	
func right_button_hover():
	right_hovered = true;
	if(!$RightButton.enabled): return;
	if(current_layer == 1): $Centering/Layer1/ToriRight.play_anim("Hover", true);
	elif(current_layer == 2): $Centering/Layer2/ToriRight.play_anim("Hover", true);
	elif(current_layer == 3): $Centering/Layer3/ToriRight.play_anim("Hover", true);
	
func left_button_unhover():
	left_hovered = false;
	if(!$LeftButton.enabled): return;
	if(current_layer == 1): $Centering/Layer1/ToriLeft.play_anim("Idle", true, 0);
	elif(current_layer == 2): $Centering/Layer2/ToriLeft.play_anim("Idle", true, 0);
	elif(current_layer == 3): $Centering/Layer3/ToriLeft.play_anim("Idle", true, 0);
	
func right_button_unhover():
	right_hovered = false;
	if(!$RightButton.enabled): return;
	if(current_layer == 1): $Centering/Layer1/ToriRight.play_anim("Idle", true, 0);
	elif(current_layer == 2): $Centering/Layer2/ToriRight.play_anim("Idle", true, 0);
	elif(current_layer == 3): $Centering/Layer3/ToriRight.play_anim("Idle", true, 0);
	
func go_to_next_stage():
	if(current_layer == 1):
		$Centering/Layer1/Particles.emitting = false;
		$Centering/Layer2/Particles.emitting = true;
		$Centering/AnimationPlayer.play("ToLayer2");
		$Centering/Layer2/ToriLeft.play_anim($Centering/Layer2/ToriLeft.startanimation, true);
		$Centering/Layer2/ToriRight.play_anim($Centering/Layer2/ToriRight.startanimation, true);
	if(current_layer == 2): 
		$Centering/Layer2/Particles.emitting = false;
		$Centering/Layer3/Particles.emitting = true;
		$Centering/AnimationPlayer.play("ToLayer3");
		$Centering/Layer3/ToriLeft.play_anim($Centering/Layer3/ToriLeft.startanimation, true);
		$Centering/Layer3/ToriRight.play_anim($Centering/Layer3/ToriRight.startanimation, true);
	yield($Centering/AnimationPlayer, "animation_finished")
	if(current_layer == 1):
		if(left_hovered): 
			$Centering/Layer2/ToriLeft.play_anim("Hover", true);
			$Centering/Layer2/ToriRight.play_anim("Idle", false, 0);
		if(right_hovered): 
			$Centering/Layer2/ToriRight.play_anim("Hover", true);
			$Centering/Layer2/ToriLeft.play_anim("Idle", false, 0);
	if(current_layer == 2): 
		if(left_hovered): 
			$Centering/Layer3/ToriLeft.play_anim("Hover", true);
			$Centering/Layer3/ToriRight.play_anim("Idle", false, 0);
		if(right_hovered): 
			$Centering/Layer3/ToriRight.play_anim("Hover", true);
			$Centering/Layer3/ToriLeft.play_anim("Idle", false, 0);
	current_layer += 1;
	
	Globals.singletons["Audio"].play("Pick A Path")
	$Centering/Text.play_anim_then_loop("popup", "loop");
	yield($Centering/Text, "animation_complete")
	$LeftButton.enabled = true;
	$RightButton.enabled = true;
	$LeftButton.pressed = false;
	$RightButton.pressed = false;
	
func show_multiplier(right, not_last_layer):
	yield(VisualServer, "frame_post_draw");
	var parent = _lasttori.get_parent();
	parent.remove_child(_lasttori);
	$Centering.add_child_below_node($Centering/Fade, _lasttori);
	Globals.singletons["Audio"].play("Torii")
	_lasttori.set_timescale(1);
	_lasttori.play_anim_then_loop("popup", "float");

	counter_text.text = "x"+str(layer_wins[current_layer-1]);
	counter_text.get_parent().remove_child(counter_text);	
	if(right):
		$Centering/TextRightPosition.add_child(counter_text)
	else:
		$Centering/TextLeftPosition.add_child(counter_text)
	
	counter_text.rect_pivot_offset = counter_text.rect_size/2;
	counter_text.rect_position = -counter_text.rect_size/2;
	var pos = counter_text.rect_size/2;
	counter_text.get_node("Background").position = pos - Vector2.UP * 100;

	counter_text.get_node("COLLECT").visible = !not_last_layer;
	counter_text.get_node("COLLECT").position.x = pos.x;
	
	counter_text.visible = true;
	
	$Centering/AnimationPlayer.play("ShowWin");
	counter_text.get_node("AnimationPlayer").play("Show");
	yield($Centering/AnimationPlayer, "animation_finished")
	
	if(!center_counter_shown):
		center_counter_shown = true;
		$Centering/CenterCounterText/AnimationPlayer.play("Show");
	var target = center_counter_amount + layer_wins[current_layer-1];
	while(center_counter_amount < target):
		Globals.singletons["Audio"].play("Click_Navigate 2")
		center_counter_amount += 1;
		$Centering/CenterCounterText.text = "x"+str(center_counter_amount);
		yield(get_tree().create_timer(0.1), "timeout")
			
	yield(get_tree().create_timer(1.0), "timeout")
	$Centering/AnimationPlayer.play("HideWin");
	yield($Centering/AnimationPlayer, "animation_finished")
	Globals.singletons["FaderBright"].tween(0.6,0.0,1);
	yield(VisualServer, "frame_post_draw");
	$Centering.remove_child(_lasttori);
	parent.add_child_below_node(parent.get_node("ToriMarker"), _lasttori);
	emit_signal("_show_mult_end");
	
func last_layer_end():
	if(center_counter_shown):
		$Centering/CenterCounterText/AnimationPlayer.play("Hide");
	Globals.singletons["BigWin"].show_win(get_wins());
	yield(Globals.singletons["BigWin"], "HideEnd")
	$Centering/AnimationPlayer.play("Hide");
	get_node("../AnimationPlayer").play("to_visible");
	yield($Centering/AnimationPlayer, "animation_finished");
	Globals.singletons["WinBar"].set_text(float(get_wins()), false);
	emit_signal("anim_end");
	shown = false;
