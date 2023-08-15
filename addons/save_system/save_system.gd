@tool
extends EditorPlugin


const AUTOLOAD_NAME = "SaveSystem"


func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/save_system/SaveSystem.gd")


func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
