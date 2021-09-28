extends Node

func _ready():
	yield(Globals, "allready")
	Globals.singletons["Slot"].connect("apply_tile_features", self, "apply_to_tiles");
	
func apply_to_tiles(spindata, reeldata):
	pass;
	

