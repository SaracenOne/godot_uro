extends Reference

const godot_uro_request_const = preload("godot_uro_requestor.gd")
const godot_uro_helper_const = preload("godot_uro_helper.gd")

const USER_NAME = "user"
const SHARD_NAME = "shard"

#func cancel_async() -> void:
#	yield(requestor.cancel(), "completed")

static func populate_query(p_query_name : String, p_query_dictionary : Dictionary) -> Dictionary:
	var query : Dictionary = {}

	for key in p_query_dictionary.keys():
		query["%s[%s]" % [p_query_name, key]] = p_query_dictionary[key]

	return query

func sign_in_async(username_or_email : String, password : String) -> String:
	var host_and_port : Dictionary = GodotUro.get_host_and_port()
		
	var query : Dictionary = {
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
	
func create_shard_async(p_query : Dictionary) -> String:
	var host_and_port : Dictionary = GodotUro.get_host_and_port()
		
	var query : Dictionary = populate_query(SHARD_NAME, p_query)
	
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
	
func delete_shard_async(p_id : String, p_query : Dictionary) -> String:
	var host_and_port : Dictionary = GodotUro.get_host_and_port()
		
	var query : Dictionary = populate_query(SHARD_NAME, p_query)

	var requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, GodotUro.using_ssl())
	
	requestor.call_deferred("request", "%s%s/%s" % [godot_uro_helper_const.get_api_path(), godot_uro_helper_const.SHARDS_PATH, p_id], \
	query, {"method": HTTPClient.METHOD_DELETE, "encoding": "form"})
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
	
func update_shard_async(p_id : String, p_query : Dictionary) -> String:
	var host_and_port : Dictionary = GodotUro.get_host_and_port()
	
	var query : Dictionary = populate_query(SHARD_NAME, p_query)
	
	var requestor = godot_uro_request_const.new(host_and_port.host, host_and_port.port, GodotUro.using_ssl())
	
	requestor.call_deferred("request", "%s%s/%s" % [godot_uro_helper_const.get_api_path(), godot_uro_helper_const.SHARDS_PATH, p_id], \
	query, {"method": HTTPClient.METHOD_PUT, "encoding": "form"})
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
		
	var query : Dictionary = populate_query(SHARD_NAME, {})
	
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
