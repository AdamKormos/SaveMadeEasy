class_name SaveSystemTestResource
extends Resource


var id : int
var name : String = "abc"
var resource : Resource
var resource_arr := [SaveSystemTestSubresource.new(), SaveSystemTestSubresource.new()]
var data : Dictionary = {
	"position" : 0,
	"tags" : {
		"primary_tag" : "",
		"secondary_tag" : ""
	}
}

var non_string_key_dictionary : Dictionary = {
	123 : "abc",
	true : Vector2.ONE,
	Vector2(-1, 0.5) : "aaaaa",
	Vector2(1, 1) : [{"name" : "Bob", "cast" : "Warrior", "mana" : 5, false : "False :("}, 235]
}

# :ExperimentalResKey
var positions : Dictionary = {
	SaveSystemTestSubresource.new() : Vector2(2, 3)
}
