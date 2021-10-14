extends Sprite
const TileData = preload("TileData.gd")
export (float) var reelPosition : float;
export (int) var reelIndex : int;
export (int) var tileIndex : int;
export (bool) var blur : bool setget _setblur;

signal ondiscard (tile, pos);

var reel;
var data;

func _init():
	connect("visibility_changed", self, "_on_visibility_changed");

func setTileData(data):
	self.data = data;
	if(self.data == null): return
	if(visible): _updatetex();
	
	if(self.data.feature != null && is_instance_valid(self.data.feature)): 
		self.data.feature.init(self);
	
func _setblur(val):
	if(self.data == null): return
	blur = val;
	if(visible): _updatetex();
	
func _updatetex():
	if(blur): self.texture = Globals.singletons["AssetLoader"].tilesBlur[self.data.id];
	else: self.texture = Globals.singletons["AssetLoader"].tiles[self.data.id];

func _process(delta):
	position.y = reelPosition + fmod(reel.spinPosition, reel.tileDistance) + reel.spinPositionOffset + reel.topOffset;

func _on_visibility_changed(n):
	if(visible): _updatetex();
