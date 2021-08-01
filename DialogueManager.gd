extends Node

# Stand-alone node for the display of dialogues based on json files made with a Godot plugin
# The plugin was made based on Levrault's dialogue editor (there may be some compatibility issues)
# Plugin can be found here:  https://github.com/BlooRabbit/DialogPlugin
# Lebvault's editor can be found here: https://github.com/Levrault/LE-dialogue-editor
# Use it to make and save your json file in the "Dialogue" folder

# Load .json by triggering loaddialogue(path) from your game script, where path is the name without extension in a folder called Dialogue
# Start dialogue with start(originnode,position, campos, camtarget) from your game script(s)

# Choices in this example are only based on "OK" or "NO" triggering a yes/no button - change this based on your own project
#	=> requires a $OKbutton and a $NObutton button node to work
# Conditions based on variables work using variables defined in this script or as autoload.variable

var position : Vector2 = Vector2.ZERO

var _dialogues := {}
var _conditions := {}
var _current_dialogue := {}
var dialogue_json
var OK_node : String =""
var NO_node : String =""
var originnode:Object = self

var _is_last_dialogue : bool= false
var _has_timer : bool = false
var _is_displaying : bool = false
var _is_executing : bool = false

#  change the below to allocate the various panels based on your own project
onready var _text = $Dialoguetext # message
onready var _choices_panel = null # panel for choices
onready var _next = $OKbutton # next button
onready var _end = $OKbutton # end of dialogue button
onready var _timer = $Timer # timer for timed messages

signal dialogue_finished
signal timer(seconds)
signal codexec(codetoexecute)

# --------------------------

func _ready():

	$OKbutton.visible=false
	$NObutton.visible=false

func _physics_process(delta):
	if movecamera: # get camera to dialog fixed place
		get_tree().root.get_node("Game/Camera").adjustcam(delta,campos)
		get_tree().root.get_node("Game/Camera").look_at(camtarget, Vector3.UP)
		# signal when camera arrived
		if (get_tree().root.get_node("Game/Camera").global_transform.origin-campos).length()<0.5:
			emit_signal("cameraOK")

# ----------------------------------------
# Start functions triggered by game code
# ----------------------------------------

# Load dialogue
func loaddialogue(path) -> void: # path is the name of the file without extension
	dialogue_json = get_json("Dialogue/"+path+".json")

# starts the dialogue
func start(origin:Object=self,pos:Object=self, cpos:Vector3=Vector3.ZERO, ctarget:Vector3=Vector3.ZERO) -> void:
	
	# launch first dialogue
	originnode=origin
	_current_dialogue = dialogue_json["root"]
	if _current_dialogue.has("conditions"): # in case dialogue starts with condition branches
		executeconditions() # displays next dialogue based on conditions
	else: # in case dialogue starts with a text dialogue 
		_current_dialogue = dialogue_json[dialogue_json.root["next"]]
		displaydialogue() # start the first text box

# ---------------------------------------------
# Specific game events triggered by json signal
# ---------------------------------------------

# Execute some game specific signals

# put you functions here, that will executed as signals from th dialog
# example: func signallight(): $light.visible = toggle($light.visible)

# ----------------------------------------
#   Dialogue system
# ----------------------------------------

