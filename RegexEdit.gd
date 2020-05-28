extends TextEdit

signal regex_updated(text)

func _on_ChainList_regex_selected(regex : String):
	print ("Regex selected: " + str(regex))
	text = regex
	set_readonly(true)

func _on_ChainList_regex_required(custom_regex):
	print ("Custom regex required: " + str(custom_regex))
	if custom_regex != null:
		text = custom_regex
	set_readonly(false)
	emit_signal("text_changed")

func _on_RegexEdit_text_changed():
	emit_signal("regex_updated", text)
