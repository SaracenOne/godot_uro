extends Reference

const godot_uro_request_const = preload("godot_uro_requestor.gd")
const godot_uro_helper_const = preload("godot_uro_helper.gd")

#func cancel_async() -> void:
#	yield(requestor.cancel(), "completed")

func sign_in_async(username_or_email : String, password : String) -> String:
	var host_and_port : Dictionary = GodotUro.get_host_and_port()
		
	var query = {
		"user[username_or_email]": username_or_email,
		"user[password]": password,
	}
	
	var requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, GodotUro.using_ssl())

	requestor.call_deferred("request", \
	godot_uro_helper_const.get_api_path() \
	+ godot_uro_helper_const.SIGN_IN_PATH, \
	query, {"method": HTTPClient.METHOD_POST, "encoding": "form"})
	
	var result = yield(requestor, "completed")
	requestor.close()
	
	var result_dict : Dictionary = _handle_result(result)
	var token : String = ""
	
	if result_dict.output != null:
		var data : Dictionary = result_dict.output.data
		if result_dict.error_code == godot_uro_helper_const.symbolic_errors.OK:
			if data.has("access_token"):
				if typeof(data["access_token"]) == TYPE_STRING:
					token = data["access_token"]
			
	return token
	
func create_shard_async(p_port : int, p_map : String, p_current_players : int, p_max_players : int) -> String:
	var host_and_port : Dictionary = GodotUro.get_host_and_port()
		
	var query = {
		"shard[port]": str(p_port),
		"shard[map]": p_map,
		"shard[current_users]": p_current_players,
		"shard[max_users]": p_max_players
	}
	
	var requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, GodotUro.using_ssl())
	
	requestor.call_deferred("request", godot_uro_helper_const.get_api_path() + godot_uro_helper_const.SHARDS_PATH, query, {"method": HTTPClient.METHOD_POST, "encoding": "form"})
	var result = yield(requestor, "completed")
	requestor.close()
	
	var result_dict : Dictionary = _handle_result(result)
	var id : String = ""
	
	if result_dict.output != null:
		var data : Dictionary = result_dict.output.data
		if result_dict.error_code == godot_uro_helper_const.symbolic_errors.OK:
			var data_id = data.get("id")
			if data_id is String:
				id = data_id
			
	return id
	
func delete_shard_async(p_id : String, p_port : int) -> String:
	var host_and_port : Dictionary = GodotUro.get_host_and_port()
		
	var query = {
	}
	
	var requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, GodotUro.using_ssl())
	
	requestor.call_deferred("request", godot_uro_helper_const.get_api_path() + godot_uro_helper_const.SHARDS_PATH + "/" + p_id, query, {"method": HTTPClient.METHOD_DELETE, "encoding": "form"})
	var result = yield(requestor, "completed")
	requestor.close()
	
	var result_dict : Dictionary = _handle_result(result)
	var id : String = ""
	
	if result_dict.output != null:
		var data : Dictionary = result_dict.output.data
		if result_dict.error_code == godot_uro_helper_const.symbolic_errors.OK:
			var data_id = data.get("id")
			if data_id is String:
				id = data_id
			
	return id
	
func get_shards() -> Dictionary:
	var host_and_port : Dictionary = GodotUro.get_host_and_port()
		
	var query = {
	}
	
	var requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, GodotUro.using_ssl())
	
	requestor.call_deferred("request", godot_uro_helper_const.get_api_path() + godot_uro_helper_const.SHARDS_PATH, query, {"method": HTTPClient.METHOD_GET, "encoding": "form"})
	var result = yield(requestor, "completed")
	requestor.close()
	
	var result_dict : Dictionary = _handle_result(result)
	result_dict = godot_uro_helper_const.process_shards_json(result_dict)
	
	return result_dict
	
func _handle_result(result) -> Dictionary:
	var result_dict : Dictionary = {"error_code":godot_uro_helper_const.symbolic_errors.OK, "output":null}
	
	if !result:
		result_dict.error_code = godot_uro_helper_const.symbolic_errors.FAILED
		return result_dict

	if !result.ok:
		result_dict.error_code = godot_uro_helper_const.symbolic_errors.FAILED
		return result_dict

	# HTTP error
	var kind : int = result.code / 100
	if kind == 4:
		result_dict.error_code = godot_uro_helper_const.symbolic_errors.NOT_AUTHORIZED
		return result_dict
	elif kind == 5:
		result_dict.error_code = godot_uro_helper_const.symbolic_errors.FAILED
		return result_dict

	result_dict.error_code = OK
	result_dict.output = result.data
	
	return result_dict
