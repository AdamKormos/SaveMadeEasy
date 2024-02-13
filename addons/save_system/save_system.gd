@tool
extends Node

# ---------------------------------------------------------------------
# --- SaveMadeEasy - A Save System inspired by Unity's PlayerPrefs 	---
# ----------- 				Made by Ádám Kormos				-----------
# ---------------------------------------------------------------------
# The Save System is a drag-and-drop, easy to use plugin that even allows
# nested Dictionaries and Resources to be stored & accessed conveniently!
# Save data is encrypted based on an encryption key variable. (Note: As of
# v1.2, OS.get_unique_id isn't used anymore, as it may change upon the user
# reinstalling their OS. :UniqueIDDeprecated)
# A Resource is broken down to a Dictionary internally. Let's say you're saving
# a Resource under the key name of "res", and it has variables "a", "b" and "c". 
# You can access its first variable like this:
#   get_var("res:a")
# Simple, right?
#
# I'd like to thank Loppansson for the awesome setup of the test environment and the naming
# conventions cleanup, and Nevereven for pointing out a handful of things that can make
# the plugin more diverse. :) My gratitude goes to all of you using the plugin and helping me 
# make it better by reporting arising issues!
#
# You can use this plugin in your Godot project as you wish. 
# Crediting me is appreciated, but not a must!
#
# If you rely on save data in an AutoLoad's _ready function, you may need to wait for the
# "loaded" signal of this AutoLoad. 


# The default file path of your save data. You can freely modify this.
const default_file_path : String = "user://save_data.sav"
const encryption_key : String = "abcdefg1234567"
const use_encryption : bool = false
# Typecasting the keys manually may increase loading times, so if you feel like
# this feature is irrelevant in your project, set this to false.
# You typically only need this enabled if you are using dictionary keys
# that aren't Strings.
const perform_typecast_on_dictionary_keys : bool = true

@export var current_state_dictionary := {}

# I wished to create a separate Dock for the controls, but connecting 
# clear_save_data_on_start to a dock control was very problematic and
# never seemed to work as intended, so I had to put these as exports. Unfortunate :(
## Set this to true to clear every save data you have, when starting the game.
@export var clear_save_data_on_start : bool = false
## Set this to true to clear every save data you have. Automatically resets to false
## afterwards
@export var clear_all_data : bool = false : set = set_clear_data
func set_clear_data(value):
	if value:
		delete_all()
		can_save_empty_in_editor_with_permission = true
		save()
		clear_all_data = false

# This variable is created because if you try to disable the plugin,
# due to this script's exit_tree, the file gets saved, but it will be
# empty (= current_state_dictionary is empty)! I'm assuming the script
# gets deloaded and that's why, but it still doesn't completely click. 
# Anyway, we *do* want to clear our save file with the exported 
# variable though, so this permission is given in that case. 
# :EditorEmptySavingPermission
var can_save_empty_in_editor_with_permission : bool = false

var base_resource_property_names := []

signal loaded
signal saved


func _ready():
	# Locating what properties a Resource has by default, so that they do not get
	# added to a Dictionary when it is formed based on a Resource.
	var res := Resource.new()
	for property in res.get_property_list():
		base_resource_property_names.append(property.name)
	
	# If we boot the game and want to erase data on start -
	if !Engine.is_editor_hint() and clear_save_data_on_start:
		delete_all()
		save()
	else:
		_load() # Load save data.
	
# Test stuff for demonstration of the plugin --------------------------
#	
#	print(get_var("Bob"))
#	set_var("Bob", TestResource.new())
#	set_var("Bob:e", Vector2(4, 9))
#	
	# Saving arrays with resources and nested resources:
#	var my_arr := [TestSubresource.new(), TestSubresource.new()]
#	my_arr[0].c[0].b = 66
#	set_var("Bob:f", my_arr)
#	print(get_var("Bob:f")[0].c[0].b)
#	save()
#	
	# Saving primitive types, dictionaries and non-resource arrays:
