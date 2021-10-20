extends "res://Slot/Features/PopupTile/PopupTileFeature.gd"

export(Vector2) var expanded_scale : Vector2;

var root = null;
var expanded : bool = false;
var offset : int = 0;
var covers : Array = [];

signal expandend;

func popup(loop = false):
	move_on_top();
	$SpineSprite.play_anim("popup_wildsmall", loop);
	$SpineSprite.set_timescale(1);

func expand(root, middletile):
	self.root = root;
	previous_tile = root;
	expanded = true;
	move_on_top();
	var scale = global_scale;
	print("TRY EXPAND");
	$SpineSprite.play_anim("wild_transform", false);
	$SpineSprite.set_timescale(1);
	yield(get_tree(), "idle_frame");
	$Tween.interpolate_property(self, "global_position", 
		null, middletile.global_position, 0.5, 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
	$Tween.interpolate_property(self, "scale", 
		null, scale * expanded_scale, 0.5, 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
	$Tween.start();
	
	yield($SpineSprite,"animation_complete")
	$SpineSprite.play_anim("idle_wildbig", true);
	emit_signal("expandend");
	
func init(tile):
	#if(root != null && tile != root): return;
	if(previous_tile):
		previous_tile.self_modulate.a = 1;
	tile.self_modulate.a = 1;
	.init(tile);
	
func discard(tile):
	tile.self_modulate.a = 1;
	.discard(tile);

func on_spin_start():
	unpop();
