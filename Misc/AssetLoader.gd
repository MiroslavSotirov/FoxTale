extends Node
export(Array) var tiles;
export(Array) var tilesBlur;

func _ready():
	Globals.register_singleton("AssetLoader", self);


