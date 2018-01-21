tool
extends PanelContainer

var tileSize = 64
var oneImageSelected = false
var oneImageSelectedSize = Vector2(0,0)
var hFrames = 0
var vFrames = 0
var getPolygonFromCollision = true
var checkCollision = false
var checkNavigation = false
var checkImage = false
var checkOccluder = false
var mainGuiPath = "HBoxContainer/"
var imagesPath
var selectedNodes
var tilePropertiesNode

func _ready():
	tilePropertiesNode = get_tree().get_nodes_in_group("tilesethelper_properties")[0]
	#image
	get_node(mainGuiPath+"VBoxContainer/HBoxImage/VBoxImage/sizeBox/size").connect("text_changed",self,"tilesize")
	get_node(mainGuiPath+"VBoxContainer/HBoxImage/VBoxImage/sizeBox/size").set_text(str(tileSize))
	get_node(mainGuiPath+"VBoxContainer/HBoxImage/CheckBox").connect("toggled",self,"setImageCheck")
	#frames
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").set_text("0")
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_text("0")
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").set_editable(false)
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_editable(false)
	#Offset
	get_node(mainGuiPath+"VBoxContainer/HBoxFrameOffset/XOffset").set_text("0")
	get_node(mainGuiPath+"VBoxContainer/HBoxFrameOffset/YOffset").set_text("0")
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").set_editable(true)
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_editable(true)
	#dialog
	get_node(mainGuiPath+"VBoxContainer/HBoxImage/ImageContainer/btnImage").connect("pressed",self,"show_dialog",["image"])
	#collision
	get_node(mainGuiPath+"VBoxContainer2/HBoxCollision/collisionPolygon").connect("pressed",self,"collisionPolygon")
	get_node(mainGuiPath+"VBoxContainer2/HBoxCollision/CheckBox").connect("toggled",self,"setCollisionPolygonCheck")
	#navigation
	get_node(mainGuiPath+"VBoxContainer2/HBoxNavigation/navigation").connect("pressed",self,"navigation")
	get_node(mainGuiPath+"VBoxContainer2/HBoxNavigation/CheckBox").connect("toggled",self,"setNavigationCheck")
	#occluder
	get_node(mainGuiPath+"VBoxContainer2/HBoxOccluder/occluder").connect("pressed",self,"occluder")
	get_node(mainGuiPath+"VBoxContainer2/HBoxOccluder/CheckBox").connect("toggled",self,"setOccluderCheck")
	#settings
	get_node(mainGuiPath+"VBoxContainer3/HBoxSettings/CheckGetPolyColli").connect("toggled",self,"setGetPolygonFromCollisionCheck")
	get_node(mainGuiPath+"VBoxContainer3/HBoxSettings/CheckGetPolyColli").set_toggle_mode(getPolygonFromCollision)
	#properties
	get_node(mainGuiPath+"VBoxProperties/random/ImageContainer1/btnImage").connect("pressed",self,"show_dialog",["propertyImage"])
	get_node(mainGuiPath+"VBoxContainer3/properties").connect("pressed",self,"addRemoveTileProperties")
	get_node(mainGuiPath+"VBoxProperties").hide()
	get_node(mainGuiPath+"VBoxProperties/cbProperties/cbFlipX").connect("toggled",self,"setTileProperties",["flipX"])
	get_node(mainGuiPath+"VBoxProperties/cbProperties/cbFlipY").connect("toggled",self,"setTileProperties",["flipY"])
	get_node(mainGuiPath+"VBoxProperties/cbProperties/cbRandom").connect("toggled",self,"setTileProperties",["random"])
	get_node(mainGuiPath+"VBoxProperties/random/add").connect("pressed",self,"addTextureFrame")
	get_node(mainGuiPath+"VBoxProperties/random/remove").connect("pressed",self,"removeTextureFrame")
	get_node(mainGuiPath+"VBoxProperties/random/ItemList").connect("item_selected",self,"listItem_selected")
	#tiles
	get_node(mainGuiPath+"VBoxContainer3/create_tiles").connect("pressed",self,"create_tiles")

func collisionPolygon():
	print("add/remove collisionPolygon")
	for seletedNode in selectedNodes:
		setCollisionPolygon(seletedNode)

