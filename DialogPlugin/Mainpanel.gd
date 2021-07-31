tool
extends Panel

# Json structure:
# level 1) dictionary with "root", "__editor" and "uuid" (uuid = unique dialogue key)
# level 2) dictionary with "text", "next", "choices", "conditions", "signals", "name", "portrait"
# level 3):
# "text" contains a dictionary of type {"en":"blabla"}
# "signals" contains a dictionaries of type {"signalname":{"Number":"2"}} 
# "choices" contains an array with dictionaries of type {"text":"blabla","next":"uuid"}
# "conditions" contains an array with dictionaries of type {"variable":{"value":false,"operator":"equal","type":"boolean"},"next":"uuid"}
# "__editor" contains data for editor display only

var open_dialog=null
var save_dialog=null
var jsonfile:Dictionary
var dialognode=preload("res://addons/Dialogs/DialogNode.tscn")
var ConditionNode=preload("res://addons/Dialogs/ConditionNode.tscn")
var ChoiceNode=preload("res://addons/Dialogs/ChoiceNode.tscn")
var SignalNode=preload("res://addons/Dialogs/SignalNode.tscn")
var language:String="en"

onready var nodepanel=$VBox/Panel

signal jsonupdated
signal graphcleared

func _ready():

	# create open file menu
	open_dialog = FileDialog.new()
	open_dialog.window_title = "Open json"
	open_dialog.add_filter("*.json ; json files")
	open_dialog.mode = FileDialog.MODE_OPEN_FILE
	open_dialog.connect("file_selected", self, "_on_file_selected")
	add_child(open_dialog)

	# create save file menu
	save_dialog = FileDialog.new()
	save_dialog.window_title = "Save json"
	save_dialog.add_filter("*.json ; json files")
	save_dialog.mode = FileDialog.MODE_SAVE_FILE
	save_dialog.connect("file_selected", self, "_on_savefile_selected")
	add_child(save_dialog)
	
	showlang()

#func _exit_tree():
#	if open_dialog : open_dialog.queue_free()
#	if save_dialog : save_dialog.queue_free()

# -------------------------
# ---   File dialogs    ---
# -------------------------

# open file button => popup load file dialog 
func _on_Openbutton_pressed():
	open_dialog.popup_centered_ratio()

# load file and put content intoo jsonfile variable
func _on_file_selected(path):
	$VBox/HBoxMenu/Filename.text=str(path)
	cleargraph()
	jsonfile=get_json(path)
	displaynodes()

# save file button => popup save file dialog 
func _on_Savebutton_pressed():
	save_dialog.popup_centered_ratio()

# load file and put content intoo jsonfile variable
func _on_savefile_selected(path):
	$VBox/HBoxMenu/Filename.text=str(path)
	refreshjson()
	savejson(path) 

func savejson(path):
	var file = File.new()
	file.open(path, File.WRITE)
	var savefile=JSON.print(jsonfile)
	file.store_string(savefile)
	file.close()

# -------------------------
# --- New file Creation ---
# -------------------------

func Newjson():
	jsonfile.clear()
	
	# Clear editor
	cleargraph()
	$VBox/HBoxMenu/Filename.text="[unsaved]"
	
	# Create and place a root node
	var newnode:GraphNode=dialognode.instance()
	$VBox/Panel.add_child(newnode)
	newnode.title="Root"
	newnode.nodeid="root"
	newnode.get_node("VBox/KeyBox").visible=false
	newnode.resizable=false
	newnode.show_close=false
	newnode.get_node("VBox/Content").visible=false
	newnode.set_slot(0,false,0,Color.turquoise,true,0,Color.turquoise)
	newnode.offset=Vector2(50,50)

	# Create the json based on current status : refreshjson()
	refreshjson()

# ---------------------
# --- Node Creation ---
# ---------------------

func checkifroot():
	var nodesingraph:Array
	for child in $VBox/Panel.get_children():
		if child.is_in_group("dialognode"): nodesingraph.push_back(child.title)
	if not nodesingraph.has("Root"): Newjson()

func NewDialog(): # Create and place a dialogue node
	checkifroot()
	yield(get_tree().create_timer(0.2),"timeout")
	var uiid=IDGen.v4() 
	var newnode:GraphNode=dialognode.instance()
	$VBox/Panel.add_child(newnode)
	newnode.title="Dialogue"
	newnode.nodeid=uiid
	newnode.nodecontent={"en":"","fr":""}
	newnode.get_node("VBox/KeyBox/Keylabel").text=uiid
	newnode.resizable=false
	newnode.show_close=true
	newnode.set_slot(0,true,0,Color.turquoise,true,0,Color.turquoise)
	newnode.offset=$VBox/Panel.scroll_offset+Vector2(100,50)
	refreshjson()
	
