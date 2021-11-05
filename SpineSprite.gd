extends SpineSprite

export(String) var skin;
export(String) var startanimation;
export(bool) var loop = true;
export(float) var timescale = 1;

var current_anim : String;

func _ready():
	#get_animation_state().disable_queue();
	play_anim(startanimation, loop);
	set_skin(skin);

func set_skin(skin):
	get_skeleton().set_skin_by_name(skin);

func play_anim(anim, loop, timescale_override=null):
	current_anim = anim;
	yield(VisualServer, "frame_post_draw");
	get_skeleton().set_slots_to_setup_pose();
	
	get_animation_state().clear_tracks();
	get_animation_state().set_animation(anim, loop);
	if(timescale_override != null): set_timescale(timescale_override, false);
	else: set_timescale(timescale);
	
func play_anim_then_loop(anim, loopanim):
	play_anim(anim, false);
	yield(self, "animation_complete");
	if(current_anim == anim): play_anim(loopanim, true);

func set_timescale(scale, permanent=true):
	get_animation_state().set_time_scale(scale);
	if(permanent): timescale = scale;

func reset_pose():
	get_skeleton().set_bones_to_setup_pose();
	get_skeleton().set_slots_to_setup_pose();
