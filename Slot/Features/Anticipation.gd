extends Node

export(Array) var target_tiles : Array;
export (int) var min_tiles = 2;
export (int) var anticipation_duration = 20;
export (Vector2) var anticipation_offset;
export (PackedScene) var anticipation_scene;

var anticipation : Array = [];
var reel_anticipations : Dictionary = {};
var activating_reel : int = 0;
var ending_reel : int = 0;
var has_anticipation : bool = false;

func _ready():
	Globals.register_singleton("Anticipation", self);
	yield(Globals, "allready")
	Globals.singletons["Slot"].connect("apply_tile_features", self, "apply_to_tiles");
	yield(get_tree(), "idle_frame");
	ending_reel = len(Globals.singletons["Slot"].reels)-1;
	for reel in Globals.singletons["Slot"].reels:
		reel.connect("onstopping", self, "on_reel_stopping", [reel]);
		reel.connect("onstopped", self, "on_reel_stopped", [reel]);
		
func apply_to_tiles(spindata, reeldata):
	var tile_count = {};
	has_anticipation = false;
	anticipation.clear();
	reel_anticipations.clear();
	var reelid = 0;
	for data in spindata["view"]:
		if(has_anticipation):
			anticipation.append(true);
		elif(reelid < ending_reel):
			for tile in target_tiles:
				if(data.has(tile)):
					if(!tile_count.has(tile)): tile_count[tile] = 0;
					tile_count[tile] += 1;
					if(tile_count[tile] >= min_tiles): 
						has_anticipation = true;
						activating_reel = reelid-1;					
					break;
			anticipation.append(false);
		else: 
			anticipation.append(false);
		reelid += 1;
	
	prints("ANTICIPATION: ", anticipation, activating_reel);
	
	reelid = 0;
	var n = 1;
	for reel_anticipation in anticipation:
		if(reel_anticipation):
			Globals.singletons["Slot"].reels[reelid].additional_stop_distance += anticipation_duration * n;
			n += 1;
		reelid += 1;

func on_reel_stopping(reel):
	if(has_anticipation): 
		pass

func on_reel_stopped(reel):
	if(!has_anticipation): return;
	
	if(reel.index == activating_reel): 
		prints("activate at reel ", activating_reel);
		Globals.singletons["Audio"].fade("Anticipation", 1, 1, 0);
		Globals.singletons["Audio"].loop("Anticipation");
		for i in range(len(anticipation)):
			if(anticipation[i]):
				var ant = anticipation_scene.instance();
				Globals.singletons["Slot"].reels[i].add_child(ant);
				ant.position = anticipation_offset;
				reel_anticipations[i] = ant;
				
	elif(reel_anticipations.has(reel.index)):
		reel_anticipations[reel.index].get_node("AnimationPlayer").play("hide");
		if(reel.index == ending_reel):
			Globals.singletons["Audio"].fade("Anticipation", 1, 0, 0.25);
