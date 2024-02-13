extends Node

# Scipt used to test the save system. Ctrl+Drag script into the scene and the 
# current scene twice to test.


var _tests := []
var _number_of_test_done : int = 0
var _longest_input_len : int = 0


func _ready():
	await get_tree().create_timer(0.2).timeout
	var first_load = not SaveSystem.has("test_resource")
	
	if first_load:
		var res := SaveSystemTestResource.new()
		res.id = 2
		SaveSystem.set_var("test_resource", res)
		# Notice how we get_var the test_resource and separately assign its "resource" variable,
		# without a set_var call. Later in the tests, you can see the reference makes it so
		# when you get/set_var "test_resource:resource", the code will refer to what 
		# we've just set here.
		SaveSystem.get_var("test_resource").resource = SaveSystemTestResource.new()
		SaveSystem.set_var("test_resource:resource:id", 1)
		SaveSystem.set_var("test_resource:resource:data:tags", {
			"primary_tag" : "resource",
			"secondary_tag" : "test_resource"
		})
		SaveSystem.set_var("test_resource:resource:name", null)
		SaveSystem.set_var("test_resource:resource:resource", SaveSystemTestResource.new())
		SaveSystem.set_var("test_resource:resource:resource:id", 2)
		SaveSystem.get_var("test_resource:resource_arr")[0].id = 44
		SaveSystem.delete("test_resource:resource:resource:data")
	
	var test_resource = SaveSystem.get_var("test_resource", SaveSystemTestResource.new())
	_test('test_resource.id', test_resource.id, 2)
	_test('test_resource.resource.id', test_resource.resource.id, 1)
	# Example: You don't have to manually set_var test_resource:name!
	_test('test_resource.name', test_resource.name, 'abc')
	_test('test_resource.data["position"]', test_resource.data["position"], 0)
	_test('test_resource.data["tags"]', test_resource.data["tags"], {"primary_tag": "", "secondary_tag": ""})
	_test('SaveSystem.has("test_resource")', SaveSystem.has("test_resource"), true)
	_test('SaveSystem.has("test_resource:id")', SaveSystem.has("test_resource:id"), true)
	_test('SaveSystem.has("test_resource:no")', SaveSystem.has("test_resource:no"), false)
	_test('SaveSystem.has("non_existent_var")', SaveSystem.has("non_existent_var"), false)
	_test(
			'SaveSystem._sanitize_key_path(":::::test_resource::::a:c:::d::")', 
			SaveSystem._sanitize_key_path(":::::test_resource::::a:c:::d::"),
			'test_resource:a:c:d'
	)
	_test(
		'test_resource.resource_arr[0].id',
		test_resource.resource_arr[0].id,
		44
	)
	
	if SaveSystem.perform_typecast_on_dictionary_keys:
		_test(
			'test_resource.non_string_key_dictionary[123]',
			test_resource.non_string_key_dictionary[123],
			"abc"
		)
		_test(
			'test_resource.non_string_key_dictionary[true]',
			test_resource.non_string_key_dictionary[true],
			Vector2.ONE
		)
		_test(
			'test_resource.non_string_key_dictionary[Vector2(1, 1)][0]["name"]',
			test_resource.non_string_key_dictionary[Vector2(1, 1)][0]["name"],
			"Bob"
		)
		_test(
			'test_resource.non_string_key_dictionary[Vector2(1, 1)][0][false]',
			test_resource.non_string_key_dictionary[Vector2(1, 1)][0][false],
			"False :("
		)
		# Experimental test, this won't work with the current plugin yet,
		# if the positions Dictionary has a Resource as the key.
		# :ExperimentalResKey
#		_test(
#			'test_resource.positions[SaveSystem._resource_to_dict(SaveSystemTestSubresource.new())]',
#			test_resource.positions[SaveSystem._resource_to_dict(SaveSystemTestSubresource.new())],
#			Vector2(2, 3)
#		)
	
	_render_tests()
	
	# Quit after printing results
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


func _test(input : String, result, expected_result):
	var success_state = ""
	if str(result) == str(expected_result):
		success_state = "OK"
	else:
		success_state = "ER"
	
	_tests.append({
		"input" : input,
		"result" : str(result),
		"expected_result" : str(expected_result),
		"success_state" : success_state
	})
	
	_longest_input_len = max(len(input), _longest_input_len)
	_number_of_test_done += 1


func _render_tests():
	print("State  Input")
	var number_of_ok : int = 0
	var _test_rendered : int = 0
	for test in _tests:
		if test["success_state"] == "ER":
			print("ER     " + test["input"])
			print(" L____ Expected: ", test["expected_result"])
			print(" L____ Recieved: ", test["result"])
			if not _test_rendered + 1 == _number_of_test_done:
				print(" |")
		else:
			print("OK     " + test["input"])
			number_of_ok += 1
		_test_rendered += 1
	print()
	print("OVER ALL: [",  number_of_ok, "/", _number_of_test_done, "] OK")
