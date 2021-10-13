extends Node2D

var positions = [];

var position_index : int = 0;

func _ready():
	$Tween.connect("tween_all_completed", self, "next");
	
func next():
	position_index += 1;
	if(len(positions) == position_index):
		position_index = 1;
		global_position = positions[0];
		
	$Tween.interpolate_property(
		self, "global_position", 
		positions[position_index-1], positions[position_index], 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
	$Tween.start();
