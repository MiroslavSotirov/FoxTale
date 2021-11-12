extends Node

var current_music : String = "";

func _ready():
	Globals.register_singleton("Audio", self);

func play(sfx, vol=1.0):
	JS.play_sound(sfx, vol);
	
func stop(sfx):
	JS.stop_sound(sfx);

func loop(sfx, vol=1.0):
	JS.loop_sound(sfx, vol);
	
func pause(sfx):
	JS.pause_sound(sfx);

func fade(sfx, from, to, duration):
	JS.fade_sound(sfx, from, to, duration);

func change_music(new_track):
	if(new_track == current_music): return;
	if(current_music != ""):
		fade(current_music, 1, 0, 1);
	loop(new_track);
	fade(new_track, 0, 1, 1);
	current_music = new_track;
	

