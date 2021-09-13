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

func _ready():
	Globals.register_singleton("Slot", self);
	testSpinStart = false;
	testSpinStop = false;
	yield(Globals, "allready")
	for i in range(len(reels)):
		reels[i] = get_node(reels[i]);
		reels[i].slot = self;
		reels[i].initialize();

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
	
func stop_spin(data = null):
	if(self.stopping || self.stopped): return;
	if(data != null): parse_spin_data(data);
	else: parse_safe_spin_data();
	for i in range(len(reels)):
		reels[i].stop_spin(targetdata[i]);
		yield(get_tree().create_timer(reelStopDelay), "timeout")

func _get_spinning():
	for reel in reels: if(reel.spinning): return true;
	return false;
	
func _get_stopped():
	for reel in reels: if(!reel.stopped): return false;
	return true;
	
func _get_stopping():
	for reel in reels: if(reel.stopping): return true;
	return false;
	
func parse_spin_data(data):
	targetdata=data["view"];
	
func parse_safe_spin_data():
	targetdata=[[0,0,0],[1,1,1],[2,2,2],[3,3,3],[4,4,4]];
