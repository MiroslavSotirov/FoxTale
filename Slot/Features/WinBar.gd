extends Control

var shown = false;
var tween : Tween;
var amount : float;
var target : float;

signal HideEnd;

func _ready():
	Globals.register_singleton("WinBar", self);

func show_win(target):
	if(shown): return;
	
	shown = true;	
	amount = 0;
	self.target = target;
	
	$AnimationPlayer.play("Show");
	$CounterText.text = Globals.format_money(0);
	tween = Tween.new();
	add_child(tween);
	tween.interpolate_method ( self, "set_text", 
		0, self.target, 1, 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start();
	#tween.connect("tween_all_completed", self, "hide");

func set_text(v):
	amount = v;
	$CounterText.text = Globals.format_money(v);

func hide():
	tween.queue_free();
	shown = false;
	$AnimationPlayer.play("Hide");
	yield($AnimationPlayer, "animation_finished");
	emit_signal("HideEnd");