func NewCondition(): # Create and place a condition node
	checkifroot()
	yield(get_tree().create_timer(0.2),"timeout")
	var uiid=IDGen.v4() 
	var newnode:GraphNode=ConditionNode.instance()
	$VBox/Panel.add_child(newnode)
	newnode.nodeid=uiid
	newnode.get_node("VBox/KeyBox/Keylabel").text=uiid
	newnode.resizable=false
	newnode.show_close=true
	newnode.set_slot(0,true,0,Color.turquoise,true,0,Color.turquoise)
	newnode.offset=$VBox/Panel.scroll_offset+Vector2(50,50)
	refreshjson()

func NewChoice(): # Create and place a choice node
	checkifroot()
	yield(get_tree().create_timer(0.2),"timeout")
	var uiid=IDGen.v4() 
	var newnode:GraphNode=ChoiceNode.instance()
	$VBox/Panel.add_child(newnode)
	newnode.nodeid=uiid
	newnode.get_node("VBox/KeyBox/Keylabel").text=uiid
	newnode.resizable=false
	newnode.show_close=true
	newnode.set_slot(0,true,0,Color.turquoise,true,0,Color.turquoise)
	newnode.offset=$VBox/Panel.scroll_offset+Vector2(50,50)
	refreshjson()

func NewSignal(): # Create and place a condition node
	checkifroot()
	yield(get_tree().create_timer(0.2),"timeout")
	var uiid=IDGen.v4() 
	var newnode:GraphNode=SignalNode.instance()
	$VBox/Panel.add_child(newnode)
	newnode.nodeid=uiid
	newnode.get_node("VBox/KeyBox/Keylabel").text=uiid
	newnode.resizable=false
	newnode.show_close=true
	newnode.set_slot(0,true,0,Color.turquoise,false,0,Color.turquoise)
	newnode.offset=$VBox/Panel.scroll_offset+Vector2(50,50)
	refreshjson()

# --------------------
# --- Json Update ----
# --------------------

func refreshjson(): # json structure : https://github.com/Levrault/LE-dialogue-editor/wiki/Json

	if $VBox/Panel.get_node(findnodewithID("root"))==null:return # no root node
	var newjson:Dictionary
	var nodecode # for "__editor" data
	
	# create "__editor" key
	var editorstructure:Dictionary
	var rootoffset= [$VBox/Panel.get_node(findnodewithID("root")).offset.x, $VBox/Panel.get_node(findnodewithID("root")).offset.y]
	editorstructure["root"]={"uuid":"root","offset":rootoffset}
	editorstructure["dialogues"]=[]
	editorstructure["signals"]=[]
	editorstructure["conditions"]=[]
	editorstructure["choices"]=[]
	
	# get each root & dialogue node and store its content
	for node in $VBox/Panel.get_children():
		if node.is_in_group("dialognode"): # only select nodes in the graphedit
			# take care of root node
			if node.title=="Root":
				var nodecontent:Dictionary
				var connectedcontent:Dictionary
				var nextnode={"next":getnext(node)}
				if nextnode.next !="": newjson["root"]={"next":getnext(node)}
				else: # check for conditions
					var connections:Array=$VBox/Panel.get_connection_list()
					for item in connections:
						if item["from"]==findnodewithID(node.nodeid):
							var attachednode:Object=$VBox/Panel.get_node(item["to"])
							if attachednode.title=="Condition":
								if nodecontent.has("conditions"):nodecontent["conditions"].push_back(getconditions(attachednode))
								else: nodecontent["conditions"]=[getconditions(attachednode)]
								nodecode={"uuid":attachednode.nodeid,"offset":getoffset(attachednode)}
								nodecode["parent"]=node.nodeid
								nodecode["data"]=attachednode.nodecontent 
								nodecode["next"]=getnext(attachednode)
								editorstructure.conditions.push_back(nodecode)
					newjson["root"]=nodecontent

			# take care of dialogue nodes and their attachements 
			if node.title=="Dialogue": 
				var nodecontent:Dictionary
				var connectedcontent:Dictionary
				# determine dialogue text and insert it into json 
				nodecontent["text"]=node.nodecontent
				nodecode={"uuid":node.nodeid,"offset":getoffset(node)}
				nodecode["parent"]=getparent(node)
				editorstructure.dialogues.push_back(nodecode)

				# determine if there are conditions / choices / signals attached
				var connections:Array=$VBox/Panel.get_connection_list()
				for item in connections:
					if item["from"]==findnodewithID(node.nodeid):
						var attachednode:Object=$VBox/Panel.get_node(item["to"])
						# get type of attached node
						var connectedtype=attachednode.title

						# create the content of the attached node
						if connectedtype=="Dialogue":
							nodecontent["next"]=getnext(node)
							nodecode={"uuid":attachednode.nodeid,"offset":getoffset(attachednode)}
							nodecode["parent"]=node.nodeid
							editorstructure.dialogues.push_back(nodecode)

						if connectedtype=="Condition":
							if nodecontent.has("conditions"):nodecontent["conditions"].push_back(getconditions(attachednode))
							else: nodecontent["conditions"]=[getconditions(attachednode)]
							nodecode={"uuid":attachednode.nodeid,"offset":getoffset(attachednode)}
							nodecode["parent"]=getparent(attachednode)
							nodecode["data"]=attachednode.nodecontent 
							nodecode["next"]=getnext(attachednode)
							editorstructure.conditions.push_back(nodecode)

						if connectedtype=="Choice":
							if nodecontent.has("choices"):nodecontent["choices"].push_back(getchoices(attachednode))
							else: nodecontent["choices"]=[getchoices(attachednode)]
							nodecode={"uuid":attachednode.nodeid,"offset":getoffset(attachednode)}
							nodecode["parent"]=getparent(attachednode)
							nodecode["text"]=attachednode.nodecontent # contains all languages
							nodecode["next"]=getnext(attachednode)
							editorstructure.choices.push_back(nodecode)

						if connectedtype=="Signal":
							nodecontent["signals"]=getsignal(attachednode)
							nodecode={"uuid":attachednode.nodeid,"offset":getoffset(attachednode)}
							nodecode["parent"]=getparent(attachednode)
							nodecode["data"]=attachednode.nodecontent 
