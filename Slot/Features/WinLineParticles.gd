extends CPUParticles2D

var positions = [];

var position_index : int = 0;

func _ready():
	$Tween.connect("tween_all_completed", self, "next");
	
func next():
	position_index += 1;
	if(len(positions) == position_index):
		position_index = 1;
		$Trail.emit = false;
		emitting = false;
		yield(get_tree().create_timer($Trail.lifetime), "timeout");
		global_position = positions[0];
		$Trail.emit = true;
		emitting = true;
		
	$Tween.interpolate_property(
		self, "global_position", 
		positions[position_index-1], positions[position_index], 0.5,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
	$Tween.start();
