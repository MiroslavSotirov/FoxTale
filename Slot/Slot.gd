extends TextureRect
export (Array) var availableTiles : Array = [];
export (Array) var reels : Array = [];
export (bool) var testSpinStart : bool setget _test_spin_start_set;
export (bool) var testSpinStop : bool setget _test_spin_stop_set;
export (float) var reelStartDelay = 0.01;
export (float) var reelStopDelay = 0.01;

var spinning : bool setget , _get_spinning;
var stopped : bool setget , _get_stopped;
var stopping : bool setget , _get_stopping;

func _ready():
	Globals.register_singleton("Slot", self);
	testSpinStart = false;
	testSpinStop = false;
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
	
func stop_spin():
	if(self.stopping || self.stopped): return;
	for reel in reels:
		reel.stop_spin([0,0,0,0]);
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
