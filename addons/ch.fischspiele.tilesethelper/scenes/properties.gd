tool
extends HBoxContainer

onready var propertyItem = get_node("VBoxContainer/propertyItem")
onready var propertyList = get_node("list")
onready var iconBool = load("res://addons/ch.fischspiele.tilesethelper/icons/icon_bool.png")
onready var iconFloat = load("res://addons/ch.fischspiele.tilesethelper/icons/icon_float.png")
onready var iconTexture = load("res://addons/ch.fischspiele.tilesethelper/icons/icon_texture.png")
onready var iconTile = load("res://addons/ch.fischspiele.tilesethelper/icons/icon_tile.png")
onready var btnRemove = get_node("VBoxContainer/buttons/remove")
onready var btnNew = get_node("VBoxContainer/buttons/new")

var selectedNode = null

func _ready():
	#set list
	propertyList.set_allow_rmb_select(false)
	propertyList.set_select_mode(ItemList.SELECT_SINGLE)
	#connections
	propertyList.connect("item_selected",self,"_propertyListItem_selected")
	btnRemove.connect("pressed",self,"_removePropertyItem")
	btnNew.connect("pressed",self,"_newPropertyItem")
	#own signal connection
	propertyItem.connect("item_changed",self,"_propertyList_Item_changed")
	propertyItem.connect("type_changed",self,"_propertyList_Type_changed")

func getPropertiesFromShader(_selectedNode):
		propertyList.clear()
		selectedNode = _selectedNode
		if _selectedNode.get_material() == null:
			propertyItem.set_empty()
		else:
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
					elif _name.begins_with("tile"):
						_type = propertyItem.TILE
						_value = _uniformArray[3]
					else: # bool or float
						if _uniformArray[0] == "bool":
							_type = propertyItem.BOOL
							_value = _uniformArray[3]=="true"
						else:
							_type = propertyItem.FLOAT
							_value = _uniformArray[3]
					addPropertyListItem(_type,_name,_value)
			if propertyList.get_item_count() > 0:
				propertyList.select(0)
				_propertyListItem_selected(0)

func addPropertyListItem(_type,_name,_value):
	print("add propertyListItem [ ",_type," , ",_name," , ",_value," ]")
	var _idx = propertyList.get_item_count()
	if _type == propertyItem.BOOL:
		propertyList.add_item(_name,iconBool)
	elif _type == propertyItem.FLOAT:
		propertyList.add_item(_name,iconFloat)
	elif _type == propertyItem.TILE:
		propertyList.add_item(_name,iconTile)
	elif _type == propertyItem.TEXTURE:
		propertyList.add_item(_name,iconTexture)
	propertyList.set_item_metadata(_idx,[_type,_name,_value])

func _propertyListItem_selected(_idx):
	var _metaData = propertyList.get_item_metadata(_idx)
	propertyItem.set_item(_metaData[0],_metaData[1],_metaData[2])

func _newPropertyItem():
	addPropertyListItem(propertyItem.BOOL,"myProperty",false)
	var _idx = propertyList.get_item_count()-1
	manualselectItem(_idx)
	propertyItem.set_focus_on_name()

func _removePropertyItem():
	if propertyList.get_selected_items().size() != 0:
		print("remove PropertyListItem [ ",propertyItem.get_item()[0]," , ",propertyItem.get_item()[1]," , ",propertyItem.get_item()[2]," ]")
		propertyList.remove_item(propertyList.get_selected_items()[0])
		if propertyList.get_item_count() != 0:
			manualselectItem(propertyList.get_item_count()-1)
		else:
			#last item removed
			propertyItem.set_empty()
		writeShader()

func _propertyList_Item_changed(_type,_name,_value):
	if propertyList.get_selected_items() != null:
		var _idx = propertyList.get_selected_items()[0]
		propertyList.set_item_text(_idx,_name)
		propertyList.set_item_metadata(_idx,[_type,_name,_value])
		writeShader()

func _propertyList_Type_changed(_type):
	if propertyList.get_selected_items() != null && propertyList.get_selected_items().size() != 0: #bug
		var _idx = propertyList.get_selected_items()[0]
		if _type == propertyItem.BOOL:
			propertyList.set_item_icon(_idx,iconBool)
		elif _type == propertyItem.FLOAT:
			propertyList.set_item_icon(_idx,iconFloat)
		elif _type == propertyItem.TILE:
			propertyList.set_item_icon(_idx,iconTile)
			var _name = getUniqueTileName()
			propertyItem.set_item_name(_name)
			propertyItem.set_item_value(0,_type)
		elif _type == propertyItem.TEXTURE:
			propertyList.set_item_icon(_idx,iconTexture)
		propertyItem.item_changed()

func writeShader():
	print("tile properties saved!")
	var _material = selectedNode.get_material()
	if _material == null:
		_material = CanvasItemMaterial.new()
		var _shader = CanvasItemShader.new()
		_material.set_shader(_shader)
		selectedNode.set_material(_material)
	var _shader = _material.get_shader()
	var _shaderCode = shaderCodeWithoutUniform(_shader.get_fragment_code())
	var _code = ""
	
	#set shader code
	if propertyList.get_item_count() == 0:
		selectedNode.set_material(null)
	else:
		for _idx in range(propertyList.get_item_count()):
			var _metaData = propertyList.get_item_metadata(_idx)
			var _type = _metaData[0]
			var _name = _metaData[1]
			var _value = _metaData[2]
			if _idx > 0:
				_code += "\n"
			if _type == propertyItem.BOOL:
				_code += "uniform bool "+_name+" = "+str(_value).to_lower()+";"
			elif _type == propertyItem.FLOAT || _type == propertyItem.TILE:
				_code += "uniform float "+_name+" = "+str(_value)+";"
			elif _type == propertyItem.TEXTURE:
				_code += "uniform texture "+_name+";"
		_code += _shaderCode
		_shader.set_code("",_code,"")
	
	#set shader param
	for _idx in range(propertyList.get_item_count()):
		var _metaData = propertyList.get_item_metadata(_idx)
		var _type = _metaData[0]
		var _name = _metaData[1]
		var _value = _metaData[2]
		if _type == propertyItem.TEXTURE:
			_material.set_shader_param(_name,_value)

func setTexturePropertyImage(_texture):
	var _name = propertyItem.get_item()[1]
	_propertyList_Item_changed(propertyItem.TEXTURE,_name,_texture)
	propertyItem.set_item_value(_texture,propertyItem.TEXTURE)

func manualselectItem(_idx):
	propertyList.select(_idx)
	_propertyListItem_selected(_idx)

func shaderCodeWithoutUniform(_code):
	var _codeArray = _code.split("\n")
	var _codeWithoutUniform = "\n"
	for i in range(_codeArray.size()):
		if _codeArray[i].find("uniform") == -1 && _codeArray[i].length() > 0:
			_codeWithoutUniform += _codeWithoutUniform + _codeArray[i] + "\n"
	return _codeWithoutUniform

func getUniqueTileName():
	var _tileNames = []
	var _tileIndex = 0
	for _idx in range(propertyList.get_item_count()):
		var _metaData = propertyList.get_item_metadata(_idx)
		var _type = _metaData[0]
		var _name = _metaData[1]
		if _type == propertyItem.TILE:
			_tileNames.append(_name)
	if _tileNames.size() == 0:
		return "tile"+str(_tileIndex)
	while _tileNames.has("tile"+str(_tileIndex)):
		_tileIndex +=1
	return "tile"+str(_tileIndex)
	