func setCollisionPolygon(seletedNode):
	if seletedNode.get_owner() != null:
		var _owner = seletedNode.get_owner()
		var _newStaticBodyNode = setStaticBody(seletedNode,_owner)
		var _newCollisionPolygonNode = CollisionPolygon2D.new()
		_newCollisionPolygonNode.set_polygon(getVector2ArrayFromSprite(seletedNode))
		_newCollisionPolygonNode.set_name("CollisionPolygon2D")
		_newStaticBodyNode.add_child(_newCollisionPolygonNode)
		_newCollisionPolygonNode.set_owner(_owner)
	else:
		print("Error: root node selected")

func occluder():
	print("add/remove occluder")
	for seletedNode in selectedNodes:
		setOccluder(seletedNode)

func setOccluder(seletedNode):
	if seletedNode.get_owner() != null:
		if seletedNode.get_type() == "Sprite":
			if seletedNode.has_node("LightOccluder2D"):
				print("deleting LightOccluder2D")
				seletedNode.remove_child(seletedNode.get_node("LightOccluder2D"))
			var _newLightOccluderNode = LightOccluder2D.new()
			_newLightOccluderNode.set_occluder_polygon(getOccPolygon2D(seletedNode))
			_newLightOccluderNode.set_name("LightOccluder2D")
			seletedNode.add_child(_newLightOccluderNode)
			_newLightOccluderNode.set_owner(seletedNode.get_parent())
		else:
			print("Error: no sprite selected")
	else:
		print("Error: root node selected")

func navigation():
	print("add/remove navigation")
	for seletedNode in selectedNodes:
		setNavigation(seletedNode)

func setNavigation(seletedNode):
	if seletedNode.get_owner() != null:
		if seletedNode.get_type() == "Sprite":
			if seletedNode.has_node("NavigationPolygonInstance"):
				seletedNode.remove_child(seletedNode.get_node("NavigationPolygonInstance"))
			var _newNavigationPolygonNode = NavigationPolygonInstance.new()
			_newNavigationPolygonNode.set_navigation_polygon(getNavPolygon(seletedNode))
			_newNavigationPolygonNode.set_name("NavigationPolygonInstance")
			seletedNode.add_child(_newNavigationPolygonNode)
			_newNavigationPolygonNode.set_owner(seletedNode.get_parent())
		else:
			print("Error: no sprite selected")
	else:
		print("Error: root node selected")

func getVector2ArrayFromSprite(selectedNode):
	var _Array = []
	var _Vector2Array = Vector2Array(_Array)
	_Vector2Array.append(Vector2(-tileSize/2,-tileSize/2))
	_Vector2Array.append(Vector2(tileSize/2,-tileSize/2))
	_Vector2Array.append(Vector2(tileSize/2,tileSize/2))
	_Vector2Array.append(Vector2(-tileSize/2,tileSize/2))
	return _Vector2Array

func getVector2ArrayFromCollision(selectedNode):
	return selectedNode.get_node("StaticBody2D/CollisionPolygon2D").get_polygon()

func getNavPolygon(selectedNode):
	var _navPoly = NavigationPolygon.new()
	var _polyArray = null
	if getPolygonFromCollision:
		_polyArray = getVector2ArrayFromCollision(selectedNode)
	else:
		_polyArray = getVector2ArrayFromSprite(selectedNode)
	_navPoly.add_outline(_polyArray)
	_navPoly.add_polygon(IntArray([0, 1, 2, 3]))
	_navPoly.set_vertices(_polyArray)
	return _navPoly

func getOccPolygon2D(selectedNode):
	var _occPoly = OccluderPolygon2D.new()
	var _polyArray = null
	if getPolygonFromCollision:
		_polyArray = getVector2ArrayFromCollision(selectedNode)
	else:
		_polyArray = getVector2ArrayFromSprite(selectedNode)
	_occPoly.set_polygon(_polyArray)
	return _occPoly

func tilesize(newTileSize):
	tileSize = int(newTileSize)
	if (tileSize < oneImageSelectedSize.x && tileSize > 0) || (oneImageSelectedSize.x != oneImageSelectedSize.y && tileSize > 0):
		hFrames = oneImageSelectedSize.x/tileSize
		vFrames = oneImageSelectedSize.y/tileSize
		get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").set_text("0")
		get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_text(str(hFrames*vFrames))
		get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").set_editable(true)
		get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_editable(true)
	else:
		disableFramesGui()

