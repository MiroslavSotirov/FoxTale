extends Control

signal anim_end;

func show():
	$Animation.visible = false;
	$AnimationPlayer.play("Show");
	yield(get_tree().create_timer(2.0), "timeout")
	$Animation.play_anim("popup", false);
	$Animation.visible = true;
	yield($Animation, "animation_complete")
	$Animation.play_anim("idle", true);
	$AnimationPlayer.play("ShowButton");
	$CustomButton.pressed = false

func on_play_button_pressed():
	$Animation.set_timescale(3);
	$AnimationPlayer.play("HideButton");
	yield($Animation, "animation_complete")
	$Animation.play_anim("close", false);
	yield(get_tree().create_timer(2.0), "timeout")
	emit_signal("anim_end");
	$AnimationPlayer.play("Hide");
