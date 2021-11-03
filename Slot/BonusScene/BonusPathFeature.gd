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
	counter_text = $CounterText;
	Globals.register_singleton("BonusPath", self);
	yield(Globals, "allready")
	pass;
	
func has_feature(data):
	if(!data.has("features")): return false;
	for feature in data["features"]:
		if(feature["type"] == "InstaWin"): return true;
	return false;

func get_wins(data):
	for win in data["wins"]:
		if(!win.has("winline")): continue;
		if(int(win["winline"]) == -1): return float(win["win"]);

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
	
	$Layer1/ToriLeft.reset_pose();
	$Layer1/ToriRight.reset_pose();
	$Layer2/ToriLeft.reset_pose();
	$Layer2/ToriRight.reset_pose();
	$Layer3/ToriLeft.reset_pose();
	$Layer3/ToriRight.reset_pose();
	$Layer1/ToriLeft.play_anim($Layer1/ToriLeft.startanimation, true);
	$Layer1/ToriRight.play_anim($Layer1/ToriRight.startanimation, true);
	$Layer2/ToriLeft.play_anim($Layer2/ToriLeft.startanimation, false);
	$Layer2/ToriRight.play_anim($Layer2/ToriRight.startanimation, false);
	$Layer3/ToriLeft.play_anim($Layer3/ToriLeft.startanimation, false);
	$Layer3/ToriRight.play_anim($Layer3/ToriRight.startanimation, false);
	$Layer1/Particles.emitting = true;

	$Text.visible = false;
	$AnimationPlayer.play("Show");
	yield(get_tree().create_timer(1.0), "timeout")
	Globals.singletons["Audio"].play("Pick A Path")
	$Text.play_anim_then_loop("popup", "loop");
	$Text.visible = true;
	yield($Text, "animation_complete")
	$Text.play_anim("loop", true);
	$AnimationPlayer.play("ShowButton");
	$CustomButton.pressed = false;

func on_play_button_pressed():
	$AnimationPlayer.play("HideButton");
	Globals.singletons["Audio"].play("Click_Navigate");
	yield($AnimationPlayer, "animation_finished")
	$LeftButton.visible = true;
	$RightButton.visible = true;
	$LeftButton.enabled = true;
	$RightButton.enabled = true;
	$LeftButton.pressed = false;
	$RightButton.pressed = false;
	if(left_hovered): 
		$Layer1/ToriLeft.play_anim("float", true);
		$Layer1/ToriRight.play_anim("Idle", false, 0);
	if(right_hovered): 
		$Layer1/ToriRight.play_anim("float", true);
		$Layer1/ToriLeft.play_anim("Idle", false, 0);
		
func right_button_pressed():
	print("RIGHT");
	$LeftButton.enabled = false;
	$RightButton.enabled = false;
	_lasttori = $Layer1/ToriRight;
	if(current_layer == 2): _lasttori = $Layer2/ToriRight;
	if(current_layer == 3): _lasttori = $Layer3/ToriRight;
	$Text.play_anim("close", false);
	var last_layer = len(layer_wins) > current_layer;
	show_multiplier(true, last_layer);
	yield(self, "_show_mult_end");
	if(last_layer): go_to_next_stage();
	else: last_layer_end();
	
func left_button_pressed():
	print("Left");
	$LeftButton.enabled = false;
	$RightButton.enabled = false;
	_lasttori = $Layer1/ToriLeft;
	if(current_layer == 2): _lasttori = $Layer2/ToriLeft;
	if(current_layer == 3): _lasttori = $Layer3/ToriLeft;
	$Text.play_anim("close", false);
	var not_last_layer = len(layer_wins) > current_layer;
	show_multiplier(false, not_last_layer);
	yield(self, "_show_mult_end");
	if(not_last_layer): go_to_next_stage();
	else: last_layer_end();
	
func left_button_hover():
	left_hovered = true;
	if(!$LeftButton.enabled): return;
	if(current_layer == 1): $Layer1/ToriLeft.play_anim("Hover", true);
	elif(current_layer == 2): $Layer2/ToriLeft.play_anim("Hover", true);
	elif(current_layer == 3): $Layer3/ToriLeft.play_anim("Hover", true);
	
func right_button_hover():
	right_hovered = true;
	if(!$RightButton.enabled): return;
	if(current_layer == 1): $Layer1/ToriRight.play_anim("Hover", true);
	elif(current_layer == 2): $Layer2/ToriRight.play_anim("Hover", true);
	elif(current_layer == 3): $Layer3/ToriRight.play_anim("Hover", true);
	
func left_button_unhover():
	left_hovered = false;
	if(!$LeftButton.enabled): return;
	if(current_layer == 1): $Layer1/ToriLeft.play_anim("Idle", true, 0);
	elif(current_layer == 2): $Layer2/ToriLeft.play_anim("Idle", true, 0);
	elif(current_layer == 3): $Layer3/ToriLeft.play_anim("Idle", true, 0);
	
