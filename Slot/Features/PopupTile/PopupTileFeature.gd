extends Node2D

export(String) var popup_animation;
export(bool) var wait_for_popup = true;
export(bool) var change_z_index = true;
export(String) var hit_sfx;
export(float) var hit_sfx_volume := 0.7;

var previous_tile;
var registered : bool = false;
var skippable : bool = false;
var to_remove : bool = false;
var popped : bool = false;

var tileX : int;
var tileY : int;
var id : int;

signal popupcomplete;

func _ready():
	Globals.singletons["PopupTiles"].created_tiles.append(self);
	Globals.connect("skip", self, "on_try_skip");
	
func init(tile):
	if(to_remove): return
	yield(VisualServer, "frame_pre_draw");
	if(previous_tile && get_parent() == previous_tile):
		previous_tile.remove_child(self);
	else: 
		register(tile);	
		
	if(get_parent() == null):
		tile.add_child(self);
	tileX = tile.reelIndex;
	tileY = tile.tileIndex;
	previous_tile = tile;	

func discard(tile):
	prints("discarded "+name, tile.reelIndex);
	to_remove = true;
	queue_free();
	Globals.singletons["PopupTiles"].created_tiles.erase(self);

func register(tile):
	if(registered): return;
	registered = true;
	tile.reel.connect("onstopped", self, "on_reel_stopped");
	tile.reel.connect("onstartspin", self, "on_spin_start");
	
func on_spin_start():
	unpop();

func popup(loop = false):
	popped = true;
	Globals.singletons["Audio"].play(hit_sfx, hit_sfx_volume)
	move_on_top();
	$SpineSprite.play_anim(popup_animation, loop);
	$SpineSprite.set_timescale(1);
	
func move_on_top():
	z_index = 1;
	Globals.safe_set_parent(self, Globals.singletons["PopupTiles"]);
	
func unpop():
	z_index = 0;
	Globals.safe_set_parent(self, previous_tile);

func on_reel_stopped():
	popup();
	skippable = true;
	yield($SpineSprite,"animation_complete");
	$SpineSprite.set_timescale(1);
	skippable = false;
	if(change_z_index): unpop();
	emit_signal("popupcomplete");
	Globals.singletons["PopupTiles"].popup_complete();

func on_try_skip():
	if(skippable):
		$SpineSprite.set_timescale(3);