#							nodecode["next"]=getnext(attachednode)
							editorstructure.signals.push_back(nodecode)

				newjson[node.nodeid]=nodecontent

	newjson["__editor"]=editorstructure # TO DO : track and delete doubles
	
	jsonfile=newjson
	
	emit_signal("jsonupdated")

func getconditions(node)->Dictionary: # get condition dictionary in a node
	var condition:Dictionary={}
	if node.title=="Condition":
		condition[node.variable]={"type":node.type,"operator":node.operator,"value":node.value}
		condition["next"]=getnext(node)
	return condition

func getchoices(node)->Dictionary: # get choice dictionary in a node
	var choice:Dictionary={}
	if node.title=="Choice":
		choice["text"]=node.nodecontent
		choice["next"]=getnext(node)
	return choice

func getsignal(node)->Dictionary: # get signal dictionary in a node
	var signalcode:Dictionary={}
	if node.title=="Signal":
		signalcode[node.variable]={"type":node.type,"value":node.value}
#		signalcode["next"]=getnext(node)
	return signalcode

func getoffset(node): # get attached node's offset
	var offset=$VBox/Panel.get_node(findnodewithID(node.nodeid)).offset
	var offsetarray=[offset.x,offset.y]
	return (offsetarray)

func getparent(node): # get a node's parent id
	var connections:Array=$VBox/Panel.get_connection_list()
	for item in connections:
		if item["to"]==findnodewithID(node.nodeid):
			var attachednode:Object=$VBox/Panel.get_node(item["from"])
			return attachednode.nodeid

func getnext(node): # get next node's id
	var connections:Array=$VBox/Panel.get_connection_list()
	for item in connections:
		if item["from"]==findnodewithID(node.nodeid):
			var attachednode:Object=$VBox/Panel.get_node(item["to"])
			if attachednode.title=="Dialogue":return attachednode.nodeid
			return ""

# -----------------------
# --- Change Language ---
# -----------------------

# highlight selected language
func showlang():
	if language =="fr":
		$"VBox/HBoxMenu/Lang-fr".set("custom_colors/font_color",Color.white)
		$"VBox/HBoxMenu/Lang-en".set("custom_colors/font_color",Color.darkgray)
	if language =="en":
		$"VBox/HBoxMenu/Lang-fr".set("custom_colors/font_color",Color.darkgray)
		$"VBox/HBoxMenu/Lang-en".set("custom_colors/font_color",Color.white)

func langchange(lang):
	language=lang
	showlang()
	yield(get_tree().create_timer(0.5),"timeout")
	refreshjson()
	yield(get_tree().create_timer(0.5),"timeout")
	cleargraph()
	yield(get_tree().create_timer(0.5),"timeout")
	displaynodes() 

# --------------------
# --- Node Display ---
# --------------------

