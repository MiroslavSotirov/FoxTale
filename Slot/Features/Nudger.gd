extends Node

signal activationend;
signal nudgeend;

var nudge_values = {};

func _ready():
	yield(Globals, "allready")
	Globals.singletons["Game"].features.append(self);
	yield(get_tree(),"idle_frame");
	for reel in Globals.singletons["Slot"].reels:
		nudge_values["reel"+str(reel.index)] = 0;

func has_feature(spindata):
	return true;
	
func activate(spindata):
	if(false): emit_signal("activationend");

	var reel = Globals.singletons["Slot"].reels[0];
	var distance_to_move = -reel.tileDistance;
	nudge_reel(reel, distance_to_move);
	yield(self,"nudgeend");
	
	emit_signal("activationend");

	#Globals.singletons["Slot"].reels[0].move();

func nudge_reel(reel, targetdistance):
	reel.stopping = false;
	var duration = 1;
	var tween = Tween.new();
	add_child(tween);
	var index = "reel"+str(reel.index);
	tween.interpolate_property(self, "nudge_values:"+index,
		0, targetdistance, duration,
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start();
	
	var lastdistance = 0;
	while nudge_values[index] != targetdistance:
		var delta = nudge_values[index] - lastdistance;
		lastdistance = nudge_values[index];
		reel.move(delta);
		yield(get_tree(), "physics_frame");
	yield(tween,"tween_all_completed");
	nudge_values[index] = 0;
	emit_signal("nudgeend");
	