func setStaticBody(selectedNode,owner):
	if selectedNode.has_node("StaticBody2D"):
		selectedNode.remove_child(selectedNode.get_node("StaticBody2D"))
	var _newStaticBodyNode = StaticBody2D.new()
	_newStaticBodyNode.set_name("StaticBody2D")
	var _newConvexPolygonShape = ConvexPolygonShape2D.new()
	_newConvexPolygonShape.set_points(getVector2ArrayFromSprite(selectedNode))
	_newStaticBodyNode.clear_shapes()
	_newStaticBodyNode.add_shape(_newConvexPolygonShape)
	selectedNode.add_child(_newStaticBodyNode)
	_newStaticBodyNode.set_owner(owner)
	return _newStaticBodyNode

func show_dialog(_dialogeType):
	var fileDialog = FileDialog.new()
	get_parent().add_child(fileDialog)
	fileDialog.set_mode(FileDialog.MODE_OPEN_FILES)
	fileDialog.set_current_path("res://")
	fileDialog.set_access(FileDialog.ACCESS_RESOURCES)
	fileDialog.clear_filters()
	fileDialog.add_filter("*.png ; PNG Images");
	fileDialog.set_custom_minimum_size(Vector2(500,500))
	fileDialog.popup_centered()
	fileDialog.show()

	if _dialogeType == "image":
		fileDialog.connect("files_selected",self,"on_files_selected",[fileDialog])
	elif _dialogeType == "propertyImage":
		fileDialog.connect("files_selected",self,"on_files_selected_property",[fileDialog])

func on_files_selected(imagePathArray,_fileDialog):
	imagesPath = imagePathArray
	var _newTexture  = ImageTexture.new()
	var _newName
	var _newSize
	get_node(mainGuiPath+"VBoxContainer/HBoxImage/CheckBox").set_pressed(true)
	setImageCheck(true)
	if imagePathArray.size() == 1:
		oneImageSelected = true
		_newTexture.load(imagePathArray[0])
		var _newTextureWidth = _newTexture.get_width()
		var _newTextureHeight = _newTexture.get_height()
		if _newTextureWidth == _newTextureHeight:
			_newSize = _newTextureWidth
			disableFramesGui()
		elif _newTextureWidth < _newTextureHeight:
			_newSize = _newTextureWidth
			get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_text(str(_newTextureHeight/_newSize))
		else:
			_newSize = _newTextureHeight
			get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_text(str(_newTextureWidth/_newSize))
		oneImageSelectedSize = Vector2(_newTextureWidth,_newTextureHeight)
		if _newTextureWidth > 64 || _newTextureHeight > 64:
			_newTexture.set_size_override(Vector2(64,64))
		_newName = getFileName(imagePathArray[0])
	else:
		oneImageSelected = false
		oneImageSelectedSize = Vector2(0,0)
		_newSize = ""
		_newTexture.load("res://addons/ch.fischspiele.tilesethelper/images/gui_image_multiple.png")
		_newName = "..."

	get_node(mainGuiPath+"VBoxContainer/HBoxImage/ImageContainer/TextureFrame").set_texture(_newTexture)
	get_node(mainGuiPath+"VBoxContainer/HBoxImage/VBoxImage/sizeBox/size").set_text(str(_newSize))
	get_node(mainGuiPath+"VBoxContainer/HBoxImage/VBoxImage/name/lblName").set_text(_newName)
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").set_text("0")
	_fileDialog.queue_free()

func create_tiles():
	if checkImage:
		addImageNodes()
	else:
		if checkCollision:
			collisionPolygon()
		if checkNavigation:
			navigation()
		if checkOccluder:
			occluder()

