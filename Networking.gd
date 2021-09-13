extends Node

signal initreceived (data);
signal spinreceived (data);
signal closereceived (data);
signal fail(errorcode);
signal success();

export (String) var init_sessionID : String;
export (String) var game : String;
export (String) var mode : String;
export (String) var operator : String;
export (String) var currency : String;
export (String) var force : String;

var sessionID : String= "";
var stateID : String= "";
var roundID : String= "";
var playerID : String= "";
var wallet : String="";
var waiting_for_response : bool = false;

const ERROR = 1
const OK = 0

var _host : String = "https://dev.maverick-ops.com";
var _port : int = 443;
var _error : String = "";
var _response : Dictionary;

func _ready():
	sessionID = init_sessionID;
	connect("fail",self,"on_fail")
	Globals.register_singleton("Networking", self);
	
func request_init():
	if(waiting_for_response): return printerr("Trying to request while waiting for response");

	var data = {
		"game" : game,
		"operator" : operator,
		"mode" : mode,
		"currency" : currency
	}
	htmlpost("/v2/rgs/init2", JSON.print(data), "initreceived");
	data = yield(self, "initreceived");
	var lastround = null;
	if("init" in data["lastRound"]): lastround = data["lastRound"]["init"];
	elif("base" in data["lastRound"]): lastround = data["lastRound"]["base"];
	else: return on_fail(901);
	
	Globals.currentBet = float(data["defaultBet"]); ## TODO
	
	Globals.emit_signal("configure_bets", 
		data["stakeValues"], 
		data["defaultBet"], 
		data["reelSets"]["base"]["betMultiplier"]);
	Globals.emit_signal("update_view", 
		lastround["view"]);
	Globals.emit_signal("update_balance", 
		lastround["balance"]["amount"]["amount"], 
		lastround["balance"]["amount"]["currency"]);
	update_state(lastround);
	self.wallet = _response["wallet"];
	if(not lastround["closed"]):
		#show lastround["Win"]
		request_close();
	
func request_spin():
	if(waiting_for_response): return printerr("Trying to request while waiting for response");
	
	var data = {
		"game" : game,
		"stake" : Globals.currentBet,
		"previousID" : stateID,
		"action" : "base",
		"wallet" : wallet,
		"force" : "",
	}
	htmlpost("/v2/rgs/play2", JSON.print(data), "spinreceived");
	data = yield(self, "spinreceived");
	update_state(data);

func request_close():
	if(waiting_for_response): return printerr("Trying to request while waiting for response");
	var data = {
		"game" : game,
		"round" : stateID,
		"wallet": wallet
		
	}
	htmlput("/v2/rgs/close", JSON.print(data), "closereceived");
	yield(self, "closereceived");
	print("Round closed");
	
func htmlget(url, finsignal):
	prints("GET Request: ",url);
	_request( HTTPClient.METHOD_GET, url, "", finsignal)

func htmlpost(url, body, finsignal):
	prints("POST Request: ",url,body);
	_request( HTTPClient.METHOD_POST, url, body, finsignal)

func htmlput(url, body, finsignal):
	prints("PUT Request: ",url,body);
	_request( HTTPClient.METHOD_PUT, url, body, finsignal)

func _request(method, url, body, finsignal):
	if(waiting_for_response): return printerr("Trying to request while waiting for response");

	waiting_for_response = true;
	var client : HTTPClient = HTTPClient.new();
	var err = 0;
	err = client.connect_to_host(_host, _port);
	client.poll();
	if(err != OK): return emit_signal("fail", err);
	
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		yield(Engine.get_main_loop(), "idle_frame");
		client.poll();
		
	assert(client.get_status() == HTTPClient.STATUS_CONNECTED)
		
	var headers = [];
	headers.append("Content-Type: application/json");
	headers.append("Authorization: "+get_auth());
	err = client.request( method, url, PoolStringArray(headers), body)
	if(err != OK): return emit_signal("fail", err);
	client.poll()
	
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		yield(Engine.get_main_loop(), "idle_frame");
		client.poll();
		
	assert(client.get_status() == HTTPClient.STATUS_BODY or client.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.
		
	if client.has_response():
		var rb = PoolByteArray() # Array that will hold the data.
		
		while client.get_status() == HTTPClient.STATUS_BODY:
			client.poll()

			var chunk = client.read_response_body_chunk()
			if chunk.size() == 0:
				yield(Engine.get_main_loop(), "idle_frame")
			else:
				rb = rb + chunk

		waiting_for_response = false;
		client.close();

		var response = rb.get_string_from_utf8();
		var json = JSON.parse(response);
		if(json.error == OK):
			_response = json.result;
			prints("Response", url,_response);
			var response_code = client.get_response_code();
			if( response_code >= 400 ):
				emit_signal("fail", response_code)
			elif(_response.has("code")):
				emit_signal("fail", _response["code"]);
			else:
				emit_signal(finsignal, _response);
		else:
			emit_signal("fail", 900);
	else:
		emit_signal("fail", 902);


func get_auth():
	return "Maverick-Host-Token " + sessionID;

func update_state(state):
	self.sessionID = state["host/verified-token"];
	self.stateID = state["stateID"];
	self.roundID = state["roundID"];

func on_fail(errcode):
	if(errcode == 900):
		#JSON parse failure
		pass;
	if(errcode == 901):
		#Invalid init round data
		pass;
	if(errcode == 902):
		#Empty response
		pass;
	#400: CoreTranslations.BadRequest,
	#401: CoreTranslations.InvalidToken,
	#403: CoreTranslations.Forbidden,
	#404: CoreTranslations.GameEngineNotFound,
	#406: CoreTranslations.RequestNotAcceptable,
	#408: CoreTranslations.Timeout,
	#412: CoreTranslations.IncorrectSequence,
	#428: CoreTranslations.MissingSequencePrecondition,
	#429: CoreTranslations.TooManyRequests,
	#450: CoreTranslations.InsufficientFunds,
	#451: CoreTranslations.RealityCheckMessage,
	#503: CoreTranslations.GameUnavailable,
	#500: CoreTranslations.NetworkError,
	#504: CoreTranslations.Timeout