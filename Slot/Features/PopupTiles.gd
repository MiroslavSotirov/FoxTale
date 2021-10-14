extends Node2D

export(Dictionary) var popup_tiles : Dictionary;

var created_tiles : Array = [];
var popup_tile_count = 0;
var remaining_tile_count = 0;

signal popuptilesend;

func _ready():
	Globals.register_singleton("PopupTiles", self);
	yield(Globals, "allready")
	Globals.singletons["Slot"].connect("apply_tile_features", self, "apply_to_tiles");

func apply_to_tiles(spindata, reeldata):
	popup_tile_count = 0;
	remaining_tile_count = 0;
	for reel in reeldata:
		for tiledata in reel:
			var id = int(tiledata.id);
			if(popup_tiles.has(id)):
				tiledata.feature = popup_tiles[id].instance();
				tiledata.feature.id = id;
				if(tiledata.feature.wait_for_popup): remaining_tile_count +=1;
				popup_tile_count += 1;

	
func get_tile_at(x,y):
	for tile in created_tiles:
		if(tile.tileX == x && tile.tileY == y): return tile;
	return null;
	
func get_tiles_id(id):
	var arr = [];
	for tile in created_tiles:
		if(tile.id == id): arr.append(tile);
	return arr;
	
func unpop_all():
	for tile in created_tiles: tile.unpop();

func popup_complete():
	remaining_tile_count -= 1;
	if(remaining_tile_count == 0):
		emit_signal("popuptilesend");
