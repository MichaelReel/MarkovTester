extends TextEdit

onready var popup := $FileDialog

signal chain_input

func _on_Button_Open_pressed():
	popup.popup()

func _on_FileDialog_file_selected(path : String):
	print ("file selected: " + path)
	var file = File.new()
	file.open(path, File.READ)
	text = file.get_as_text()
	file.close()

func _on_Button_Create_pressed():
	emit_signal("chain_input", text)
