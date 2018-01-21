tool
extends HBoxContainer

signal item_changed

const BOOL = 0;const FLOAT = 1;const TEXTURE = 2
onready var propertyType = get_node("typeContainer/dataType")
onready var propertyValueType = get_node("valueContainer/propertyValue")
onready var propertyName = get_node("nameContainer/propertyName")

var itemList

func _ready():
	set_avaible_types()
	propertyType.connect("item_selected",self,"item_selected")
	propertyName.connect("focus_exit",self,"name_exit")
	propertyName.connect("text_entered",self,"name_changed")
	#propertyName.connect("text_changed",self,"name_changed")

func set_item(_type,_name,_value):
	propertyType.select(_type)
	propertyName.set_text(_name)
	if _type == BOOL:
		propertyValueType.get_node(str(_type)).set_pressed(_value)
	elif _type == FLOAT:
		propertyValueType.get_node(str(_type)).set_value(_value)
	elif _type == TEXTURE:
		propertyValueType.get_node(str(_type)+"/TextureFrame").set_texture(_value)
	changeValueTypeTo(_type)

func get_item():
	var _value = null
	var _type = propertyType.get_selected_ID()
	if _type == BOOL:
		_value = propertyValueType.get_node(str(_type)).is_pressed()
	elif _type == FLOAT:
		_value = propertyValueType.get_node(str(_type)).get_value()
	elif _type == TEXTURE:
		_value = propertyValueType.get_node(str(_type)+"/TextureFrame").get_texture()
	return [_type,propertyName.get_text(),_value]

func set_avaible_types():
	pass

func item_selected(_id):
	if _id == BOOL:
		changeValueTypeTo(BOOL)
	elif _id == FLOAT:
		changeValueTypeTo(FLOAT)
	elif _id == TEXTURE:
		changeValueTypeTo(TEXTURE)
	item_changed()

func changeValueTypeTo(_type):
	for _child in propertyValueType.get_children():
		_child.hide()
	propertyValueType.get_node(str(_type)).show()

func setFocusOnName():
	propertyName.grab_focus()
	propertyName.select_all()

func name_changed(_text):
	propertyName.release_focus()
	item_changed()

func name_exit():
	item_changed()

func item_changed():
	var _item = get_item()
	emit_signal("item_changed",_item[0],_item[1],_item[2])