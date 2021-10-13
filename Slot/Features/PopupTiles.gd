extends Node

export(Dictionary) var popup_tiles : Dictionary;

var created_tiles : Array = [];
var popup_tile_count = 0;
var _popup_tile_count = 0;

signal popuptilesend;

func _ready():
	Globals.register_singleton("PopupTiles", self);
	yield(Globals, "allready")
	Globals.singletons["Slot"].connect("apply_tile_features", self, "apply_to_tiles");

func apply_to_tiles(spindata, reeldata):
	popup_tile_count = 0;
	for reel in reeldata:
		for tiledata in reel:
			var id = int(tiledata.id);
			if(popup_tiles.has(id)):
				tiledata.feature = popup_tiles[id].instance();
				popup_tile_count += 1;
	_popup_tile_count = popup_tile_count;
	
func get_tile_at(x,y):
	for tile in created_tiles:
		if(tile.tileX == x && tile.tileY == y): return tile;
	return null;

func popup_complete():
	_popup_tile_count -= 1;
	print(_popup_tile_count);
	if(_popup_tile_count == 0):
		emit_signal("popuptilesend");
