extends SpineSprite

export(String) var skin;
export(String) var startanimation;
export(bool) var loop = true;

func _ready():
	play_anim(startanimation, loop);
	set_skin(skin);

func set_skin(skin):
	get_skeleton().set_skin_by_name(skin);

func play_anim(anim, loop):		
	get_animation_state().set_animation(anim, loop);
