tool
extends PanelContainer

var tileSize = 64
var oneImageSelected = false
var oneImageSelectedSize = Vector2(0,0)
var hFrames = 0
var vFrames = 0
var getPolygonFromCollision = false
var checkCollision = false
var checkNavigation = false
var checkImage = false
var checkOccluder = false
var mainGuiPath = "HBoxContainer/"
var imagesPath
var selectedNodes
var tilePropertiesNode
var editorPlugin

func _ready():
	tilePropertiesNode = get_tree().get_nodes_in_group("tilesethelper_properties")[0]
	tilePropertiesNode.propertyItem.propertyTextureBtn.connect("pressed",self,"show_dialog",["propertyImage"])
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
	changePropertiesVisible(false)
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
	var fileDialog = EditorFileDialog.new()
	editorPlugin.get_base_control().add_child(fileDialog)
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
		disableFramesGui()

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
	var _root =  get_tree().get_edited_scene_root()
	if get_node(mainGuiPath+"VBoxContainer/HBoxImageFrame/frame1").is_editable():
		print("creating ",imagesPath.size()," frame sprites from selection")
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
				var _imageName = get_node(mainGuiPath+"VBoxContainer/HBoxImage/VBoxImage/name/lblName").get_text()+str(_frame)
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
		print("creating ",imagesPath.size()," sprites from selection")
		for _imagePath in imagesPath:
			var _newTexture  = ImageTexture.new()
			_newTexture.load(_imagePath)
			_newTexture.set_flags(0)
			tileSize = _newTexture.get_width()
			var _imageName = getFileName(_imagePath)
			var _newSpriteNode
			print(_imageName)
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
func changePropertiesVisible(_value):
	get_node(mainGuiPath+"/VBoxProperties/lable").set("visibility/visible",_value)
	get_node(mainGuiPath+"/VBoxProperties/HSeparator").set("visibility/visible",_value)
	get_node(mainGuiPath+"/VBoxProperties/properties").set("visibility/visible",_value)

func on_files_selected_property(imagePathArray,_fileDialog):
	imagesPath = imagePathArray
	var _newTexture  = ImageTexture.new()
	if imagePathArray.size() == 1:
		_newTexture.load(imagePathArray[0])
		var _newTextureWidth = _newTexture.get_width()
		var _newTextureHeight = _newTexture.get_height()
		if _newTextureWidth > 64 || _newTextureHeight > 64:
			_newTexture.set_size_override(Vector2(64,64))
		tilePropertiesNode.setTexturePropertyImage(_newTexture)
	_fileDialog.queue_free()

func on_selection_changed():
	if selectedNodes.size() == 1:
		var _selectedNode = selectedNodes[0]
		tilePropertiesNode.getPropertiesFromShader(_selectedNode)
		if _selectedNode.get_type() == "Sprite":
			if editorPlugin.isPropertiesAvailable:
				changePropertiesVisible(true)
		else:
			changePropertiesVisible(false)
	else:
		changePropertiesVisible(false)

#----------------- GUI Helper functions ------------------#
func setCollisionPolygonCheck(_newValue):
	print("set CollisionPolygonCheck to ",_newValue)
	checkCollision = _newValue

func setImageCheck(_newValue):
	print("set ImageCheck to ",_newValue)
	checkImage = _newValue

func setNavigationCheck(_newValue):
	print("set NavigationCheck to ",_newValue)
	checkNavigation = _newValue

func setOccluderCheck(_newValue):
	print("set OccluderCheck to ",_newValue)
	checkOccluder = _newValue

func setGetPolygonFromCollisionCheck(_newValue):
	print("set GetPolygonFromCollisionCheck to ",_newValue)
	getPolygonFromCollision = _newValue

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