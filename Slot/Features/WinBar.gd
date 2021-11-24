extends Control

var shown = false;
var tween : Tween;
var amount : float;
var target : float;

signal CountEnd
signal HideEnd;

func _ready():
	VisualServer.canvas_item_set_z_index(get_canvas_item(), 19);
	amount = 0.0;
	Globals.register_singleton(name, self);

func show_win(target, bottom = true):
	self.target = target;

	if(!shown):
		if(bottom): $AnimationPlayer.play("ShowBottom");
		else: $AnimationPlayer.play("Show");
		
	$CounterText.text = Globals.format_money(amount);
	
	tween = Tween.new();
	add_child(tween);
	tween.interpolate_method ( self, "set_text", 
		amount, self.target, 1, 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
		
	tween.start();
	tween.connect("tween_all_completed", self, "count_end");
	shown = true;	
	Globals.singletons["Audio"].loop("Coins Endless")
	
func set_text(v):
	if(!shown):
		$AnimationPlayer.play("ShowBottom");
		$AnimationPlayer.seek($AnimationPlayer.current_animation_length,true);
		shown = true;
	amount = v;
	$CounterText.text = Globals.format_money(v);

func count_end():
	Globals.singletons["Audio"].stop("Coins Endless")
	if($AnimationPlayer.assigned_animation == "Show"):
		$AnimationPlayer.play("GoDown");
		yield($AnimationPlayer,"animation_finished")
	emit_signal("CountEnd");

func hide(instant=false):
	if(!shown): return;
	if(tween != null && is_instance_valid(tween)):
		tween.queue_free();
		tween = null;
		set_text(target);
		Globals.singletons["Audio"].stop("Coins Endless")
	shown = false;
	if(instant):
		$AnimationPlayer.play("Hide");
		$AnimationPlayer.seek($AnimationPlayer.current_animation_length,true);
	else:
		$AnimationPlayer.play("Hide");
		yield($AnimationPlayer, "animation_finished");
	amount = 0.0;
	emit_signal("HideEnd");