func addImageNodes():
	print("creating ",imagesPath.size()," sprites from selection")
	var _root =  get_tree().get_edited_scene_root()
	if get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").is_editable():
		for _imagePath in imagesPath:
			var _newTexture  = ImageTexture.new()
			_newTexture.load(_imagePath)
			_newTexture.set_flags(0)
			var _startFrame = int(get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").get_text())
			var _endFrame = int(get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").get_text())
			var offsetX = int(get_node(mainGuiPath+"VBoxContainer/HBoxFrameOffset/XOffset").get_text())
			var offsetY = int(get_node(mainGuiPath+"VBoxContainer/HBoxFrameOffset/YOffset").get_text())
			var tilesWide = int((_newTexture.get_size().x + offsetX) / (int(tileSize) + offsetX))
			var tilesTall = int((_newTexture.get_size().y + offsetY) / (int(tileSize) + offsetY))
			for _frame in range(_startFrame,_endFrame):
				var _imageName = getFileName(_imagePath)+str(_frame)
				var _newSpriteNode
				if !_root.has_node(_imageName):
					_newSpriteNode = Sprite.new()
					_newSpriteNode.set_texture(_newTexture)
					_newSpriteNode.set_vframes(vFrames)
					_newSpriteNode.set_hframes(hFrames)

					if (int(tileSize) < _newTexture.get_size().x):
						_newSpriteNode.set_region(true)

						var tmpX = offsetX
						if _frame % tilesWide == 0:
							tmpX = 0
						var tmpY = offsetY
						if _frame / tilesWide < 1:
							tmpY = 0
						var position = Vector2 ((tmpX + int(tileSize)) * (int(_frame) % tilesWide) , (tmpY + int(tileSize)) * int((int(_frame) / tilesWide)))
						_newSpriteNode.set_region_rect( Rect2( position, Vector2(int(tileSize), int(tileSize))) )
						_newSpriteNode.set_pos(position)
					else:
						_newSpriteNode.set_pos(Vector2(0,0))
					_newSpriteNode.set_frame(_frame)
					_root.add_child(_newSpriteNode)
					_newSpriteNode.set_owner(_root)
					_newSpriteNode.set_name(_imageName)
				else:
					_newSpriteNode = _root.get_node(_imageName)
					_newSpriteNode.set_texture(_newTexture)
					_newSpriteNode.set_vframes(vFrames)
					_newSpriteNode.set_hframes(hFrames)
					_newSpriteNode.set_frame(_frame)
				if checkCollision:
					setCollisionPolygon(_newSpriteNode)
				if checkNavigation:
					setNavigation(_newSpriteNode)
				if checkOccluder:
					setOccluder(_newSpriteNode)
	else:
		for _imagePath in imagesPath:
			var _newTexture  = ImageTexture.new()
			_newTexture.load(_imagePath)
			_newTexture.set_flags(0)
			tileSize = _newTexture.get_width()
			var _imageName = getFileName(_imagePath)
			var _newSpriteNode
			if !_root.has_node(_imageName):
				_newSpriteNode = Sprite.new()
				_newSpriteNode.set_texture(_newTexture)
				_root.add_child(_newSpriteNode)
				_newSpriteNode.set_pos(Vector2(0,0))
				_newSpriteNode.set_owner(_root)
				_newSpriteNode.set_name(_imageName)
			else:
				_newSpriteNode = _root.get_node(_imageName)
				_newSpriteNode.set_texture(_newTexture)
			if checkCollision:
				setCollisionPolygon(_newSpriteNode)
			if checkNavigation:
				setNavigation(_newSpriteNode)
			if checkOccluder:
				setOccluder(_newSpriteNode)

### - - Tile Properties - - ###
func on_files_selected_property(imagePathArray,_fileDialog):
	imagesPath = imagePathArray
	var _newTexture  = ImageTexture.new()
	if imagePathArray.size() == 1 && get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_selected_items().size() == 1:
		_newTexture.load(imagePathArray[0])
		var _newTextureWidth = _newTexture.get_width()
		var _newTextureHeight = _newTexture.get_height()
		if _newTextureWidth > 64 || _newTextureHeight > 64:
			_newTexture.set_size_override(Vector2(64,64))
		get_node(mainGuiPath+"VBoxProperties/random/ImageContainer1/TextureFrame").set_texture(_newTexture)
		var _idx = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_selected_items()[0]
		var _name = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_text(_idx)
		var _selectedNode = selectedNodes[0]
		var _material = _selectedNode.get_material()
		var _texture = _material.set_shader_param(_name,_newTexture)
	#get_parent().remove_child(_fileDialog)
	_fileDialog.queue_free()

func on_selection_changed():
	if selectedNodes.size() == 1:
		var _selectedNode = selectedNodes[0]
		tilePropertiesNode.getPropertiesFromShader(_selectedNode)
	if selectedNodes.size() == 1:
		var _selectedNode = selectedNodes[0]
		if _selectedNode.get_type() == "Sprite":
			get_node(mainGuiPath+"VBoxContainer3/properties").set_disabled(false)
			var _material = _selectedNode.get_material()
			if _material == null:
				get_node(mainGuiPath+"VBoxContainer3/properties").set_text("Add Tiles Properties")
				get_node(mainGuiPath+"VBoxProperties").hide()
			else:
				get_node(mainGuiPath+"VBoxContainer3/properties").set_text("Remove Tiles Properties")
				get_node(mainGuiPath+"VBoxProperties").show()
				#show tileproperties
				get_node(mainGuiPath+"VBoxProperties/cbProperties/cbFlipX").set_pressed(_material.get_shader_param("flipX"))
				get_node(mainGuiPath+"VBoxProperties/cbProperties/cbFlipY").set_pressed(_material.get_shader_param("flipY"))
				get_node(mainGuiPath+"VBoxProperties/cbProperties/cbRandom").set_pressed(_material.get_shader_param("random"))
				if _material.get_shader_param("random"):
					get_node(mainGuiPath+"VBoxProperties/random").show()
					var i = 1
					get_node(mainGuiPath+"VBoxProperties/random/ItemList").clear()
					while _material.get_shader_param("frame"+str(i)): #dirty trick, because _shader.has_param("frame1")) is always false !?!
						get_node(mainGuiPath+"VBoxProperties/random/ItemList").add_item("frame"+str(i))
						i +=1
					if get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_count() > 0: #select first item
						get_node(mainGuiPath+"VBoxProperties/random/ItemList").select(0)
						listItem_selected(0)
				else:
					get_node(mainGuiPath+"VBoxProperties/random").hide()
		else:
			lockProperties()
	else:
		lockProperties()

func addRemoveTileProperties():
	if selectedNodes.size() == 1:
		var _selectedNode = selectedNodes[0]
		if _selectedNode.get_type() == "Sprite":
			if get_node(mainGuiPath+"VBoxContainer3/properties").get_text() == "Add Tiles Properties":
				var _canvasItemMaterial = CanvasItemMaterial.new()
				#fix tile properties / should be more flexible
				var _shader = CanvasItemShader.new()
				_shader.set_code("","uniform bool flipX = false;\nuniform bool flipY = false;\nuniform bool random = false;","")
				_canvasItemMaterial.set_shader(_shader)
				_selectedNode.set_material(_canvasItemMaterial)
				get_node(mainGuiPath+"VBoxContainer3/properties").set_text("Remove Tiles Properties")
			else:
				_selectedNode.set_material(null)
				get_node(mainGuiPath+"VBoxContainer3/properties").set_text("Add Tiles Properties")
			on_selection_changed()

func addTextureFrame():
	var _count = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_count()
	var _itemName = "frame"+str(_count+1)
	get_node(mainGuiPath+"VBoxProperties/random/ItemList").add_item(_itemName)
	var _selectedNode = selectedNodes[0]
	var _material = _selectedNode.get_material()
	var _shader = _material.get_shader()
	var _code = _shader.get_fragment_code().replace("\nCOLOR = tex(frame1, UV);","")
	_code = _code+"\nuniform texture "+_itemName+";\nCOLOR = tex(frame1, UV);"
	_shader.set_code("",_code,"")
	var _texture = _selectedNode.get_texture()
	_material.set_shader_param(_itemName,_texture)
	get_node(mainGuiPath+"VBoxProperties/random/ItemList").select(_count)
	listItem_selected(_count)

func removeTextureFrame():
	var _idx = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_selected_items()[0]
	var _selectedNode = selectedNodes[0]
	var _material = _selectedNode.get_material()
	var _itemCount = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_count()
	for i in range(_itemCount):#set item meta data
		var _itemText = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_text(i)
		get_node(mainGuiPath+"VBoxProperties/random/ItemList").set_item_metadata(i,_material.get_shader_param(_itemText))
	for i in range(_idx,_itemCount):#update item text
		get_node(mainGuiPath+"VBoxProperties/random/ItemList").set_item_text(i,"frame"+str(i))
	get_node(mainGuiPath+"VBoxProperties/random/ItemList").remove_item(_idx)
	updateShaderCodeFromItemList()
	if _itemCount-1 != 0: #select next item
		get_node(mainGuiPath+"VBoxProperties/random/ItemList").select(_itemCount-2)
		listItem_selected(_itemCount-2)
	else:
		resetPropertyImage()

func listItem_selected(_idx):
	var _name = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_text(_idx)
	var _selectedNode = selectedNodes[0]
	var _material = _selectedNode.get_material()
	var _texture = _material.get_shader_param(_name)
	if _texture.get_width() > 64 || _texture.get_height() > 64:
			_texture.set_size_override(Vector2(64,64))
	get_node(mainGuiPath+"VBoxProperties/random/ImageContainer1/TextureFrame").set_texture(_texture)

func updateShaderCodeFromItemList():
	var _selectedNode = selectedNodes[0]
	var _material = _selectedNode.get_material()
	var _shader = _material.get_shader()
	var _stateRandom = _material.get_shader_param("random")
	var _code = getShaderCodeFromCeckbox(_material)
	if _stateRandom:
		var _itemCount = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_count()
		for i in range(_itemCount):
			_code = _code+"\nuniform texture frame"+str(i+1)+";"
		_code = _code+"\nCOLOR = tex(frame1, UV);"
	_shader.set_code("",_code,"")
	if _stateRandom:
		var _itemCount = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_count()
		for i in range(_itemCount):
			var _texture = get_node(mainGuiPath+"VBoxProperties/random/ItemList").get_item_metadata(i)
			_material.set_shader_param("frame"+str(i+1),_texture)

func setTileProperties(_newValue,_property):
	if selectedNodes.size() == 1:
		var _selectedNode = selectedNodes[0]
		if _selectedNode.get_type() == "Sprite":
			var _material = _selectedNode.get_material()
			_material.set_shader_param(_property,_newValue)
			if _property == "random":
				if _newValue:
					get_node(mainGuiPath+"VBoxProperties/random").show()
					resetPropertyImage()
				else:
					var _shader = _material.get_shader()
					var _code = getShaderCodeFromCeckbox(_material)
					_shader.set_code("",_code,"")
					get_node(mainGuiPath+"VBoxProperties/random/ItemList").clear()
					get_node(mainGuiPath+"VBoxProperties/random").hide()

#----------------- GUI Helper functions ------------------#
func setCollisionPolygonCheck(newValue):
	checkCollision = newValue

func setImageCheck(newValue):
	checkImage = newValue

func setNavigationCheck(newValue):
	checkNavigation = newValue

func setOccluderCheck(newValue):
	checkOccluder = newValue

func setGetPolygonFromCollisionCheck(newValue):
	getPolygonFromCollision = newValue

func lockProperties():
	get_node(mainGuiPath+"VBoxContainer3/properties").set_text("Add Tiles Properties")
	get_node(mainGuiPath+"VBoxContainer3/properties").set_disabled(true)
	get_node(mainGuiPath+"VBoxProperties").hide()

func resetPropertyImage():
	var _texture = load("res://addons/ch.fischspiele.tilesethelper/images/gui_image_single.png")
	get_node(mainGuiPath+"VBoxProperties/random/ImageContainer1/TextureFrame").set_texture(_texture)

func getShaderCodeFromCeckbox(_material):
	var _stateFlipX = str(_material.get_shader_param("flipX"))
	var _stateFlipY = str(_material.get_shader_param("flipY"))
	var _stateRandom = _material.get_shader_param("random")
	return "uniform bool flipX = "+_stateFlipX.to_lower()+";\nuniform bool flipY = "+_stateFlipY.to_lower()+";\nuniform bool random = "+str(_stateRandom).to_lower()+";"

func disableFramesGui():
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").set_text("0")
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_text("0")
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").set_editable(false)
	get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame2").set_editable(false)
	vFrames = 0
	hFrames = 0

#----------------- Helper functions ------------------#
func getFileName(_path):
	var _fileName = _path.substr(_path.find_last("/")+1, _path.length() - _path.find_last("/")-1)
	var _dotPos = _fileName.find_last(".")
	if _dotPos != -1:
		_fileName = _fileName.substr(0,_dotPos)
	return _fileName