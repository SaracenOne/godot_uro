extends Node
tool

var cfg : ConfigFile = null

const CONFIG_FILE_PATH = "user://uro.ini"
const godot_uro_auth_const = preload("godot_uro_auth.gd")

var godot_uro_auth : godot_uro_auth_const = null

const uro_login_editor_dialog_const = preload("uro_login_editor_dialog.gd")
var uro_login_editor_dialog : uro_login_editor_dialog_const = null

signal sign_in_submission_sent()
signal sign_in_submission_complete(result)
signal logout()

func logout():
	godot_uro_auth.token = ""
	cfg.set_value("api", "token", "")
	cfg.save(CONFIG_FILE_PATH)
	
	emit_signal("logout")

func sign_in(username_or_email : String, password : String) -> void:
	if godot_uro_auth:
		if godot_uro_auth.busy:
			return
		
		emit_signal("sign_in_submission_sent")
		var token : String = yield(godot_uro_auth.sign_in(username_or_email, password), "completed")
		
		if token != "":
			cfg.set_value("api", "token", token)
			cfg.save(CONFIG_FILE_PATH)
			emit_signal("sign_in_submission_complete", OK)
		else:
			logout()
			emit_signal("sign_in_submission_complete", FAILED)

func show_login_dialog() -> void:
	if Engine.is_editor_hint():
		if uro_login_editor_dialog:
			uro_login_editor_dialog.popup_centered()
			
func setup_editor_user_interfaces(p_editor_interface) -> void:
	if Engine.is_editor_hint():
		uro_login_editor_dialog = uro_login_editor_dialog_const.new()
		p_editor_interface.get_editor_viewport().add_child(uro_login_editor_dialog)
			
func teardown_editor_user_interfaces():
	if uro_login_editor_dialog:
		uro_login_editor_dialog.queue_free()
		
func _enter_tree():
	cfg = ConfigFile.new()
	cfg.load(CONFIG_FILE_PATH)
	
	if godot_uro_auth == null:
		godot_uro_auth = godot_uro_auth_const.new()
	godot_uro_auth.setup()
	
func _exit_tree():
	godot_uro_auth.teardown()
