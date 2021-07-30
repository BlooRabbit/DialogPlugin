tool
extends GraphNode
signal nodechanged

var nodeid:String="" # stores unique ID of node
var nodecontent:Dictionary={"en":"", "fr":""} # stores content of node in all languages
onready var Editor:Object= get_parent().get_parent().get_parent()

#func _ready():
#	connect("nodechanged",Editor, "refreshjson")

func _close_request():
	var connections:Array=Editor.get_node("VBox/Panel").get_connection_list()
	for item in connections:
		if item["to"]==self.name or item["from"]==self.name:
			Editor.get_node("VBox/Panel").disconnect_node(item["from"],0,item["to"],0)
	queue_free()

func _on_resize_request(new_minsize):
	rect_size=new_minsize

func _on_Content_text_changed():
	nodecontent[Editor.language]=$VBox/Content.text 

#	emit_signal("nodechanged") # refresh json file

func _on_Singlenode_clicked():
	print(nodecontent)
