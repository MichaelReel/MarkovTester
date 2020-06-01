extends Button

func _on_ChainList_table_created(has_entries : bool):
	set_disabled(not has_entries)
