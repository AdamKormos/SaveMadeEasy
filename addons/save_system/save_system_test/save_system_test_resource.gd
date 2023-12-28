class_name SaveSystemTestResource
extends Resource


var id : int
var name : String
var resource : Resource
var resource_arr := [SaveSystemTestSubresource.new(), SaveSystemTestSubresource.new()]
var data : Dictionary = {
	"position" : 0,
	"tags" : {
		"primary_tag" : "",
		"secondary_tag" : ""
	}
}

