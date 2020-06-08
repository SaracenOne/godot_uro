extends Reference

const godot_uro_request_const = preload("godot_uro_requestor.gd")

var token : String = ""

const LOCALHOST_HOST = "127.0.0.1"
const LOCALHOST_PORT = 4000

const DEFAULT_URO_HOST = LOCALHOST_HOST
const DEFAULT_URO_PORT = LOCALHOST_PORT

const API_PATH = "/api"
const API_VERSION = "/v1"
const SIGN_IN_PATH = "/sign-in"

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

func cancel() -> void:
	yield(requestor.cancel(), "completed")

func sign_in(email_or_username : String, password : String) -> String:
	# Make sure to use SSL!
	var host : String = ""
	var port : int = 0
	
	if use_localhost:
		host = LOCALHOST_HOST
		port = LOCALHOST_PORT
	else:
		host = uro_host
		port = uro_port
		
	var query = {
		"user[username_or_email]": email_or_username,
		"user[password]": password,
	}
	
	var requestor = godot_uro_request_const.new(host, port, false) # USE_SSL = false
	requestor.request(API_PATH + API_VERSION + SIGN_IN_PATH, query, {"method": HTTPClient.METHOD_POST, "encoding": "form"})
	
	var result = yield(requestor, "completed")
	requestor.close()
	busy = false
	
	var result_dict : Dictionary = _handle_result(result)
	token = ""
	
	if result_dict.output != null:
		var data : Dictionary = result_dict.output.data
		if result_dict.error_code == SymbolicErrors.OK:
			if data.has("access_token"):
				token = data["access_token"]
			
	return token
	
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
		result_dict.error_code = SymbolicErrors.FAILED
		return result_dict

	if !result.ok:
		OS.alert('Network operation failed. Try again later.', 'Error')
		result_dict.error_code = SymbolicErrors.FAILED
		return result_dict

	# HTTP error
	var kind : int = result.code / 100
	if kind == 4:
		result_dict.error_code = SymbolicErrors.NOT_AUTHORIZED
		return result_dict
	elif kind == 5:
		OS.alert('Server error. Try again later.', 'Error')
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
