extends Node

export(Dictionary) var popup_tiles : Dictionary;

var created_tiles : Array = [];

func _ready():
	Globals.register_singleton("PopupTiles", self);
	yield(Globals, "allready")
	Globals.singletons["Slot"].connect("apply_tile_features", self, "apply_to_tiles");

func apply_to_tiles(spindata, reeldata):
	for reel in reeldata:
		for tiledata in reel:
			var id = int(tiledata.id);
			if(popup_tiles.has(id)):
				tiledata.feature = popup_tiles[id].instance();
	
func get_tile_at(x,y):
	for tile in created_tiles:
		if(tile.tileX == x && tile.tileY == y): return tile;
	return null;
