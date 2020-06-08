extends EditorPlugin
tool

const uro_logo_const = preload("uro_logo.png")
var editor_interface : EditorInterface = null
var button : Button = null

func _show_uro_menu() -> void:
	GodotUro.show_login_dialog()

func get_name() -> String:
	return "GodotUro"

func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	
	add_autoload_singleton("GodotUro", "res://addons/godot_uro/godot_uro.gd")

	button = Button.new()
	button.set_text("Uro")
	button.set_button_icon(uro_logo_const)
	button.set_tooltip("Access the Uro Menu.")
	button.set_flat(true)
	button.connect("pressed", self, "_show_uro_menu")
	
	add_control_to_container(CONTAINER_TOOLBAR, button)
	
	GodotUro.setup_editor_user_interfaces(editor_interface)

func _exit_tree() -> void:
	GodotUro.teardown_editor_user_interfaces()
	
	remove_autoload_singleton("GodotUro")
	button.free()
