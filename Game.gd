extends Node

func _ready():
	yield(Globals, "allready")
	Globals.singletons["Fader"].tween(1,1,0);
	Globals.singletons["Networking"].connect("initreceived", self, "init_data_received");
	Globals.singletons["Networking"].request_init();
	yield(Globals.singletons["Networking"], "initreceived");
	Globals.singletons["Fader"].tween(1,0,0.5);
	
func on_play_button_pressed():
	show_slot();
	
func show_slot():
	Globals.singletons["Fader"].tween(0,1,0.5);
	yield(Globals.singletons["Fader"], "done")
	$IntroContainer.queue_free();
	$SlotContainer.visible = true;
	$UIContainer.visible = true;
	Globals.singletons["Fader"].tween(1,0,0.5);

func _process(delta):
	if($SlotContainer.visible):		
		if(Input.is_action_pressed("spin")): try_spin();
			
func try_spin():
	if(!Globals.canSpin): return;
	
	Globals.singletons["Slot"].start_spin();
	Globals.singletons["Networking"].request_spin();
	var data = yield(Globals.singletons["Networking"], "spinreceived");
	Globals.singletons["Slot"].stop_spin(data);
	Globals.singletons["Networking"].request_close();
	
func check_resolution_for_changes():
	pass;

func init_data_received(data):
	pass

