extends Control
tool

const MARGIN_SIZE = 32

var vbox_container : VBoxContainer = null

var sign_in_label : Label = null

var sign_in_vbox_container : VBoxContainer = null
var email_or_username_label : Label = null
var email_or_username_lineedit : LineEdit = null
var password_label : Label = null
var password_lineedit : LineEdit = null

var submit_button : Button = null
var result_label : Label = null

func sign_in_submission_sent() -> void:
	email_or_username_lineedit.editable = false
	password_lineedit.editable = false
	
	submit_button.disabled = true
	
func sign_in_submission_complete(p_result) -> void:
	email_or_username_lineedit.editable = true
	password_lineedit.editable = true
	
	submit_button.disabled = false
	
	if p_result == FAILED:
		password_lineedit.text = ""
		result_label.set_text("Login credentials invalid...")
	else:
		result_label.set_text("")

func submit_button_pressed() -> void:
	var email_or_username : String = email_or_username_lineedit.text
	var password : String = password_lineedit.text
	
	GodotUro.sign_in(email_or_username, password)
	
func _init() -> void:
	vbox_container = VBoxContainer.new()
	vbox_container.alignment = VBoxContainer.ALIGN_BEGIN
	
	add_child(vbox_container)
	
	sign_in_label = Label.new()
	sign_in_label.set_text("")
	sign_in_label.align = Label.ALIGN_CENTER
	vbox_container.add_child(sign_in_label)
	
	sign_in_vbox_container = VBoxContainer.new()
	sign_in_vbox_container.alignment = VBoxContainer.ALIGN_CENTER
	sign_in_vbox_container.size_flags_vertical = SIZE_EXPAND_FILL
	
	email_or_username_label = Label.new()
	email_or_username_label.set_text("Email/Username")
	
	email_or_username_lineedit = LineEdit.new()
	
	password_label = Label.new()
	password_label.set_text("Password")
	
	password_lineedit = LineEdit.new()
	password_lineedit.secret = true
	
	sign_in_vbox_container.add_child(email_or_username_label)
	sign_in_vbox_container.add_child(email_or_username_lineedit)
	sign_in_vbox_container.add_child(password_label)
	sign_in_vbox_container.add_child(password_lineedit)
	
	vbox_container.add_child(sign_in_vbox_container)
	
	submit_button = Button.new()
	submit_button.set_text("Submit")
	submit_button.connect("pressed", self, "submit_button_pressed")
	
	vbox_container.add_child(submit_button)

	result_label = Label.new()
	result_label.set_text("")
	result_label.align = HALIGN_CENTER
	vbox_container.add_child(result_label)

	vbox_container.set_anchors_and_margins_preset(PRESET_WIDE, PRESET_MODE_MINSIZE, 0)
	vbox_container.margin_top = 0
	vbox_container.margin_left = MARGIN_SIZE
	vbox_container.margin_bottom = -MARGIN_SIZE
	vbox_container.margin_right = -MARGIN_SIZE
	
	GodotUro.connect("sign_in_submission_sent", self, "sign_in_submission_sent")
	GodotUro.connect("sign_in_submission_complete", self, "sign_in_submission_complete")
