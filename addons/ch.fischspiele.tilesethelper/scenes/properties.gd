tool
extends HBoxContainer

onready var propertyItem = get_node("VBoxContainer/propertyItem")
onready var propertyList = get_node("list")
onready var iconBool = load("res://addons/ch.fischspiele.tilesethelper/icons/icon_bool.png")
onready var iconFloat = load("res://addons/ch.fischspiele.tilesethelper/icons/icon_float.png")
onready var iconTexture = load("res://addons/ch.fischspiele.tilesethelper/icons/icon_texture.png")
onready var btnRemove = get_node("VBoxContainer/buttons/remove")
onready var btnNew = get_node("VBoxContainer/buttons/new")

func _ready():
	propertyItem.connect("item_changed",self,"_changePropertyListItem")
	btnRemove.connect("pressed",self,"_removePropertyItem")
	btnNew.connect("pressed",self,"_newPropertyItem")
	propertyList.set_allow_rmb_select(false)
	propertyList.set_select_mode(ItemList.SELECT_SINGLE)
	propertyList.connect("item_selected",self,"_propertyListItem_selected")

func getPropertiesFromShader(_selectedNode):
		propertyList.clear()
		if _selectedNode.get_material():
			var _material = _selectedNode.get_material()
			var _shader = _material.get_shader()
			var _code = _shader.get_fragment_code()
			_code = _code.replace(" ="," ")
			_code = _code.replace("\n","")
			var _codeArray = _code.split(";")
			for _i in range(_codeArray.size()):
				if _codeArray[_i].find("uniform") != -1:
					var _propertyLine = _codeArray[_i].replace("uniform ","")
					var _uniformArray = _propertyLine.split(" ")
					var _type = null
					var _name = _uniformArray[1]
					var _value = null
					if _propertyLine.find("texture") != -1:
						_type = propertyItem.TEXTURE
						_value = _material.get_shader_param(_uniformArray[1])
					else: # bool or float
						if _uniformArray[0] == "bool":
							_type = propertyItem.BOOL
							_value = _uniformArray[2]=="true"
						else:
							_type = propertyItem.FLOAT
							_value = _uniformArray[2]
					addPropertyListItem(_type,_name,_value)
			if propertyList.get_item_count() > 0:
				propertyList.select(0)
				_propertyListItem_selected(0)

func addPropertyListItem(_type,_name,_value):
	var _idx = propertyList.get_item_count()
	if _type == propertyItem.BOOL:
		propertyList.add_item(_name,iconBool)
	elif _type == propertyItem.FLOAT:
		propertyList.add_item(_name,iconFloat)
	else:
		propertyList.add_item(_name,iconTexture)
	propertyList.set_item_metadata(_idx,[_type,_name,_value])

func _propertyListItem_selected(_idx):
	var _metaData = propertyList.get_item_metadata(_idx)
	propertyItem.set_item(_metaData[0],_metaData[1],_metaData[2])

func _newPropertyItem():
	addPropertyListItem(propertyItem.BOOL,"myProperty",false)
	var _idx = propertyList.get_item_count()-1
	manualselectItem(_idx)
	propertyItem.setFocusOnName()

func _removePropertyItem():
	if propertyList.get_selected_items().size() != 0:
		propertyList.remove_item(propertyList.get_selected_items()[0])
		if propertyList.get_item_count() != 0:
			manualselectItem(propertyList.get_item_count()-1)

func _changePropertyListItem(_type,_name,_value):
	var _idx = propertyList.get_selected_items()[0]
	propertyList.set_item_text(_idx,_name)
	if _type == propertyItem.BOOL:
		propertyList.set_item_icon(_idx,iconBool)
	elif _type == propertyItem.FLOAT:
		propertyList.set_item_icon(_idx,iconFloat)
	else:
		propertyList.set_item_icon(_idx,iconTexture)
	propertyList.set_item_metadata(_idx,[_type,_name,_value])
	writeShader()

func writeShader():
	print("write shader")
	pass

func manualselectItem(_idx):
	propertyList.select(_idx)
	_propertyListItem_selected(_idx)
