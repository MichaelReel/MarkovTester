extends TextEdit

onready var popup := $FileDialog

func _on_Button_pressed():
	popup.popup()

func _on_FileDialog_file_selected(path : String):
	print ("file selected: " + path)
	var file = File.new()
	file.open(path, File.READ)
	text = file.get_as_text()
	file.close()
