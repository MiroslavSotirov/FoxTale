extends "res://Slot/Features/PopupTile/PopupTileFeature.gd"

export(int) var width = 1;
export(int) var height = 1;

var root;
var expanded : bool = false;

func popup():
	$SpineSprite.play_anim("popup_wildsmall", true);
	pass;
	
