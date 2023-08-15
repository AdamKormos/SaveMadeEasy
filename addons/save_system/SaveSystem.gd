extends Node

# ---------------------------------------------------------------------
# --- SaveMadeEasy - A Save System inspired by Unity's PlayerPrefs 	---
# ----------- 				Made by Ádám Kormos				-----------
# ---------------------------------------------------------------------
# The Save System is a drag-and-drop, easy to use plugin that even allows
# nested Dictionaries and Resources to be stored & accessed conveniently!
# Save data is encrypted uniquely, based on the OS id of the device, meaning
# save files cannot be shared and reused across players. (You can change this
# by modifying the open_encrypted_with_pass function's encryption key)
# A Resource is broken down to a Dictionary internally. Let's say you're saving
# a Resource under the key name of "res", and it has variables "a", "b" and "c". 
# You can access its first variable like this:
#   get_var("res:a")
# Simple, right?
#
# You can use this plugin in your Godot project as you wish. 
# Crediting me is appreciated, but not a must!
#
# If you rely on save data in an AutoLoad's _ready function, you may need to wait for the
# "loaded" signal of this AutoLoad. 


# The file path of your save data. You can freely modify this.
const file_name = "user://save_data.sav"

var current_state_dictionary := {}
var base_resource_property_names := []


signal loaded
signal saved


func _ready():
	# Locating what properties a Resource has by default, so that they do not get
	# added to a Dictionary when it is formed based on a Resource.
	var res := Resource.new()
	for property in res.get_property_list():
		base_resource_property_names.append(property.name)
	
	_load() # Load save data.
	
	# Test stuff for demonstration of the plugin:
#	set_var("Bob", TestResource.new())
#	set_var("Bob:a", TestResource.new())
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
	if(!has(key_path)):
		return
	
	if(!_is_hierarchical(key_path)): # If the key has no hierarchy, it can be simply erased.
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
	if(_is_hierarchical(key_path)):
		var key_parent = _get_variable_at_path(_get_variable_name_body(key_path))
		return key_parent != null && key_parent.has(_get_variable_name_head(key_path))
	else:
		return current_state_dictionary.has(key_path)


# Assigns a value to a key.
func set_var(key_path : String, value):
	key_path = _sanitize_key_path(key_path)
	if(_is_hierarchical(key_path)):
		if(value is Resource):
			value = _resource_to_dict(value)
		
		if(!has(key_path)): # Read :HasIncludesNull
			return
		# Hierarchical variable assignment can be achieved by tracking the key's direct parent
		# dictionary, and then getting the head of it so that we can overwrite the value. 
		var result = _get_parent_dictionary(key_path)
		var variable_name : String = _get_variable_name_head(key_path)
		result[variable_name] = value
		return
	
	if(value is Resource): # Resource, has to be nested and translated.
		current_state_dictionary[key_path] = _resource_to_dict(value)
	else: # Simple value.
		current_state_dictionary[key_path] = value


# Saves the current state.
func save():
	var f : FileAccess = FileAccess.open_encrypted_with_pass(file_name, FileAccess.WRITE, OS.get_unique_id())
	f.store_var(current_state_dictionary, true)
	emit_signal("saved")


# Returns a variable.
func get_var(key_path : String, default = null):
	key_path = _sanitize_key_path(key_path)
	var var_at_path = _get_variable_at_path(key_path)
	if(var_at_path != null):
		return var_at_path
	else:
		return default


# --------------------------------- INTERNAL FUNCTIONS ---------------------------------


# A hierarchical key has a colon separating its body and head. Read :KeyParts
func _is_hierarchical(key : String) -> bool:
	return key.find(":") != -1


# Loads the root dictionary stored in the save file.
func _load():
	var f : FileAccess = FileAccess.open_encrypted_with_pass(file_name, FileAccess.READ, OS.get_unique_id())
	if(f):
		current_state_dictionary = f.get_var()
	emit_signal("loaded")


# Sanitizes the input key path. It must be performed on every input that goes into 
# internal functions.
func _sanitize_key_path(key_path : String) -> String:
	var sanitized_string : String = ""
	key_path = key_path.lstrip(":").rstrip(":") # Remove : from beginning and end
	
	var i : int = 0
	while(i < key_path.length()):
		sanitized_string += key_path[i]
		if(key_path[i] == ":"): # Skip over multiple colons placed after each other.
			while(key_path[i + 1] == ":"): # No need to look for going OOB because the edges of the key are uncolonised (lol)
				i += 1
		i += 1
	return sanitized_string


# Returns the top element of a key path.
func _get_variable_root(key_path : String) -> String:
	key_path = _sanitize_key_path(key_path)
	if(_is_hierarchical(key_path)): 
		return key_path.substr(0, key_path.find(":"))
	else:
		return key_path


# :KeyParts
func _get_variable_name_body(key_path : String) -> String:
	key_path = _sanitize_key_path(key_path)
	if(_is_hierarchical(key_path)): 
		return key_path.substr(0, key_path.rfind(":"))
	else:
		return key_path


# :KeyParts
func _get_variable_name_head(key_path : String) -> String:
	key_path = _sanitize_key_path(key_path)
	if(_is_hierarchical(key_path)): 
		return key_path.substr(key_path.rfind(":") + 1)
	else:
		return key_path


# Retrieves a key's parent dictionary using recursion. If path is not hierarchical,
# the base is used.
func _get_parent_dictionary(key_path : String, carried_dict : Dictionary = current_state_dictionary):
	key_path = _sanitize_key_path(key_path)
	if(key_path.count(":") == 0):
		return carried_dict
	elif(key_path.count(":") == 1):
		return carried_dict[key_path.split(":")[0]]
	
	var first_name = key_path.substr(0, key_path.find(":"))
	key_path = key_path.trim_prefix(first_name + key_path[key_path.find(":")])
	return _get_parent_dictionary(key_path, carried_dict[first_name])


# Initiates recursive search for a variable.
func _get_variable_at_path(key_path : String, carried_dict : Dictionary = current_state_dictionary):
	key_path = _sanitize_key_path(key_path)
	var parent_dict = _get_parent_dictionary(key_path)
	if(parent_dict != null && parent_dict.has(_get_variable_name_head(key_path))):
		return parent_dict[_get_variable_name_head(key_path)]
	else:
		return null


# Converts a Resource to a Dictionary so that it can be stored as save data. The
# default properties of a Resource aren't included because they would just flood the dictionary.
func _resource_to_dict(resource : Resource) -> Dictionary:
	var dict := {}
	for property in resource.get_property_list():
		if(base_resource_property_names.has(property.name) || property.name.ends_with(".gd")): 
			continue
		dict[property.name] = resource.get(property.name)
	return dict
