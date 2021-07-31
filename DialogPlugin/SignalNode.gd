tool
extends GraphNode
signal nodechanged

var nodeid:String="" # stores unique ID of node
var nodecontent:Dictionary={} # stores content of node in all languages
var variable=""
var type="string"
var value=""
onready var Editor:Object= get_parent().get_parent().get_parent()

func _ready():
	updatenode()
	$VBox/HBoxType/Content._select_int(0)
	$VBox/HBoxType/Content.text="string"
#	connect("nodechanged",Editor, "refreshjson")

func _close_request():
	var connections:Array=Editor.get_node("VBox/Panel").get_connection_list()
	for item in connections:
		if item["to"]==self.name or item["from"]==self.name:
			Editor.get_node("VBox/Panel").disconnect_node(item["from"],0,item["to"],0)
	queue_free()

func _on_resize_request(new_minsize):
	rect_size=new_minsize

func _on_values_changed(): # refresh the nodecontent variable
	nodecontent.clear()
	variable =$VBox/HBoxVar/Content.text
	type=$VBox/HBoxType/Content.text
	value=$VBox/HBoxValue/Content.text
	nodecontent[variable]={"type":type,"value":value}
	
#	emit_signal("nodechanged") # refresh json file

func updatenode():
	$VBox/HBoxVar/Content.text=variable
	$VBox/HBoxType/Content.text=type
	$VBox/HBoxValue/Content.text=value
	_on_values_changed() # rebuild nodecontent variable

func _on_Singlenode_clicked():
	print(nodecontent)
	print(selected)
	
func _on_type_selected(index):
	if index==0:type="string"
	if index==1:type="number"
	update()
