extends Control
const TileData = preload("TileData.gd")

export (String) var reel_spin_sfx : String;
export (String) var reel_stop_sfx : String;
export (float) var reel_stop_volume : float;
export (String) var reel_start_sfx : String;

export (Array) var availableTiles : Array = [];
export (Array) var reels : Array = [];
export (bool) var testSpinStart : bool setget _test_spin_start_set;
export (bool) var testSpinStop : bool setget _test_spin_stop_set;
export (float) var reelStartDelay = 0.01;
export (float) var reelStopDelay = 0.01;

var allspinning : bool setget , _get_allspinning;
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
	
func assign_tiles(tilearray):
	for x in range(Globals.visible_reels_count):
		for y in range(Globals.visible_tiles_count):
			get_tile_at(x,y).setTileData(TileData.new(tilearray[x][y]));

func _on_reel_stopped():
	Globals.singletons["Audio"].stop(reel_spin_sfx)
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
	Globals.singletons["Audio"].play(reel_start_sfx)
	Globals.singletons["Audio"].loop(reel_spin_sfx)
	for reel in reels:
		reel.start_spin();
		yield(get_tree().create_timer(reelStartDelay), "timeout")
	
	reels_spinning = len(reels);
	emit_signal("onstartspin");
	
func stop_spin(data = null):
	if(self.stopping || self.stopped): return;
	if(data != null): parse_spin_data(data);
	else: parse_safe_spin_data();
	print(targetdata);
	for i in range(len(reels)):
		reels[i].stop_spin(targetdata[i]);
		yield(get_tree().create_timer(reelStopDelay), "timeout")
	emit_signal("onstopping");

func _get_spinning():
	return reels_spinning > 0;
	
func _get_allspinning():
	return reels_spinning == len(reels);
	
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
	print("Parsing safe spin data");
	for i in range(len(reels)):
		targetdata.append([]);
		for n in range(reels[i].visibleTileCount):
			targetdata[i].append(TileData.new(i));

func get_tile_at(x,y):
	return reels[x].get_tile_at(y);