#	set_var("Bob:a:b", 3)
#	set_var("Bob:a:c:d", {"abcf" : 5})
#	print(has("Bob"))
#	set_var("Bob:a:b", null)
#	set_var("Bob:a:c", TestResource.new())
#	set_var("Bob:a:c:c", 10)
#	delete("Bob:a:c:d")
#	print(get_var("Bob"))
#	print(_sanitize_key_path("Bob:a:c:d"))
#	print(_sanitize_key_path(":::::Bob::::a:c:::d::"))
#	print(has("Z"))


func _exit_tree():
	save() # Save on exit.


# Deletes every existing save data.
func delete_all():
	current_state_dictionary.clear()


# Deletes a specific key's information.
func delete(key_path : String):
	if not has(key_path):
		return
	
	if not _is_hierarchical(key_path): # If the key has no hierarchy, it can be simply erased.
		current_state_dictionary.erase(key_path)
		return
	
	# In case of a hierarchical key, we need to break it down to body and head,
	# where body means every part of the key until the last colon and the head
	# is the rest of it, at the bottom of the hierarchy, as it's inside the
	# body's dictionary key set.
	# A path is a certain variable's identifier with which you can access it. 
	# :KeyParts 
	var body = _get_variable_name_body(key_path)
	var head = _get_variable_name_head(key_path)
	_get_variable_at_path(body).erase(head)


# Returns whether a key exists or not. A variable can exist and be null, 
# so you can get a null returned, because the condition only checks if the key's 
# parent is null. It's made this way because despite the value being null, the variable
# itself is still around and is in the save info tree. Returning false in case it's null
# would make it impossible to assign anything to it once it is set to null!
# :HasIncludesNull
# (Note: Might consider making a function called has_and_valid)
func has(key_path : String) -> bool:
	if _is_hierarchical(key_path):
		var variable_head = _get_variable_name_head(key_path)
		var key_parent = _get_variable_at_path(_get_variable_name_body(key_path))
		if key_parent == null:
			return false
		
		var valid_as_object : bool = (key_parent is Object and variable_head in key_parent)
		var valid_as_dict : bool = (not key_parent is Object and key_parent.has(variable_head))
		return key_parent != null and (valid_as_object or valid_as_dict)
	else:
		return current_state_dictionary.has(key_path)


# Assigns a value to a key.
func set_var(key_path : String, value):
	key_path = _sanitize_key_path(key_path)
	if _is_hierarchical(key_path):
		if value is Resource:
			value = _resource_to_dict(value)
		elif value is Array:
			value = _parse_array(value)
		elif value is Dictionary:
			value = _typecast_dictionary_keys(value)
		
		if not has(key_path): # Read :HasIncludesNull
			return
		
		# Hierarchical variable assignment can be achieved by tracking the key's direct parent
		# dictionary, and then getting the head of it so that we can overwrite the value. 
		var result = _get_parent_dictionary(key_path)
		var variable_name : String = _get_variable_name_head(key_path)
		result[variable_name] = value
		return
	
	if value is Resource: # Resource, has to be nested and translated.
		current_state_dictionary[key_path] = _resource_to_dict(value)
	else: # Simple value.
		current_state_dictionary[key_path] = value


# Saves the current state. You may use a different file path for multi-slot saving.
func save(file_path : String = default_file_path):
	# :EditorEmptySavingPermission
	if current_state_dictionary.is_empty() and Engine.is_editor_hint():
		if !can_save_empty_in_editor_with_permission:
			return
	
	var file : FileAccess
	if use_encryption:
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, encryption_key)
	else:
		file = FileAccess.open(file_path, FileAccess.WRITE)
	
	# We need to call typecasting when saving too, so that Resources that
	# weren't manually added with set_var but are parts of an object that
	# were, can be broken down to Dictionaries.
	current_state_dictionary = _typecast_dictionary_keys(current_state_dictionary)
	file.store_string(JSON.stringify(current_state_dictionary, "\t"))
	can_save_empty_in_editor_with_permission = false
	emit_signal("saved")


