tool
extends Control

export (Array) var lines;
export (int) var lines_count setget set_lines_count;
export (int) var reel_count = 5;
export (PackedScene) var tile_scene; 
export (PackedScene) var line_scene; 

var shown = false;
var shown_tiles : Array; 
signal ShowEnd;

func _ready():
	Globals.register_singleton("WinLines", self);
	
func set_lines_count(n):
	lines_count = n;
	var diff = len(lines) - n;
	if(diff < 0):
		for i in range(abs(diff)):
			var a = [];
			for b in range(reel_count): a.append(0);
			lines.append(a);
	elif(diff > 0):
		for i in range(diff): lines.pop_back();

func show_lines(windata):
	shown = true;
	visible = true;
	Globals.singletons["WinlinesOverlap"].tween(0,1,0.5);
	for win in windata:
		if(win.has("winline") && win["winline"] < 0): continue;
		show_line(win["symbol_positions"]);
		yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("ShowEnd");
		
func show_line(positions):
	var global_positions = [];
		
	for pos in positions:
		if(shown_tiles.has(pos)): continue;
		
		shown_tiles.append(pos);
		var y = int(pos)%3;
		var x = floor(pos/3);		
		var wintile = tile_scene.instance();		
		var tile = Globals.singletons["Slot"].get_tile_at(x,y);
		$TilesContainer.add_child(wintile);
		wintile.tileX = tile.reelIndex;
		wintile.tileY = tile.tileIndex;
		wintile.set_id(tile.data.id);
		wintile.global_position = tile.global_position;
		global_positions.append(tile.global_position);
		
	var winline = line_scene.instance();
	$LinesContainer.add_child(winline);
	winline.global_position = global_positions[0];
	winline.positions = global_positions;
	winline.next();
		
	
	# wins:[
	#	{
	#		index:1:3, 
	#		multiplier:1, 
	#		payout: {count:3, multiplier:5, symbol:1}, 
	#		symbol_positions:[0, 4, 8], 
	#		win:0.150, 
	#		winline:3
	#	}]}
	
func hide_lines():
	shown = false;
	visible = false;
	
	for c in $LinesContainer.get_children():
		$LinesContainer.remove_child(c)
		c.queue_free();

	for c in $TilesContainer.get_children():
		$TilesContainer.remove_child(c)
		c.queue_free();
	
	shown_tiles.clear();
		
	Globals.singletons["WinlinesOverlap"].tween(1,0,1);
