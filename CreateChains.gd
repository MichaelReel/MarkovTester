extends ItemList

signal created_random_strings(text)
signal regex_selected(regex)
signal regex_required(regex)

const ID_MODE_MAP : Array = [
	"1letter",
	"2letter",
	"3letter",
	"cvc",
	"consonants",
	"custom",
]

const MODE_TO_REGEX_MAP : Dictionary = {
	"1letter"    : ".{1}",
	"2letter"    : ".{2}",
	"3letter"    : ".{3}",
	"cvc"        : "[bcdfghjklmnpqrstvwxyz][aeiou]*[bcdfghjklmnpqrstvwxyz]",
	"consonants" : "[aeiou]*[bcdfghjklmnpqrstvwxyz]{1}",
	"custom"     : null,
}

var table : MarkovTable
var mode : String = ID_MODE_MAP[2]

class MarkovTable:
	
	var links : Dictionary
	var totals : Dictionary
	var headers : Array
	var callback : FuncRef
	
	func _init(input : String, add_item_callback : FuncRef, split : String = '1letter'):
		"""
		Create the markov chain table.
		By default the table will be empty.
		When input is given, split will determine the technique
		used to split words into markov states.
		split = '1letter' : 1 letter equals 1 state.
		split = '2letter' : Every 2 letters equals 1 state, 
							last state may be a single letter.
		split = '3letter' : Every 3 letters equals 1 state, 
							last state may be a single letter
							or 2 letters. This can create a 
							very large table.
		split = 'consonants' : Each split ends with a consonant
		split = 'cvc' : Each link ends up in the form consonant-vowel-consonant
		"""
		links = {}
		totals = {}
		headers = []
		callback = add_item_callback
		read_input_stream(input, split)

	func read_input_stream(input : String, split : String):
		for line in input.split("\n"):
			line = line.strip_edges().to_lower()
			if not line.empty():
				insert_word(line, split)

	func insert_word(word : String, split : String):
		split_by_regex(word, split)

	func split_by_regex(word_in : String, regex : String):
		var filter := RegEx.new()
		var err = filter.compile(regex)
		if err:
			callback.call_func("\t", "Regex error. Exp: " + regex + ", Err-code: " + err)
			return
		var word : Array = filter.search_all(word_in)
		if (word.empty()):
			# Somethings might not fit the rules
			add_link(' ', word_in)
			add_link(word_in, ' ')
			return
		add_link(' ', word[0].get_string())
		add_link(word[-1].get_string(), ' ')
		for i in range(0, word.size() - 1):
			var a : String = word[i].get_string()
			var b : String = word[i + 1].get_string()
			add_link(a, b)

	func add_link(start : String, end : String):
		if not headers.has(start):
			headers.append(start)
		if not headers.has(end):
			headers.append(end)
		if not links.has(start):
			links[start] = {}
			totals[start] = 0
		if not links[start].has(end):
			links[start][end] = 0
			if callback.is_valid():
				callback.call_func(start, end)
		links[start][end] += 1
		totals[start] += 1

	func make_random_word() -> String:
		# Use space to find a starting state:
		var state := get_random_linked_state(' ')
		var word := state
		while state != ' ':
			state = get_random_linked_state(state)
			word += state
		return word

	func get_random_linked_state(state : String) -> String:
		var next_states : Array = links[state].keys()
		var state_ind := randi() % next_states.size()
		return next_states[state_ind]

func _on_InputList_chain_input(text : String):
	self.clear()
	table = MarkovTable.new(text, funcref(self, "new_item_added"), MODE_TO_REGEX_MAP[mode])
	sort_items_by_text()

func new_item_added(start : String, end : String):
	add_item("'" + start + "' -> '" + end + "'")

func _on_RandomButton_pressed():
	var text := ""
	seed(OS.get_system_time_msecs())
	for _i in range (0, 100):
		text += table.make_random_word() + "\n"
	emit_signal("created_random_strings", text)

func _on_SplitModeButton_item_selected(id : int):
	mode = ID_MODE_MAP[id]
	print ("id " + str(id) + " for mode " + mode)
	if mode == "custom":
		emit_signal("regex_required", MODE_TO_REGEX_MAP[mode])
	else:
		emit_signal("regex_selected", MODE_TO_REGEX_MAP[mode])

func _on_RegexEdit_regex_updated(text : String):
	print ("updating regex")
	MODE_TO_REGEX_MAP["custom"] = text