# Returns a variable.
func get_var(key_path : String, default = null):
	key_path = _sanitize_key_path(key_path)
	var var_at_path = _get_variable_at_path(key_path)
	if var_at_path != null:
		return var_at_path
	else:
		return default


# --------------------------------- INTERNAL FUNCTIONS ---------------------------------


# Performs a recursive look-up on its elements to "unpack" potential resources in arrays,
# and return an array of data that only holds primitives and dictionaries.
func _parse_array(array : Array) -> Array:
	var result := []
	for element in array:
		if element is Resource:
			result.append(_resource_to_dict(element))
		elif element is Array:
			result.append(_parse_array(element))
		else:
			result.append(element)
	return result


# A hierarchical key has a colon separating its body and head. Read :KeyParts
func _is_hierarchical(key : String) -> bool:
	return key.find(":") != -1


# Loads the root dictionary stored in the save file. You may use a different
# file path for multi-slot saving.
func _load(file_path : String = default_file_path):
	var file : FileAccess
	if use_encryption:
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, encryption_key)
	else:
		file = FileAccess.open(file_path, FileAccess.READ)
	
	if file:
		current_state_dictionary = JSON.parse_string(file.get_as_text())
		if perform_typecast_on_dictionary_keys:
			current_state_dictionary = _typecast_dictionary_keys(current_state_dictionary)
	
	emit_signal("loaded")


# By default, JSON parsing doesn't typecast the keys of a Dictionary, which can be
# an issue. So when the file is loaded, a manual typecast is performed on Dictionary
# keys to ensure you can access them as intended, without having to stringify all
# your Dictionary keys.
func _typecast_dictionary_keys(input_dict : Dictionary) -> Dictionary:
	var typed_dict := {}
	for key in input_dict.keys():
		var value = input_dict[key]
		
		var typed_key = _get_typed_key(key)
		# If our key's value is a Dictionary, its keys must go through recursive 
		# typecasting, and be assigned in that form to our result dictionary's key. 
		if value is Dictionary:
			typed_dict[typed_key] = _typecast_dictionary_keys(value)
		else:
			# If the value is an Array, we have to account for underlying Dictionaries
			# among its elements and recursively typecast them.
			if value is Array:
				for i in range(value.size()):
					if value[i] is Dictionary:
						value[i] = _typecast_dictionary_keys(value[i])
			typed_dict[typed_key] = value
	return typed_dict


# Typecasts a key value and returns it. We cannot simply use str_to_var in every case,
# as for Strings (text value - which is also what we read out of files) that cannot 
# be typecasted, it returns null, and it doesn't parse Vectors properly!
# :StrToVarIsNullOnString
func _get_typed_key(key):
	# Since str_to_var lacks converting the sheer coordinate values into a Vector 
	# automatically, we have to add some conditions to predict whether the key is 
	# a Vector value or not.
	if key is String and key.begins_with("(") and key.ends_with(")") and key.find(",") != -1:
		var comma_count : int = key.count(",")
		# To better understand this parsing, imagine we store a 2D Vector of
		# (2, 5). "(2, 5)" is what's being stored in the file, and we have one comma,
		# so the result parameter of str_to_var is "Vector2(2, 5)", which the 
		# function can conveniently work with.
		var supposed_vector_value = str_to_var("Vector" + str(comma_count + 1) + key)
		if supposed_vector_value != null:
			return supposed_vector_value
		# Here we can get around the :StrToVarIsNullOnString limitation, as we
		# already know our key is a String, given the branch entry conditions.
		else:
			return key
	# We cannot typecast Resource keys, because when we load them back,
	# there is no reliable way to know what type of Resource it was,
	# so the recommended approach is to call _resource_to_dict on your
	# resource before using it as a key, if the Dictionary is in an object
	# you're saving.
	# TODO: Perhaps we could add the Resource's resource_path as an additional
	# key when we convert it to a Dictionary, and immediately convert the
	# Dictionary back to a Resource on load? We'd still need a manual
	# lookup method though, because Godot compares Resources based on their
	# unique IDs, not based on their variables matching, of course.
	# :NoResourceKeyTypecast