# This function displays the dialogues
func displaydialogue() -> void:
		
	if _is_displaying : return
	_is_displaying = true

	if _current_dialogue.empty() or not _current_dialogue.has("text"): Dialogue_finished() # avoid game breaks

	# if there is no linked dialogue, no choice and no condition => last dialogue
	if not _current_dialogue.has("conditions") and not _current_dialogue.has("next") and not _current_dialogue.has("choices"):
		_is_last_dialogue=true

	# reset choice display
	$OKbutton.visible=false
	$NObutton.visible=false
	
	# parse dialog text
	var text: String = _current_dialogue["text"][TranslationServer.get_locale()]
	var message= texttoimagepath(text) # transform in-dialog image tags
	_text.parse_bbcode(message) 

	# resize dialog box based on message size
	# do your own stuff here if needed !

	# make letters appear progressively
	var textsize=message.length()
	$Tween.interpolate_property(_text,"visible_characters",0,textsize,textsize*0.02,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	$Tween.start()
	yield(get_tree().create_timer(textsize*0.01),"timeout")

	# check if player can make some choices and have them displayed
	# careful: in this example, choices are only "OK" or "NO" - adapt depending on your project
	if _current_dialogue.has("choices"):
		var conditions: Array = (
			_current_dialogue.get("conditions")
			if _current_dialogue.has("conditions")
			else []
		)
		displaychoices(get_choices(_current_dialogue.choices, conditions))
	else: # just display a next button
		$OKbutton.visible=true
		$OKbutton.grab_focus()

	_is_displaying = false

# displays choices
# careful: in this example, choices are only "OK" or "NO" - adapt depending on your project
func displaychoices(choices):
	OK_node=""
	NO_node=""
	for choice in choices:
		# the below checks if it is a OK or NO button
		var choosefrom:String = choice["text"][TranslationServer.get_locale()]
		if choosefrom=="OK": 
			OK_node=choice["next"] # store OK choice
			$OKbutton.visible=true
			$OKbutton.grab_focus()
		if choosefrom=="NO": 
			NO_node=choice["next"] # store NO choice
			$NObutton.visible=true

# implements the conditions (conditions can follow root or dialogue nodes)
# condition may be a variable of the dialog script or an autoload.variable
func executeconditions():
	if _is_displaying or _is_executing : return
	_is_executing==true

	var chosendialog : Dictionary
	var conditions=_current_dialogue.conditions
	for condition in conditions:
		for key in condition.keys(): # key is either the condition or its "next" node
			if key != "next": 
				if checkiftrue(key, condition[key]):
					chosendialog=dialogue_json[condition["next"]]
	if chosendialog.empty(): 
		Dialogue_finished() # avoid dialog issues
		return
	_current_dialogue=chosendialog
	displaydialogue()

	_is_executing=false

# checks if a given condition is true and returns a boolean
func checkiftrue(variable, condition) -> bool:
	var vartocheck=get(variable)
# ------
	if "autoload" in variable: # variable for conditions can be an autoload
		variable=variable.replace("autoload.","")
		vartocheck=autoload.get(variable)
# ------
	if condition ["type"] == "boolean":
		var valtocheck :bool
		if condition["value"]=="true":valtocheck=true
		if condition["value"]=="false":valtocheck=false
		if vartocheck == valtocheck: return true
		else: return false
	elif condition ["type"] == "number":
		var value=int(condition["value"])
		if condition ["operator"] == "equal":
			if vartocheck == value: return true
			else: return false
		if condition ["operator"] == "greater":
			if vartocheck > value: return true
			else: return false
		if condition ["operator"] == "lower":
			if vartocheck < value: return true
			else: return false
		if condition ["operator"] == "different":
			if vartocheck != value: return true
			else: return false
	return false

# OK button
func _OKbutton_pressed():
	if _current_dialogue.has("signals"): 
		_emit_dialogue_signal(_current_dialogue["signals"])
	if _is_last_dialogue: Dialogue_finished() # OK to end dialogue
	elif _current_dialogue.has("conditions"): 
		executeconditions() # next dialogue based on conditions
	else: # not last dialogue and no conditions, so "OK" means "next" or "choice"
		if OK_node !="": # OK is a choice and the next key is stored in OK_node
			_current_dialogue = dialogue_json[OK_node]
			displaydialogue()
		else:  # OK means next
			if _current_dialogue.has("next"): 
				_current_dialogue = dialogue_json[_current_dialogue["next"]]
				displaydialogue()
			else: Dialogue_finished() # avoid dead ends

# NO button
func _NObutton_pressed():
	if NO_node !="":  # go to node refered to in NO_node
		_current_dialogue = dialogue_json[NO_node]
		displaydialogue()

# Emit signals - this requires that the signals are "declared" somewhere ("signal string(value)")
# For example timed dialog works with a signal called "timer(seconds)" to created a timed box
# Another signal is the "execode(blabla)" signal which executes specific code
func _emit_dialogue_signal(signals: Dictionary) -> void:
	for key in signals:
		if not signals[key] is Dictionary:
			if signals[key] == null:
				connect(key, self, key)
				emit_signal(key)
				continue
			connect(key, self, key)
			emit_signal(key, signals[key])
			continue
		var multi_values_signal: Dictionary = signals[key]
		for type in multi_values_signal:
			var value = _convert_value_to_type(type, multi_values_signal[type])
			connect(key, self, key)
			emit_signal(key, value)

# Function used for signals
func _convert_value_to_type(type: String, value):
	match type:
		"vector2":
			return Vector2(value["x"], value["y"])
		"number":
			if "." in type: return float(value)
			else: return int(value)
		"string":
			return str(value)
	return value

# ----------------
# End of dialogue
# ----------------

# close box at end of dialogue
func closebox():
	yield(get_tree().create_timer(0.1), "timeout")
	$Tween.interpolate_property(self,"rect_scale",Vector2(1.0,1.0),Vector2(0.0,0.0),0.3, Tween.TRANS_SINE,Tween.EASE_IN_OUT)
	$Tween.start() #tween the scale of the dialogue box back to zero
	yield($Tween,"tween_completed")
	self.visible=false
	self.set("rect_size", Vector2(470,290)) # reset standard box size

# Reset dialogue when finished
func Dialogue_finished() -> void:
	emit_signal("dialogue_finished") # can be captured by yield from origin node
	$OKbutton.visible=false
	$NObutton.visible=false
	_text.text=""
	_text.bbcode_text=""
	closebox()
	clear()
	_timer.stop()
	_is_last_dialogue = false
	_has_timer = false

# clear dialogue variables
func clear() -> void:
	NO_node=""
	OK_node=""
	_dialogues = {}
	_current_dialogue = {}
	_conditions = {}

# Function to get choices in case of multiple choices
func get_choices(choices: Array, conditions: Array = []) -> Array:
	if conditions.empty():
		return choices

	var result := []
	var conditional_choices := {}

	for choice in choices:
		if choice.has("uuid"):
			conditional_choices[choice.uuid] = choice
		else:
			result.append(choice)

	if conditional_choices.empty():
		return choices

	var matching_condition := 0
	for condition in conditions:
		var current_matching_condition := 0
		for key in condition:
			var predicated_next: String = condition.next
			condition.erase("next")

			if _conditions.has(key):
				# conditions will never match
				if _conditions.size() < condition.size():
					continue

				if condition.empty():
					result.append(conditional_choices[predicated_next])

				if _check_conditions(condition, key):
					current_matching_condition += 1

			if current_matching_condition > matching_condition:
				result.append(conditional_choices[predicated_next])

	# dialogue json file was badly configuarated since it doesn't have a default choice
	assert(not result.empty())
	return result

# Check conditions
# @returns {bool}
func _check_conditions(condition: Dictionary, key: String) -> bool:
	match condition[key].operator:
		"lower":
			return condition[key].value > _conditions[key]
		"greater":
			return condition[key].value < _conditions[key]
		"different":
			return condition[key].value != _conditions[key]
		_:
			return condition[key].value == _conditions[key]

# --------------------------
# Read and parse Json file
# --------------------------

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
		
	data_parse.result.erase("__editor")
	return data_parse.result
