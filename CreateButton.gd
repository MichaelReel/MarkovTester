extends Button

func _on_InputList_input_available(available : bool):
	set_disabled(!available)
