extends Control

signal _show_mult_end;
signal anim_end;

var current_layer = 1;

var _lasttori;

func show():
	current_layer = 1;
	$Text.visible = false;
	$AnimationPlayer.play("Show");
	yield(get_tree().create_timer(2.0), "timeout")
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
	show_multiplier();
	yield(self, "_show_mult_end");
	if(current_layer < 3): go_to_next_stage();
	else: last_layer_end();
	
func left_button_pressed():
	print("Left");
	$LeftButton.enabled = false;
	$RightButton.enabled = false;
	_lasttori = $Layer1/ToriLeft;
	if(current_layer == 2): _lasttori = $Layer2/ToriLeft;
	if(current_layer == 3): _lasttori = $Layer3/ToriLeft;
	$Text.play_anim("close", false);
	show_multiplier();
	yield(self, "_show_mult_end");
	if(current_layer < 3): go_to_next_stage();
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
	
func show_multiplier():
	var parent = _lasttori.get_parent();
	parent.remove_child(_lasttori);
	add_child_below_node($Fade, _lasttori);
	_lasttori.play_anim("popup", false);
	$AnimationPlayer.play("ShowWin");
	yield($AnimationPlayer, "animation_finished")
	yield(get_tree().create_timer(2.0), "timeout")
	$AnimationPlayer.play("HideWin");
	yield($AnimationPlayer, "animation_finished")
	Globals.singletons["FaderBright"].tween(0.6,0.0,1);
	remove_child(_lasttori);
	parent.add_child(_lasttori);
	emit_signal("_show_mult_end");
	
func last_layer_end():
	pass;
