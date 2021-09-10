extends Sprite
const TileData = preload("TileData.gd")
export (float) var reelPosition : float;
export (int) var reelIndex : int;
export (bool) var blur : bool setget _setblur;

signal ondiscard (tile, pos);

var reel;
var data;

func setTileData(data):
	self.data = data;
	if(self.data == null): return
	if(blur): self.texture = Globals.singletons["AssetLoader"].tilesBlur[self.data.id];
	else: self.texture = Globals.singletons["AssetLoader"].tiles[self.data.id];

	if(self.data.feature != null): self.data.feature.init(self);
	
func _setblur(val):
	if(self.data == null): return
	blur = val;
	if(blur): self.texture = Globals.singletons["AssetLoader"].tilesBlur[self.data.id];
	else: self.texture = Globals.singletons["AssetLoader"].tiles[self.data.id];

func _process(delta):
	position.y = reelPosition + fmod(reel.spinPosition, reel.tileDistance) + reel.spinPositionOffset + reel.topOffset;

func _discard():
	if(reel == null || get_parent() == null): return;
	get_parent().remove_child(self);
	reel.discardedTiles.push_back(self);
	emit_signal("ondiscard", self);