func displaynodes(): # NB: jsonfile contains the whole file
	
	var jsonstruct:Dictionary=jsonfile["__editor"] # contains editor information
	
	# create root node
	var newnode:GraphNode=dialognode.instance()
	$VBox/Panel.add_child(newnode)
	newnode.title="Root"
	newnode.nodeid="root"
	newnode.get_node("VBox/KeyBox").visible=false
	newnode.resizable=false
	newnode.show_close=false
	newnode.get_node("VBox/Content").visible=false
	newnode.set_slot(0,false,0,Color.turquoise,true,0,Color.turquoise)
	var offset=Vector2(jsonstruct["root"]["offset"][0],jsonstruct["root"]["offset"][1])
	newnode.offset=offset
	
	# create dialogue nodes 
	for dialog in jsonstruct["dialogues"]:
		newnode=dialognode.instance()
		$VBox/Panel.add_child(newnode)
		var uuid=dialog["uuid"]
		newnode.nodeid=uuid
		newnode.nodecontent["fr"]=jsonfile[uuid]["text"]["fr"] # contains all languages
		newnode.nodecontent["en"]=jsonfile[uuid]["text"]["en"] # contains all languages
		newnode.title="Dialogue"
		newnode.get_node("VBox/KeyBox/Keylabel").text=uuid
		newnode.offset=Vector2(dialog["offset"][0],dialog["offset"][1])
		newnode.set_slot(0,true,0,Color.turquoise,true,0,Color.turquoise)
		newnode.get_node("VBox/Content").set_text(jsonfile[uuid]["text"][language])
		# check if there is a "next" node and display its uiid
		if jsonfile[uuid].has("next"):newnode.get_node("VBox/Nextnode").text=str(jsonfile[uuid]["next"])
		else: newnode.get_node("VBox/Nextnode").text=""

	# connect root node
	var rootnode=$VBox/Panel.get_node(findnodewithID("root"))
	if jsonfile["root"].has("next"):  
		connectroot() # connect root to dialogue node
		rootnode.get_node("VBox/Nextnode").text=jsonfile["root"]["next"]

	# create condition nodes
	for condition in jsonstruct["conditions"]:
		newnode=ConditionNode.instance()
		$VBox/Panel.add_child(newnode)
		newnode.nodeid=condition["uuid"]
		newnode.get_node("VBox/KeyBox/Keylabel").text=condition["uuid"]
		newnode.offset=Vector2(condition["offset"][0],condition["offset"][1])
		newnode.set_slot(0,true,0,Color.turquoise,true,0,Color.turquoise)
		if condition.has("data"):
			for variable in condition["data"]:
				newnode.variable = variable
				newnode.type = condition.data[variable].type
				newnode.operator = condition.data[variable].operator
				newnode.value = condition.data[variable].value
				newnode.updatenode()
		# connect to its parent node
		if condition.has("parent"):
			var nodefrom=findnodewithID(condition["parent"])
			var nodeto=findnodewithID(condition["uuid"])
			if nodefrom=="" or nodeto=="": print("nodes are not recognized: nodefrom="+str(nodefrom)+" - nodeto=" + str(nodeto))
			else:
				$VBox/Panel.connect_node(nodefrom,0,nodeto,0)
		# display next node and connect it
		if condition.has("next"):
			newnode.get_node("VBox/Nextnode").text=condition["next"]
			var nodefrom=findnodewithID(condition["uuid"])
			var nodeto=findnodewithID(condition["next"])
			if nodefrom=="" or nodeto=="": print("nodes are not recognized: nodefrom="+str(nodefrom)+" - nodeto=" + str(nodeto))
			else:
				$VBox/Panel.connect_node(nodefrom,0,nodeto,0)

	# create choice nodes
	for choice in jsonstruct["choices"]:
		newnode=ChoiceNode.instance()
		$VBox/Panel.add_child(newnode)
		newnode.nodeid=choice["uuid"]
		newnode.get_node("VBox/KeyBox/Keylabel").text=choice["uuid"]
		newnode.offset=Vector2(choice["offset"][0],choice["offset"][1])
		newnode.set_slot(0,true,0,Color.turquoise,true,0,Color.turquoise)
		newnode.nodecontent["fr"]=choice["text"]["fr"] # contains fr language
		newnode.nodecontent["en"]=choice["text"]["en"] # contains en language
		newnode.updatenode()
		# connect to its parent node
		if choice.has("parent"):
			var nodefrom=findnodewithID(choice["parent"])
			var nodeto=findnodewithID(choice["uuid"])
			if nodefrom=="" or nodeto=="": print("nodes are not recognized: nodefrom="+str(nodefrom)+" - nodeto=" + str(nodeto))
			else:
				$VBox/Panel.connect_node(nodefrom,0,nodeto,0)
		# display next node
		if choice["next"]:newnode.get_node("VBox/Nextnode").text=choice["next"]

	# create signal nodes
	for _signal in jsonstruct["signals"]:
		newnode=SignalNode.instance()
		$VBox/Panel.add_child(newnode)
		newnode.nodeid=_signal["uuid"]
		newnode.get_node("VBox/KeyBox/Keylabel").text=_signal["uuid"]
		newnode.offset=Vector2(_signal["offset"][0],_signal["offset"][1])
		newnode.set_slot(0,true,0,Color.turquoise,false,0,Color.turquoise)
		for variable in _signal["data"]:
			newnode.variable = variable
			newnode.type = _signal.data[variable].type
			newnode.value = _signal.data[variable].value
			newnode.updatenode()
		# connect to its parent node
		if _signal.has("parent"):
			var nodefrom=findnodewithID(_signal["parent"])
			var nodeto=findnodewithID(_signal["uuid"])
			if nodefrom=="" or nodeto=="": print("nodes are not recognized: nodefrom="+str(nodefrom)+" - nodeto=" + str(nodeto))
			else:
				$VBox/Panel.connect_node(nodefrom,0,nodeto,0)
		# display next node
