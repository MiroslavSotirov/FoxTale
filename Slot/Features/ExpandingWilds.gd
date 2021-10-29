extends Node

export (int) var wildID : int = 9;

signal allexpanded;

var to_expand : int = 0;

var expanded_wilds = [];

func _ready():
	Globals.register_singleton("ExpandingWilds", self);
	yield(Globals, "allready")
	yield(get_tree(),"idle_frame");
	pass;
	
func has_feature(spindata):
	expanded_wilds.clear();	
	if(!spindata.has("features")): return false;
	for feature in spindata["features"]:
		if(feature["type"]=="ExpandingWild"): return true;
	return false;
	
func expand(spindata):
	yield(get_tree(),"idle_frame");
	to_expand = 0;
	for feature in spindata["features"]:
		if(feature["type"] == "ExpandingWild"): to_expand += 1;
	
	Globals.singletons["Game"].foxes_expand_anim_start();
	yield(Globals.singletons["Game"], "fox_animation_end")
	for feature in spindata["features"]:
		if(feature["type"] != "ExpandingWild"): continue;
		expand_wild(feature);
		yield(get_tree().create_timer(0), "timeout");

	
func expand_wild(feature):
	var wildToExpand = null;
	var tiles = [];
	for pos in feature["data"]["positions"]:
		var y = int(pos)%Globals.visible_tiles_count;
		var x = floor(pos/Globals.visible_tiles_count);	
		var tile = 	Globals.singletons["Slot"].get_tile_at(x,y);
		if(pos == feature["data"]["from"]):
			wildToExpand = tile.data.feature;
		tiles.append(tile);

	#tiles.invert();
	wildToExpand.covers = feature["data"]["positions"];
	wildToExpand.expand(tiles[0], tiles[1]);
	yield(wildToExpand, "expandend")
	for i in range(len(tiles)):			
		if(tiles[i].data.feature != null):
			if(tiles[i].data.feature != wildToExpand):
				tiles[i].data.feature.discard(tiles[i]);
				tiles[i].data.feature = null;
		tiles[i].data.id = wildID;
		tiles[i].self_modulate.a = 0;
	
	wildToExpand.init(tiles[0]);
	expanded_wilds.append(wildToExpand);
	tiles[0].data.feature = wildToExpand;
	expand_complete();
	
func get_expanded_wild_at(x, y):
	var index = float((x*Globals.visible_tiles_count)+y);
	for wild in expanded_wilds:
		if(wild.covers.has(index)): return wild;
	return null;
	
func expand_complete():
	to_expand -= 1;
	if(to_expand == 0):
		emit_signal("allexpanded");
