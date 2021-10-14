extends Control
const TileData = preload("TileData.gd")

export (float) var topOffset : float = 0;
export (float) var spinPosition : float = 0;
export (float) var spinPositionOffset : float = 0;
export (int) var spinPositionNormal : int = 0;
export (float) var spinSpeed : float = 10;
export (float) var spinSpeedMultiplier : float = 0;
export (float) var tileDistance : float = 150;
export (int) var topTileCount : int = 3;
export (int) var visibleTileCount : int = 3;
export (int) var bottomTileCount : int = 3;
export (int) var stopExtraDistance : int = 5;
export (Array) var targetData : Array;
export (PackedScene) var tileScene;

signal onstartspin;
signal onstopping;
signal onstopped;

var slot;

var totalTileCount : int;
var queueData = [];
var currentTiles = [];
var tiles = {};
var visible_tiles = [];

var spinning : bool = false;
var stopped : bool = true;
var stopping : bool = false;

var index : int = 0;

var _spinPositionNormal : int = 0;
var _spinPositionTarget : float = 0;

func initialize():
	totalTileCount = topTileCount + visibleTileCount + bottomTileCount;
		
	for i in range(totalTileCount):
		_generate_tile_at(i-topTileCount);
		currentTiles[i].setTileData(_generate_random_tiledata());
		tiles[i-topTileCount] = currentTiles[i];
		if(i >= topTileCount && i < topTileCount+visibleTileCount):
			visible_tiles.append(currentTiles[i]);
		
func get_tile_at(y):
	return currentTiles[topTileCount+y];
	
func _process(delta):
	if(spinSpeedMultiplier != 0):
		move(spinSpeed*spinSpeedMultiplier*delta);

func start_spin():
	stopping = false;
	stopped = false;
	spinning = true;
	$AnimationPlayer.play("ReelSpinStartAnimation");
	emit_signal("onstartspin");

func _start_spin_anim_end():
	for tile in currentTiles: tile.blur = true;
	
func stop_spin(data):
	data.invert(); ## TODO!
	#for i in range(stopExtraDistance + topTileCount): queueData.push_back(_generate_random_tiledata());
	for n in data: queueData.push_back(n);
	for i in range(stopExtraDistance + topTileCount): queueData.push_back(_generate_random_tiledata());

	targetData = data;
	#spinPosition = fmod(spinPosition, tileDistance * totalTileCount);
	_spinPositionTarget = spinPosition - fmod(spinPosition, tileDistance) + len(queueData)*tileDistance;
	stopping = true;
	emit_signal("onstopping");
	
func stop_spin_anim():
	for tile in currentTiles: tile.blur = false;
	$AnimationPlayer.play("ReelSpinStopAnimation");
	
func _stop_spin_anim_end():
	spinning = false;
	stopped = true;
	emit_signal("onstopped");
	
func move(amount : float):
	if(stopping):
		if(amount > 0): #We are moving down;
			spinPosition = min(spinPosition + amount, _spinPositionTarget);
		elif(amount < 0): #we are moving up
			spinPosition = max(spinPosition + amount, _spinPositionTarget);
		if(spinPosition == _spinPositionTarget):
			stop_spin_anim();
	else: 
		spinPosition += amount;

	spinPositionNormal = int(spinPosition/tileDistance);
	if(_spinPositionNormal != spinPositionNormal):
		var dir = sign(spinPositionNormal-_spinPositionNormal);
		if(dir > 0):
			for i in range(abs(spinPositionNormal-_spinPositionNormal)): 
				shift_down_tiles();
		elif(dir < 0):
			for i in range(abs(spinPositionNormal-_spinPositionNormal)): 
				shift_up_tiles();
	_spinPositionNormal = spinPositionNormal;

func shift_down_tiles():
	if(len(queueData)==0): queueData.push_back(_generate_random_tiledata());

	var lastTile = currentTiles[len(currentTiles)-1];
	if(lastTile.data.feature != null && is_instance_valid(lastTile.data.feature)): 
		lastTile.data.feature.discard(lastTile);
	
	var order = range(1,len(currentTiles));
	order.invert();
	for i in order:
		currentTiles[i].setTileData(currentTiles[i-1].data);
	
	var firstTile = currentTiles[0];
	firstTile.setTileData(queueData.pop_front());	
	
func shift_up_tiles():
	if(len(queueData)==0): queueData.push_back(_generate_random_tiledata());
	
	var lastTile = currentTiles[0];
	if(lastTile.data.feature != null): lastTile.data.feature.discard(lastTile);
	
	var order = range(len(currentTiles)-1);
	for i in order:
		currentTiles[i].setTileData(currentTiles[i+1].data);
	
	var firstTile = currentTiles[len(currentTiles)-1];
	firstTile.setTileData(queueData.pop_front());	
		
func _generate_random_tiledata():
	return TileData.new(slot.availableTiles[randi() % len(slot.availableTiles)]);
		
func _get_tile_pos(n):
	return n*tileDistance;

func _generate_tile_at(position):
	var newTile = tileScene.instance();
	newTile.reel = self;
	newTile.reelPosition = _get_tile_pos(position);
	newTile.reelIndex = index;
	newTile.tileIndex = position;
	currentTiles.insert(position+topTileCount, newTile);	
	
	$TileContainer.add_child(newTile);