#		if condition["next"]:newnode.get_node("VBox/Nextnode").text=condition["next"]

		# For each dialog node identify "next" nodes and connect them
	for node in jsonfile.keys():
		if node!="__editor": # only use dialogue nodes and root node
			if jsonfile[node].has("next"):
				var nodefrom=findnodewithID(node)
				var nodeto=findnodewithID(jsonfile[node]["next"])
				if nodefrom=="" or nodeto=="":print("node to connect not found")
				else:nodepanel.connect_node(nodefrom,0,nodeto,0)

		# For each dialog node identify "parent" nodes and connect them
	for node in jsonfile.keys():
		if node=="__editor":
#			if jsonfile[node].dialogues.size()>0:
			for i in jsonfile["__editor"]["dialogues"]: # dialogues contains an array
				var nodefrom=findnodewithID(i["parent"])
				var nodeto=findnodewithID(i["uuid"])
				if nodefrom=="" or nodeto=="":print("node to connect not found")
				else:nodepanel.connect_node(nodefrom,0,nodeto,0)

func connectroot():
	var nodefrom=findnodewithID("root")
	var nodeto=findnodewithID(jsonfile["root"]["next"])
	if nodefrom=="" or nodeto=="": print("nodes are not recognized: nodefrom="+str(nodefrom)+" - nodeto=" + str(nodeto))
	else:
		nodepanel.connect_node(nodefrom,0,nodeto,0)
#		$VBox/Panel.update()

func findnodewithID(ID):
	for node in $VBox/Panel.get_children():
		if node.is_in_group("dialognode"):
			if node.nodeid==ID: return node.name
	return ""

# -------------------
# --- JSON parser ---
# -------------------

func get_json(file_path: String) -> Dictionary:
	var file := File.new()

	if file.open(file_path, file.READ) != OK:
		print("get_json: file cannot been read")
		return {}

	var text_content := file.get_as_text()
	file.close()
	var data_parse = JSON.parse(text_content)
	if data_parse.error != OK:
		print("get_json: error while parsing")
		return {}
		
#	data_parse.result.erase("__editor")
	return data_parse.result

# ------------------------------
# --- Graph Editor Functions ---
# ------------------------------

func _on_Panel_connection_request(from, from_slot, to, to_slot):
	$VBox/Panel.connect_node(from, from_slot, to, to_slot)
	if $VBox/Panel.get_node(to).title=="Dialogue" or $VBox/Panel.get_node(to).title=="Signal":
		$VBox/Panel.get_node(from+"/VBox/Nextnode").text=$VBox/Panel.get_node(to).nodeid
	refreshjson()

func _on_Panel_disconnection_request(from, from_slot, to, to_slot):
	$VBox/Panel.disconnect_node(from, from_slot, to, to_slot)
	$VBox/Panel.get_node(from+"/VBox/Nextnode").text=""
	refreshjson()

func cleargraph():
	$VBox/Panel.clear_connections()
	if $VBox/Panel.get_child_count()>0: # clear all existing nodes 
		for child in $VBox/Panel.get_children():
			if child.is_in_group("dialognode"):
				child.queue_free()
		emit_signal("graphcleared")

func printjson():
	print(JSON.print(jsonfile))
#	for node in $VBox/Panel.get_children():
#		if node.is_in_group("dialognode"):
#			print (node.name)
	print("----")
