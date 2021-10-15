extends Node2D

export (SpineSkeletonDataResource) var bell;
export (SpineSkeletonDataResource) var fox;
export (SpineSkeletonDataResource) var lantern;
export (SpineSkeletonDataResource) var sake;
export (SpineSkeletonDataResource) var wild;
export (SpineSkeletonDataResource) var junior;

export(int) var id : int setget set_id;

var tileX;
var tileY;

func set_id(n):
	var iswild = false;

	if(n < 0): return;
	if(n > 9): return;
	id = n;
	
	if(id == 0):
		$SpineSprite.animation_state_data_res.skeleton = junior;
		$SpineSprite.get_skeleton().set_skin_by_name("10");
	elif(id == 1):
		$SpineSprite.animation_state_data_res.skeleton = junior;
		$SpineSprite.get_skeleton().set_skin_by_name("j");
	elif(id == 2):
		$SpineSprite.animation_state_data_res.skeleton = junior;
		$SpineSprite.get_skeleton().set_skin_by_name("q");
	elif(id == 3):
		$SpineSprite.animation_state_data_res.skeleton = junior;
		$SpineSprite.get_skeleton().set_skin_by_name("k");
	elif(id == 4):
		$SpineSprite.animation_state_data_res.skeleton = junior;
		$SpineSprite.get_skeleton().set_skin_by_name("a");
	elif(id == 5):
		$SpineSprite.animation_state_data_res.skeleton = sake;
	elif(id == 6):
		$SpineSprite.animation_state_data_res.skeleton = lantern;
	elif(id == 7):
		$SpineSprite.animation_state_data_res.skeleton = bell;
	elif(id == 8):
		$SpineSprite.animation_state_data_res.skeleton = fox;
	elif(id == 9):
		#$SpineSprite.animation_state_data_res.skeleton = wild;
		iswild = true;
	elif(id == 10):
		pass;
	elif(id == 11):
		pass;
	
	if(iswild):
		var expandedwild = Globals.singletons["ExpandingWilds"].get_expanded_wild_at(tileX, tileY);
		var isexpandedwild = expandedwild != null;
		if(isexpandedwild):
			expandedwild.move_on_top();	
		else:
			var tile = Globals.singletons["PopupTiles"].get_tile_at(tileX, tileY);
			tile.popup(true);
			tile.change_z_index = false;
	else:
		$SpineSprite.setup_pose_trigger = true;
		$SpineSprite.clear_tracks_trigger = true;
		yield(get_tree(),"idle_frame");
		var animations = $SpineSprite.animation_state_data_res.skeleton.get_animations();
		for animation in animations:
			var name = animation.get_anim_name();
			if(name == "popup"):
				$SpineSprite.get_animation_state().set_animation("popup", true);
				break;
			elif(name == "animation"):
				$SpineSprite.get_animation_state().set_animation("animation", true);
				break;
