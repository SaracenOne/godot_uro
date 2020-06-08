extends WindowDialog
tool

var uro_login_control_const = preload("uro_login_editor_control.gd")
var uro_login_control : Control = null

func about_to_show() -> void:
	pass

func _ready() -> void:
	if connect("about_to_show", self, "about_to_show") == OK:
		printerr("Could not connect to about_to_show")
		
func _init() -> void:
	set_title("Sign in")
	set_size(Vector2(600, 800))
	
	uro_login_control = uro_login_control_const.new()
	add_child(uro_login_control)
	
	uro_login_control.set_anchors_and_margins_preset(PRESET_WIDE, PRESET_MODE_MINSIZE)
