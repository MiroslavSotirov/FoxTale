extends Node2D

export(String) var popup_animation;

var previous_tile;
var registered : bool = false;

var tileX;
var tileY;

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
	
func popup():
	$SpineSprite.play_anim(popup_animation, false);
	$SpineSprite.set_timescale(1);
	
func on_reel_stopped():
	popup();
	yield($SpineSprite,"animation_complete");
	emit_signal("popupcomplete");
	Globals.singletons["PopupTiles"].popup_complete();
