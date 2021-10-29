extends SpineSprite

export(String) var skin;
export(String) var startanimation;
export(bool) var loop = true;
export(float) var timescale = 1;

var _waiting_change : bool = false;

func _ready():
	#get_animation_state().disable_queue();
	play_anim(startanimation, loop);
	set_skin(skin);

func set_skin(skin):
	get_skeleton().set_skin_by_name(skin);

func play_anim(anim, loop):
	_waiting_change = false;
	yield(VisualServer, "frame_post_draw");
	get_skeleton().set_slots_to_setup_pose();
	
	get_animation_state().clear_tracks();
	get_animation_state().set_animation(anim, loop);
	set_timescale(timescale);
	
func play_anim_then_loop(anim, loopanim):
	play_anim(anim, false);
	_waiting_change = true;
	yield(self, "animation_complete");
	if(_waiting_change): play_anim(loopanim, true);

func set_timescale(scale):
	get_animation_state().set_time_scale(scale);
	timescale = scale;
