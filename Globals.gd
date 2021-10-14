extends Node

var singletons = {};
var spindata = {};

signal allready;
signal resolutionchanged(landscape, portrait, ratio, zoom);
signal configure_bets(bets, defaultbet, multiplier);
signal update_balance(new, currency);
signal update_view(view);

var currentBet : float;

var screenratio : float;
var landscape : bool = false;
var portrait : bool = false;

var _resolution : Vector2;
var zoom_resolution_from : float = 1024;
var zoom_resolution_to : float = 768;
var landscaperatio : float = 16.0/9.0;
var portraitratio : float = 9.0/20.0;

var visible_reels_count : int = 0;
var visible_tiles_count : int = 0;
var canSpin : bool setget ,check_can_spin;
	
func _ready():
	yield(get_tree(),"idle_frame")
	emit_signal("allready");

func register_singleton(name, obj):
	singletons[name] = obj;

func _process(delta):
	var res = Vector2(OS.window_size.x, OS.window_size.y); #get_viewport().get_visible_rect().size;
	if(_resolution != res):
		_resolution_changed(res);
		_resolution = res;

func _resolution_changed(newres : Vector2):
	screenratio = clamp(inverse_lerp(landscaperatio, portraitratio, newres.x/newres.y), 0, 1);
	landscape = screenratio > 0.5;
	portrait = screenratio <= 0.5;
	var zoom : float = min(newres.x, newres.y);
	zoom = inverse_lerp(zoom_resolution_from, zoom_resolution_to, zoom);
	
	emit_signal("resolutionchanged", landscape, portrait, screenratio, zoom);
	prints("New screen ratio ", newres, landscape, portrait, screenratio, zoom)

func check_can_spin():
	return !singletons["Fader"].visible && !singletons["Slot"].spinning && singletons["Game"].round_ended;

func format_money(v):
	return ("%.2f" % v) + "$";

func safe_set_parent(obj, newparent):
	var pos = obj.global_position;
	var scale = obj.global_scale;
	obj.get_parent().remove_child(obj);
	newparent.add_child(obj);
	obj.global_scale = scale;
	obj.global_position = pos;
	if(obj.get_node_or_null("SpineSprite") != null):
		obj.get_node("SpineSprite").update_skeleton();
