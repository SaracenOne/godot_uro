extends EditorPlugin
tool

const uro_logo_const = preload("uro_logo.png")
var editor_interface: EditorInterface = null
var button: Button = null


func get_name() -> String:
	return "GodotUro"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()

	add_autoload_singleton("GodotUro", "res://addons/godot_uro/godot_uro.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GodotUro")
