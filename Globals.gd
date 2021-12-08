extends Node

var singletons = {};
var spindata = {};

signal allready;
signal resolutionchanged(landscape, portrait, ratio, zoom);
signal configure_bets(bets, defaultbet, multiplier);
signal update_balance(new, currency);
signal update_view(view);
signal skip;

var currentBet : float;

var screenratio : float;
var landscape : bool = false;
var portrait : bool = false;

var resolution : Vector2;
var zoom_resolution_from : float = 2048+1024;
var zoom_resolution_to : float = 1024;
var landscaperatio : float = 16.0/9.0;
var portraitratio : float = 9.0/20.0;

var visible_reels_count : int = 0;
var visible_tiles_count : int = 0;
var canSpin : bool setget ,check_can_spin;

var current_language = "NONE";
var currency_symbol = "฿";
var currency_code = "USD";
var currency_position = true;
	
func loading_done():
	print("loading done");
	JS.connect("set_stake", self, "set_stake");
	connect("configure_bets", self, "configure_bets");
	yield(get_tree(),"idle_frame")
	emit_signal("allready");
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	_resolution_changed(resolution);

	if(JS.enabled): 
		JS.output("", "elysiumgamerequestinit");
	else: 
		singletons["Networking"].request_init();
	
func register_singleton(name, obj):
	singletons[name] = obj;

func _process(delta):
	var res = Vector2(OS.window_size.x, OS.window_size.y); #get_viewport().get_visible_rect().size;
	if(resolution != res):
		_resolution_changed(res);

		
func _resolution_changed(newres : Vector2):
	#newres *= 2
	yield(VisualServer, "frame_post_draw");
	screenratio = clamp(inverse_lerp(landscaperatio, portraitratio, newres.x/newres.y), 0, 1);
	landscape = screenratio > 0.5;
	portrait = screenratio <= 0.5;
	var zoom : float = min(newres.x, newres.y);
	zoom = inverse_lerp(zoom_resolution_from, zoom_resolution_to, zoom);
	resolution = newres;
	emit_signal("resolutionchanged", landscape, portrait, screenratio, zoom);
	prints("New screen ratio ", newres, landscape, portrait, screenratio, zoom)

func check_can_spin():
	return !singletons["Fader"].visible && !singletons["Slot"].spinning && singletons["Game"].round_ended;

func format_money(v):
	v = float(v);
	if(currency_position):
		return currency_symbol+("%.2f" % v);
	else:
		return ("%.2f" % v)+currency_symbol;

func safe_set_parent(obj, newparent):	
	yield(VisualServer, "frame_post_draw");
	if(obj == null || !is_instance_valid(obj)): return;
	var transform = obj.get_global_transform();
	if(obj.get_parent() != null):
		obj.get_parent().remove_child(obj);
	newparent.add_child(obj);
	obj.set_global_transform(transform);
	update_all(obj);		
	obj.update();

func update_all(obj):
	for child in obj.get_children():
		if("update" in child): child.update();
		if("_draw" in child): child._draw();
		update_all(child);
		
func set_jurisdiction(jrd):
	pass;
	
func set_debug(dbg):
	pass;
	
func set_currency(currency):
	singletons["Networking"].set_currency(currency);
	
func set_stake(stake):
	currentBet = float(stake);
	
func set_language(lang : String):
	lang = lang.to_upper();
	prints("LANGUAGE SET TO ",lang);
	current_language = lang;
	singletons["AssetLoader"].download_language(lang);
	
func configure_bets(bets, defaultbet, multiplier):
	currentBet = float(bets[-1]);
	var biggestbet = float(bets[-1]) * float(multiplier);
	singletons["BigWin"].big_win_limit = biggestbet * 1.05;
	singletons["BigWin"].super_win_limit = biggestbet * 2;
	singletons["BigWin"].mega_win_limit = biggestbet * 3;

