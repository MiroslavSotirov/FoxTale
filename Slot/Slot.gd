extends Control
const TileData = preload("TileData.gd")

export (Array) var availableTiles : Array = [];
export (Array) var reels : Array = [];
export (bool) var testSpinStart : bool setget _test_spin_start_set;
export (bool) var testSpinStop : bool setget _test_spin_stop_set;
export (float) var reelStartDelay = 0.01;
export (float) var reelStopDelay = 0.01;

var spinning : bool setget , _get_spinning;
var stopped : bool setget , _get_stopped;
var stopping : bool setget , _get_stopping;

var targetdata : Array = [];
var reels_spinning : int = 0;

signal apply_tile_features(spindata, reeldata);
signal onstartspin;
signal onstopping;
signal onstopped;

func _ready():
	Globals.register_singleton("Slot", self);
	testSpinStart = false;
	testSpinStop = false;
	yield(Globals, "allready")
	for i in range(len(reels)):
		reels[i] = get_node(reels[i]);
		reels[i].slot = self;
		reels[i].index = i;
		reels[i].initialize();
		reels[i].connect("onstopped", self, "_on_reel_stopped");
		
	Globals.visible_tiles_count = reels[0].visibleTileCount;
	Globals.visible_reels_count = len(reels);

func _on_reel_stopped():
	reels_spinning -= 1;
	if(reels_spinning == 0): emit_signal("onstopped");

func _test_spin_start_set(val):
	if(!val): return;
	start_spin();
	testSpinStart = false;

func _test_spin_stop_set(val):
	if(!val): return;
	stop_spin();
	testSpinStop = false;	

func start_spin():
	if(self.spinning): return;
	for reel in reels:
		reel.start_spin();
		yield(get_tree().create_timer(reelStartDelay), "timeout")
	
	reels_spinning = len(reels);
	emit_signal("onstartspin");
	
func stop_spin(data = null):
	if(self.stopping || self.stopped): return;
	if(data != null): parse_spin_data(data);
	else: parse_safe_spin_data();
	for i in range(len(reels)):
		reels[i].stop_spin(targetdata[i]);
		yield(get_tree().create_timer(reelStopDelay), "timeout")
	emit_signal("onstopping");

func _get_spinning():
	return reels_spinning > 0;
	
func _get_stopped():
	for reel in reels: if(!reel.stopped): return false;
	return true;
	
func _get_stopping():
	for reel in reels: if(reel.stopping): return true;
	return false;
	
func parse_spin_data(data):
	var spindata = [];
	for reelids in data["view"]:
		var reeldata = [];
		for tileid in reelids:
			reeldata.append(TileData.new(tileid))
		spindata.append(reeldata);
	
	emit_signal("apply_tile_features", data, spindata);
	
	targetdata=spindata;
	
func parse_safe_spin_data():
	targetdata=[
		[TileData.new(1),TileData.new(1),TileData.new(1)],\
		[TileData.new(2),TileData.new(2),TileData.new(2)],\
		[TileData.new(3),TileData.new(3),TileData.new(3)],\
		[TileData.new(4),TileData.new(4),TileData.new(4)],\
	];

func get_tile_at(x,y):
	return reels[x].get_tile_at(y);
