extends Node2D

export(String) var popup_animation;
export(bool) var wait_for_popup = true;
export(bool) var change_z_index = true;

var previous_tile;
var registered : bool = false;

var tileX;
var tileY;
var id;

signal popupcomplete;

func _ready():
	Globals.singletons["PopupTiles"].created_tiles.append(self);
	
func init(tile):
	if(previous_tile):
		previous_tile.remove_child(self);
	else: register(tile);
	
	tile.add_child(self);
	tileX = tile.reelIndex;
	tileY = tile.tileIndex;
	previous_tile = tile;	

func discard(tile):
	prints("discarded "+name, tile.reelIndex);
	queue_free();
	Globals.singletons["PopupTiles"].created_tiles.erase(self);

func register(tile):
	registered = true;
	tile.reel.connect("onstopped", self, "on_reel_stopped");
	tile.reel.connect("onstartspin", self, "on_spin_start");
	
func on_spin_start():
	unpop();

func popup(loop = false):
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
	yield($SpineSprite,"animation_complete");
	if(change_z_index): unpop();
	emit_signal("popupcomplete");
	Globals.singletons["PopupTiles"].popup_complete();
