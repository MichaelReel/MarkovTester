extends Button

func _on_InputList_input_available(available : bool):
	
	print ("TEXT CHANGED")
	set_disabled(!available)
