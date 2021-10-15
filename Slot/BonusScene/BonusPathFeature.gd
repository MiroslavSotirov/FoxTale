extends Control

signal _show_mult_end;
signal anim_end;

var current_layer = 1;
var layer_wins = [];
var _lasttori;
var shown = false;
var counter_text;

func _ready():
	counter_text = $CounterText;
	Globals.register_singleton("BonusPath", self);
	yield(Globals, "allready")
	pass;
	
func has_feature(data):
	if(!data.has("features")): return false;
	for feature in data["features"]:
		if(feature["type"] == "bonus"): return true;
	return false;

func get_wins(data):
	for win in data["wins"]:
		if(!win.has("winline")): continue;
		if(int(win["winline"]) == -1): return win["win"];

func activate(totalmultiplier):
	#15 18 21 24 27 30 35 40
	shown = true;
	var steps = 1;
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
	
	$Text.visible = false;
	$AnimationPlayer.play("Show");
	yield(get_tree().create_timer(1.0), "timeout")
	$Text.play_anim_then_loop("popup", "loop");
	$Text.visible = true;
	yield($Text, "animation_complete")
	$Text.play_anim("loop", true);
	$AnimationPlayer.play("ShowButton");
	$CustomButton.pressed = false

func on_play_button_pressed():
	$AnimationPlayer.play("HideButton");
	yield($AnimationPlayer, "animation_finished")
	$LeftButton.visible = true;
	$RightButton.visible = true;
	$LeftButton.enabled = true;
	$RightButton.enabled = true;
	$LeftButton.pressed = false;
	$RightButton.pressed = false;

func right_button_pressed():
	print("RIGHT");
	$LeftButton.enabled = false;
	$RightButton.enabled = false;
	_lasttori = $Layer1/ToriRight;
	if(current_layer == 2): _lasttori = $Layer2/ToriRight;
	if(current_layer == 3): _lasttori = $Layer3/ToriRight;
	$Text.play_anim("close", false);
	show_multiplier(true);
	yield(self, "_show_mult_end");
	prints(len(layer_wins), current_layer);
	if(len(layer_wins) > current_layer): go_to_next_stage();
	else: last_layer_end();
	
func left_button_pressed():
	print("Left");
	$LeftButton.enabled = false;
	$RightButton.enabled = false;
	_lasttori = $Layer1/ToriLeft;
	if(current_layer == 2): _lasttori = $Layer2/ToriLeft;
	if(current_layer == 3): _lasttori = $Layer3/ToriLeft;
	$Text.play_anim("close", false);
	show_multiplier(false);
	yield(self, "_show_mult_end");
	prints(len(layer_wins), current_layer);
	if(len(layer_wins) > current_layer): go_to_next_stage();
	else: last_layer_end();
	
func go_to_next_stage():
	if(current_layer == 1): $AnimationPlayer.play("ToLayer2");
	if(current_layer == 2): $AnimationPlayer.play("ToLayer3");
	yield($AnimationPlayer, "animation_finished")
	current_layer += 1;
	
	$Text.play_anim_then_loop("popup", "loop");
	yield($Text, "animation_complete")
	$LeftButton.enabled = true;
	$RightButton.enabled = true;
	$LeftButton.pressed = false;
	$RightButton.pressed = false;
	
func show_multiplier(right):
	var parent = _lasttori.get_parent();
	parent.remove_child(_lasttori);
	add_child_below_node($Fade, _lasttori);
	_lasttori.play_anim("popup", false);

	counter_text.text = "x"+str(layer_wins[current_layer-1]);
	counter_text.get_parent().remove_child(counter_text);	
	if(right):
		$TextRightPosition.add_child(counter_text)
	else:
		$TextLeftPosition.add_child(counter_text)

	counter_text.rect_pivot_offset = counter_text.rect_size/2;
	counter_text.rect_position = -counter_text.rect_size/2;
	counter_text.get_node("Background").position = counter_text.rect_size/2;
	counter_text.get_node("Background").position.y += 100;
	counter_text.visible = true;
	$AnimationPlayer.play("ShowWin");
	counter_text.get_node("AnimationPlayer").play("Show");
	yield($AnimationPlayer, "animation_finished")
	yield(get_tree().create_timer(2.0), "timeout")
	$AnimationPlayer.play("HideWin");
	yield($AnimationPlayer, "animation_finished")
	Globals.singletons["FaderBright"].tween(0.6,0.0,1);
	remove_child(_lasttori);
	parent.add_child(_lasttori);
	emit_signal("_show_mult_end");
	
func last_layer_end():
	$AnimationPlayer.play("Hide");
	yield($AnimationPlayer, "animation_finished")
	emit_signal("anim_end");
	shown = false;