func right_button_unhover():
	right_hovered = false;
	if(!$RightButton.enabled): return;
	if(current_layer == 1): $Layer1/ToriRight.play_anim("Idle", true, 0);
	elif(current_layer == 2): $Layer2/ToriRight.play_anim("Idle", true, 0);
	elif(current_layer == 3): $Layer3/ToriRight.play_anim("Idle", true, 0);
	
func go_to_next_stage():
	if(current_layer == 1):
		$Layer1/Particles.emitting = false;
		$Layer2/Particles.emitting = true;
		$AnimationPlayer.play("ToLayer2");
		$Layer2/ToriLeft.play_anim($Layer2/ToriLeft.startanimation, true);
		$Layer2/ToriRight.play_anim($Layer2/ToriRight.startanimation, true);
	if(current_layer == 2): 
		$Layer2/Particles.emitting = false;
		$Layer3/Particles.emitting = true;
		$AnimationPlayer.play("ToLayer3");
		$Layer3/ToriLeft.play_anim($Layer3/ToriLeft.startanimation, true);
		$Layer3/ToriRight.play_anim($Layer3/ToriRight.startanimation, true);
	yield($AnimationPlayer, "animation_finished")
	if(current_layer == 1):
		if(left_hovered): 
			$Layer2/ToriLeft.play_anim("Hover", true);
			$Layer2/ToriRight.play_anim("Idle", false, 0);
		if(right_hovered): 
			$Layer2/ToriRight.play_anim("Hover", true);
			$Layer2/ToriLeft.play_anim("Idle", false, 0);
	if(current_layer == 2): 
		if(left_hovered): 
			$Layer3/ToriLeft.play_anim("Hover", true);
			$Layer3/ToriRight.play_anim("Idle", false, 0);
		if(right_hovered): 
			$Layer3/ToriRight.play_anim("Hover", true);
			$Layer3/ToriLeft.play_anim("Idle", false, 0);
	current_layer += 1;
	
	Globals.singletons["Audio"].play("Pick A Path")
	$Text.play_anim_then_loop("popup", "loop");
	yield($Text, "animation_complete")
	$LeftButton.enabled = true;
	$RightButton.enabled = true;
	$LeftButton.pressed = false;
	$RightButton.pressed = false;
	
func show_multiplier(right, not_last_layer):
	var parent = _lasttori.get_parent();
	parent.remove_child(_lasttori);
	add_child_below_node($Fade, _lasttori);
	Globals.singletons["Audio"].play("Torii")
	_lasttori.set_timescale(1);
	_lasttori.play_anim_then_loop("popup", "float");

	counter_text.text = "x"+str(layer_wins[current_layer-1]);
	counter_text.get_parent().remove_child(counter_text);	
	if(right):
		$TextRightPosition.add_child(counter_text)
	else:
		$TextLeftPosition.add_child(counter_text)
	
	counter_text.get_node("COLLECT").visible = !not_last_layer;

	counter_text.rect_pivot_offset = counter_text.rect_size/2;
	counter_text.rect_position = -counter_text.rect_size/2;
	counter_text.get_node("Background").position = counter_text.rect_size/2;
	counter_text.get_node("Background").position.y += 100;
	counter_text.visible = true;
	
	$AnimationPlayer.play("ShowWin");
	counter_text.get_node("AnimationPlayer").play("Show");
	yield($AnimationPlayer, "animation_finished")
	
	if(!center_counter_shown):
		center_counter_shown = true;
		$CenterCounterText/AnimationPlayer.play("Show");
	var target = center_counter_amount + layer_wins[current_layer-1];
	while(center_counter_amount < target):
		Globals.singletons["Audio"].play("Click_Navigate 2")
		center_counter_amount += 1;
		$CenterCounterText.text = "x"+str(center_counter_amount);
		yield(get_tree().create_timer(0.1), "timeout")
			
	yield(get_tree().create_timer(1.0), "timeout")
	$AnimationPlayer.play("HideWin");
	yield($AnimationPlayer, "animation_finished")
	Globals.singletons["FaderBright"].tween(0.6,0.0,1);
	remove_child(_lasttori);
	parent.add_child(_lasttori);
	emit_signal("_show_mult_end");
	
func last_layer_end():
	$AnimationPlayer.play("Hide");
	if(center_counter_shown):
		$CenterCounterText/AnimationPlayer.play("Hide");
	yield($AnimationPlayer, "animation_finished")
	emit_signal("anim_end");
	shown = false;

func set_tori_add_visibility(tori, v, timescale):
	tori.set_timescale(timescale, false)
	tori.get_node("torii2").visibility = v;