#	elif key is Resource:
#		return _typecast_dictionary_keys(_resource_to_dict(key))
	# :StrToVarIsNullOnString
	elif (key is String and str_to_var(key) == null) or (not key is String):
		return key
	else:
		return str_to_var(key)


# Sanitizes the input key path. It must be performed on every input that goes into 
# internal functions.
func _sanitize_key_path(key_path : String) -> String:
	var sanitized_string : String = ""
	key_path = key_path.lstrip(":").rstrip(":") # Remove : from beginning and end
	
	var i : int = 0
	while i < key_path.length():
		sanitized_string += key_path[i]
		if key_path[i] == ":": # Skip over multiple colons placed after each other.
			while(key_path[i + 1] == ":"): # No need to look for going OOB because the edges of the key are uncolonised (lol)
				i += 1
		i += 1
	return sanitized_string


# Returns the top element of a key path.
func _get_variable_root(key_path : String) -> String:
	key_path = _sanitize_key_path(key_path)
	if _is_hierarchical(key_path): 
		return key_path.substr(0, key_path.find(":"))
	else:
		return key_path


# :KeyParts
func _get_variable_name_body(key_path : String) -> String:
	key_path = _sanitize_key_path(key_path)
	if _is_hierarchical(key_path): 
		return key_path.substr(0, key_path.rfind(":"))
	else:
		return key_path


# :KeyParts
func _get_variable_name_head(key_path : String) -> String:
	key_path = _sanitize_key_path(key_path)
	if _is_hierarchical(key_path): 
		return key_path.substr(key_path.rfind(":") + 1)
	else:
		return key_path


# Retrieves a key's parent dictionary using recursion. If path is not hierarchical,
# the base is used.
func _get_parent_dictionary(key_path : String, carried_dict : Dictionary = current_state_dictionary):
	key_path = _sanitize_key_path(key_path)
	var depth_count = key_path.count(":")
	if depth_count == 0:
		return carried_dict
	elif depth_count == 1:
		return carried_dict[key_path.split(":")[0]]
	
	var first_splitter_index = key_path.find(":")
	var first_name = key_path.substr(0, first_splitter_index)
	key_path = key_path.trim_prefix(first_name + key_path[first_splitter_index])
	
	if carried_dict[first_name] is Object:
		carried_dict[first_name] = _resource_to_dict(carried_dict[first_name])
	return _get_parent_dictionary(key_path, carried_dict[first_name])


# Initiates recursive search for a variable.
func _get_variable_at_path(key_path : String, carried_dict : Dictionary = current_state_dictionary):
	key_path = _sanitize_key_path(key_path)
	var parent_dict = _get_parent_dictionary(key_path)
	if parent_dict != null:
		var variable_head = _get_variable_name_head(key_path)
		if not parent_dict is Object and parent_dict.has(variable_head):
			return parent_dict[variable_head]
		elif parent_dict is Object and variable_head in parent_dict:
			return parent_dict.get(variable_head)
		else:
			return null
	else:
		return null


# Converts a Resource to a Dictionary so that it can be stored as save data. The
# default properties of a Resource aren't included because they would just flood the dictionary.
func _resource_to_dict(resource : Resource) -> Dictionary:
	var dict := {}
	for property in resource.get_property_list():
		if base_resource_property_names.has(property.name) or property.name.ends_with(".gd"): 
			continue
		
		var property_value = resource.get(property.name)
		# Arrays have to be interpreted recursively, see _parse_array function description.
		if property_value is Array:
			dict[property.name] = _parse_array(property_value)
		else:
			dict[property.name] = property_value
	return dict


# Converts a Dictionary's information into a Resource. We need a resource as the
# 2nd parameter so that the instance has the given fields our Dictionary assigns.
# The simplest approach is using a new instance of the Resource type in question
# (e.g TestResource.new())
func _dict_to_resource(dict : Dictionary, target_resource : Resource) -> Resource:
	for i in range(dict.size()):
		var key = dict.keys()[i]
		var value = dict.values()[i]
		target_resource.set(key, value)
	return target_resource
