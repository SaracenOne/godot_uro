extends Reference

const godot_uro_request_const = preload("godot_uro_requestor.gd")

const LOCALHOST_HOST = "127.0.0.1"
const LOCALHOST_PORT = 4000

const DEFAULT_URO_HOST = LOCALHOST_HOST
const DEFAULT_URO_PORT = LOCALHOST_PORT

const API_PATH = "/api"
const API_VERSION = "/v1"

const NEW_PATH = "/new"

const SIGN_IN_PATH = "/sign-in"
const SHARDS_PATH = "/shards"

var http_client : HTTPClient = null

var use_localhost : bool = true
var uro_host : String = DEFAULT_URO_HOST
var uro_port : int = DEFAULT_URO_PORT

var requestor = null
var busy : bool = false

enum SymbolicErrors {
	OK,
	FAILED,
	NOT_AUTHORIZED
}

signal completed(p_result)

func cancel() -> void:
	yield(requestor.cancel(), "completed")

func get_host_and_port() -> Dictionary:
	var host : String = ""
	var port : int = 0
	
	if use_localhost:
		host = LOCALHOST_HOST
		port = LOCALHOST_PORT
	else:
		host = uro_host
		port = uro_port
		
	return {"host":host, "port":port}
	
func using_ssl() -> bool:
	return false
	
static func get_api_path() -> String:
	return API_PATH + API_VERSION

func sign_in(username_or_email : String, password : String) -> String:
	var host_and_port : Dictionary = get_host_and_port()
		
	var query = {
		"user[username_or_email]": username_or_email,
		"user[password]": password,
	}

	requestor.call_deferred("request", get_api_path() + SIGN_IN_PATH, query, {"method": HTTPClient.METHOD_POST, "encoding": "form"})
	var result = yield(requestor, "completed")
	requestor.close()
	busy = false
	
	var result_dict : Dictionary = _handle_result(result)
	var token : String = ""
	
	if result_dict.output != null:
		var data : Dictionary = result_dict.output.data
		if result_dict.error_code == SymbolicErrors.OK:
			if data.has("access_token"):
				if typeof(data["access_token"]) == TYPE_STRING:
					token = data["access_token"]
			
	emit_signal("completed", token)
	return token
	
func create_shard(port : int, map : String, max_players : int) -> String:
	var host_and_port : Dictionary = get_host_and_port()
		
	var query = {
		"shard[port]": str(port),
		"shard[map]": map,
		"shard[max_users]": max_players
	}
	
	requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, using_ssl())
	
	requestor.call_deferred("request", get_api_path() + SHARDS_PATH, query, {"method": HTTPClient.METHOD_POST, "encoding": "form"})
	var result = yield(requestor, "completed")
	requestor.close()
	busy = false
	
	var result_dict : Dictionary = _handle_result(result)
	var id : String = ""
	
	if result_dict.output != null:
		var data : Dictionary = result_dict.output.data
		if result_dict.error_code == SymbolicErrors.OK:
			if data.has("data"):
				if typeof(data["data"]) == TYPE_STRING:
					id = data["data"]
			
	emit_signal("completed", id)
	return id
	
func delete_shard(p_id : String) -> bool:
	var host_and_port : Dictionary = get_host_and_port()
		
	var query = {
	}
	
	requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, using_ssl())
	
	requestor.call_deferred("request", get_api_path() + SHARDS_PATH + "/" + p_id, query, {"method": HTTPClient.METHOD_DELETE, "encoding": "form"})
	var result = yield(requestor, "completed")
	requestor.close()
	busy = false
	
	var result_dict : Dictionary = _handle_result(result)
	
	emit_signal("completed", null)
	return true
	
static func process_shards_json(p_input) -> Dictionary:
	var result_dict : Dictionary = {}
	var new_shards : Array = []
	
	var output = p_input.get("output")
	if output is Dictionary:
		var data = output.get("data")
		if data is Dictionary:
			var shards = data.get("shards")
			if shards is Array:
				for shard in shards:
					if shard is Dictionary:
						var new_shard : Dictionary
						new_shard.address = shard.get("address", "")
						new_shard.port = shard.get("port", -1)
						new_shard.map = shard.get("map", "")
						new_shard.current_users = shard.get("current_users", 0)
						new_shard.max_users = shard.get("max_users", 0)
						new_shards.push_back(new_shard)
	
	result_dict.error_code = p_input.error_code
	result_dict.shards = new_shards
	return result_dict
	
func get_shards() -> Dictionary:
	var host_and_port : Dictionary = get_host_and_port()
		
	var query = {
	}
	
	requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, using_ssl())
	
	requestor.call_deferred("request", get_api_path() + SHARDS_PATH, query, {"method": HTTPClient.METHOD_GET, "encoding": "form"})
	var result = yield(requestor, "completed")
	requestor.close()
	busy = false
	
	var result_dict : Dictionary = _handle_result(result)
	result_dict = process_shards_json(result_dict)
	
	
	return result_dict
	
func setup_configuration() -> void:
	if !ProjectSettings.has_setting("services/uro/use_localhost"):
		ProjectSettings.set_setting("services/uro/use_localhost", use_localhost)
	else:
		use_localhost = ProjectSettings.get_setting("services/uro/use_localhost")
	
	if !ProjectSettings.has_setting("services/uro/host"):
		ProjectSettings.set_setting("services/uro/host", uro_host)
	else:
		uro_host = ProjectSettings.get_setting("services/uro/host")
		
	if !ProjectSettings.has_setting("services/uro/port"):
		ProjectSettings.set_setting("services/uro/port", uro_port)
	else:
		uro_port = ProjectSettings.get_setting("services/uro/port")

func _handle_result(result) -> Dictionary:
	var result_dict : Dictionary = {"error_code":SymbolicErrors.OK, "output":null}
	
	if !result:
		OS.alert('Network operation failed. Try again later.', 'Error')
		result_dict.error_code = SymbolicErrors.FAILED
		return result_dict

	if !result.ok:
		result_dict.error_code = SymbolicErrors.FAILED
		return result_dict

	# HTTP error
	var kind : int = result.code / 100
	if kind == 4:
		result_dict.error_code = SymbolicErrors.NOT_AUTHORIZED
		return result_dict
	elif kind == 5:
		OS.alert('Server error: ' + str(result.code))
		result_dict.error_code = SymbolicErrors.FAILED
		return result_dict

	result_dict.error_code = OK
	result_dict.output = result.data
	
	return result_dict

func setup():
	setup_configuration()
	http_client = HTTPClient.new()
	
func teardown():
	pass
