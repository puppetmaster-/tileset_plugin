tool
extends HBoxContainer

signal item_changed
signal type_changed

const BOOL = 0;const FLOAT = 1;const TEXTURE = 2;const TILE = 3
onready var propertyType = get_node("typeContainer/dataType")
onready var propertyValueType = get_node("valueContainer/propertyValue")
onready var propertyName = get_node("nameContainer/propertyName")
onready var propertyTileValue = get_node("valueContainer/propertyValue/3/value")
onready var propertyBoolValue = get_node("valueContainer/propertyValue/0")
onready var propertyTextureBtn = get_node("valueContainer/propertyValue/2/btnImage")

var itemList

func _ready():
	propertyType.connect("item_selected",self,"itemType_change")
	propertyName.connect("text_entered",self,"name_changed")
	propertyTileValue.connect("text_entered",self,"tileValue_changed")
	propertyBoolValue.connect("pressed",self,"item_changed")

#------------------ VISUAL ------------------#
func set_item(_type,_name,_value):
	print("set_item = ",_type," / ",_name," / ",_value)
	propertyType.select(_type)
	propertyName.set_text(_name)
	if _type == BOOL:
		propertyValueType.get_node(str(_type)).set_pressed(_value)
	elif _type == FLOAT:
		propertyValueType.get_node(str(_type)).set_value(float(_value))
	elif _type == TEXTURE:
		propertyValueType.get_node(str(_type)+"/TextureFrame").set_texture(_value)
	elif _type == TILE:
		propertyValueType.get_node(str(_type)+"/value").set_text(str(_value))
		setTileValue(_value)
	changeValueTypeTo(_type)

func item_selected(_id):
	if _id == BOOL:
		changeValueTypeTo(BOOL)
	elif _id == FLOAT:
		changeValueTypeTo(FLOAT)
	elif _id == TEXTURE:
		changeValueTypeTo(TEXTURE)
	elif _id == TILE:
		propertyName.set_editable(false)
		changeValueTypeTo(TILE)
	item_changed()

func changeValueTypeTo(_type):
	propertyName.get_parent().show()
	if _type == TILE:
		propertyName.get_parent().hide()
	for _child in propertyValueType.get_children():
		_child.hide()
	propertyValueType.get_node(str(_type)).show()

#------------------ SET DATA ------------------#
func set_empty():
	print("set propertyItem empty")
	propertyType.select(BOOL)
	changeValueTypeTo(BOOL)
	set_item_value(false,BOOL)
	propertyName.set_text("")

func set_item_name(_name):
	propertyName.set_text(_name)

func set_item_value(_value,_type):
	if _type == BOOL:
		propertyValueType.get_node(str(_type)).set_pressed(_value)
	elif _type == FLOAT:
		propertyValueType.get_node(str(_type)).set_value(float(_value))
	elif _type == TEXTURE:
		propertyValueType.get_node(str(_type)+"/TextureFrame").set_texture(_value)
	elif _type == TILE:
		propertyValueType.get_node(str(_type)+"/value").set_text(str(_value))

func setTileValue(_value):
	var _child = get_tree().get_edited_scene_root().get_child(int(_value))
	var _texture = _child.get_texture()
	var _sprite = propertyValueType.get_node("3/Sprite")
	if _child.is_region(): #texture with region
		_sprite.set_region(_child.is_region())
		_sprite.set_region_rect(_child.get_region_rect())
	else: #single texture
		_sprite.set_vframes(1)
		_sprite.set_hframes(1)
		_sprite.set_frame(0)
		_sprite.set_region(false)
		_texture.set_size_override(Vector2(64,64))
	_sprite.set_texture(_texture)
	

#------------------ GET DATA ------------------#
func get_item():
	var _value = null
	var _type = propertyType.get_selected_ID()
	if _type == BOOL:
		_value = propertyValueType.get_node(str(_type)).is_pressed()
	elif _type == FLOAT:
		_value = propertyValueType.get_node(str(_type)).get_value()
	elif _type == TEXTURE:
		_value = propertyValueType.get_node(str(_type)+"/TextureFrame").get_texture()
	elif _type == TILE:
		_value = propertyValueType.get_node(str(_type)+"/value").get_text()
	return [_type,propertyName.get_text(),_value]

func setFocusOnName():
	propertyName.grab_focus()
	propertyName.select_all()

#------------------ EVENTS ------------------#
func tileValue_changed(_value):
	setTileValue(_value)
	item_changed()

func itemType_change(_type):
	changeValueTypeTo(_type)
	emit_signal("type_changed",_type)

func name_changed(_text):
	propertyName.release_focus()
	item_changed()

func item_changed():
	var _item = get_item()
	emit_signal("item_changed",_item[0],_item[1],_item[2])