extends ItemList

signal created_random_strings

var table : MarkovTable

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
		match split:
			"1letter":
				split_letter(word)
			"2letter":
				split_multiletter(word, 2)
			"3letter":
				split_multiletter(word, 3)
			"consonants":
				split_by_regex(word, "([aeiou]*[bcdfghjklmnpqrstvwxyz]{1})")
			"cvc":
				split_by_regex(word, "([bcdfghjklmnpqrstvwxyz][aeiou]*[bcdfghjklmnpqrstvwxyz])")
			_:
				split_by_regex(word, split)

	func split_letter(word : String):
		add_link(' ', word[0])
		add_link(word[-1], ' ')
		for i in range(0, word.length() - 1):
			var a := word[i]
			var b := word[i + 1]
			add_link(a, b)
	
	func split_multiletter(word_in : String, n : int):
		var word : Array = []
		for i in range(0, word_in.length(), n):
			word.append(word_in.substr(i, n))
		add_link(' ', word[0])
		add_link(word[-1], ' ')
		for i in range(0, word.size() - 1):
			var a : String = word[i]
			var b : String = word[i + 1]
			add_link(a, b)

	func split_by_regex(word_in : String, regex : String):
		var filter := RegEx.new()
		var err = filter.compile(regex)
		if err:
			callback.call_func("\t", "Regex error. Exp: " + regex + ", Err-code: " + err)
			return
		var word : Array = filter.search_all(word_in)
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
	table = MarkovTable.new(text, funcref(self, "new_item_added"), "3letter")
	sort_items_by_text()

func new_item_added(start : String, end : String):
	add_item("'" + start + "' -> '" + end + "'")

func _on_RandomButton_pressed():
	var text := ""
	seed(OS.get_system_time_msecs())
	for _i in range (0, 100):
		text += table.make_random_word() + "\n"
	emit_signal("created_random_strings", text)
