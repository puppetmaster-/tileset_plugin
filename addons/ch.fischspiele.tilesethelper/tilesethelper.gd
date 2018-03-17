tool
extends EditorPlugin

var dock = null
var tileSize = 64
var oneImageSelected = false
var oneImageSelectedSize = Vector2(0,0)
var hFrames = 0
var vFrames = 0
var getPolygonFromCollision = false # todo true not working
var checkCollision = false
var checkNavigation = false
var checkImage = false
var checkOccluder = false
var mainGuiPath = "VBoxContainer/"
var imagesPath
var fileDialog = null

func _enter_tree():
	dock = preload("res://addons/ch.fischspiele.tilesethelper/tilesethelper_dock.tscn").instance()
	#image
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/sizeBox/size").connect("text_changed",self,"tilesize")
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/sizeBox/size").set_text(str(tileSize))
	dock.get_node(mainGuiPath+"HBoxImage/CheckBox").connect("toggled",self,"setImageCheck")
	#frames
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_text("0")
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_text("0")
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_editable(false)
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_editable(false)
	#Offset
	dock.get_node(mainGuiPath+"HBoxFrameOffset/XOffset").set_text("0")
	dock.get_node(mainGuiPath+"HBoxFrameOffset/YOffset").set_text("0")
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_editable(true)
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_editable(true)
	#dialog
	dock.get_node(mainGuiPath+"HBoxImage/ImageContainer/btnImage").connect("pressed",self,"show_dialog")
	#collision
	dock.get_node(mainGuiPath+"HBoxCollision/collisionPolygon").connect("pressed",self,"collisionPolygon")
	dock.get_node(mainGuiPath+"HBoxCollision/CheckBox").connect("toggled",self,"setCollisionPolygonCheck")
	#navigation
	dock.get_node(mainGuiPath+"HBoxNavigation/navigation").connect("pressed",self,"navigation")
	dock.get_node(mainGuiPath+"HBoxNavigation/CheckBox").connect("toggled",self,"setNavigationCheck")
	#occluder
	dock.get_node(mainGuiPath+"HBoxOccluder/occluder").connect("pressed",self,"occluder")
	dock.get_node(mainGuiPath+"HBoxOccluder/CheckBox").connect("toggled",self,"setOccluderCheck")
	#settings
	dock.get_node(mainGuiPath+"HBoxSettings/CheckGetPolyColli").connect("toggled",self,"setGetPolygonFromCollisionCheck")
	#dock.get_node(mainGuiPath+"HBoxSettings/CheckGetPolyColli").set_toggle_mode(getPolygonFromCollision)
	#tiles
	dock.get_node(mainGuiPath+"create_tiles").connect("pressed",self,"create_tiles")
	add_control_to_dock( DOCK_SLOT_RIGHT_BL, dock )

func collisionPolygon():
	print("add/remove collisionPolygon")
	for _selectedNode in get_editor_interface().get_selection().get_selected_nodes():
		setCollisionPolygon(_selectedNode)

func setCollisionPolygon(_selectedNode):
	if _selectedNode.get_owner() != null:
		var _owner = _selectedNode.get_owner()
		var _newStaticBodyNode = setStaticBody(_selectedNode,_owner)
		var _newCollisionPolygonNode = CollisionPolygon2D.new()
		_newCollisionPolygonNode.set_polygon(getVector2ArrayFromSprite(_selectedNode))
		_newCollisionPolygonNode.set_name("CollisionPolygon2D")
		_newStaticBodyNode.add_child(_newCollisionPolygonNode)
		_newCollisionPolygonNode.set_owner(_owner)
	else:
		print("Error: root node selected")

func setStaticBody(_selectedNode,_owner):
	if _selectedNode.has_node("StaticBody2D"):
		_selectedNode.remove_child(_selectedNode.get_node("StaticBody2D"))
	var _newStaticBodyNode = StaticBody2D.new()
	_newStaticBodyNode.set_name("StaticBody2D")
	_selectedNode.add_child(_newStaticBodyNode)
	_newStaticBodyNode.set_owner(_owner)
	return _newStaticBodyNode

func occluder():
	print("add/remove occluder")
	for _selectedNode in get_editor_interface().get_selection().get_selected_nodes():
		setOccluder(_selectedNode)

func setOccluder(_selectedNode):
	if _selectedNode.get_owner() != null:
		if _selectedNode is Sprite:
			if _selectedNode.has_node("LightOccluder2D"):
				print("deleting LightOccluder2D")
				_selectedNode.remove_child(_selectedNode.get_node("LightOccluder2D"))
			var _newLightOccluderNode = LightOccluder2D.new()
			_newLightOccluderNode.set_occluder_polygon(getOccPolygon2D(_selectedNode))
			_newLightOccluderNode.set_name("LightOccluder2D")
			_selectedNode.add_child(_newLightOccluderNode)
			_newLightOccluderNode.set_owner(_selectedNode.get_parent())
		else:
			print("Error: no sprite selected")
	else:
		print("Error: root node selected")

func navigation():
	print("add/remove navigation")
	for _selectedNode in get_editor_interface().get_selection().get_selected_nodes():
		setNavigation(_selectedNode)

func setNavigation(_selectedNode):
	if _selectedNode.get_owner() != null:
		if _selectedNode is Sprite:
			if _selectedNode.has_node("NavigationPolygonInstance"):
				_selectedNode.remove_child(_selectedNode.get_node("NavigationPolygonInstance"))
			var _newNavigationPolygonNode = NavigationPolygonInstance.new()
			_newNavigationPolygonNode.set_navigation_polygon(getNavPolygon(_selectedNode))
			_newNavigationPolygonNode.set_name("NavigationPolygonInstance")
			_selectedNode.add_child(_newNavigationPolygonNode)
			_newNavigationPolygonNode.set_owner(_selectedNode.get_parent())
		else:
			print("Error: no sprite selected")
	else:
		print("Error: root node selected")

func getVector2ArrayFromSprite(_selectedNode):
	var _Array = []
	var _Vector2Array = PoolVector2Array(_Array)
	_Vector2Array.append(Vector2(-tileSize/2,-tileSize/2))
	_Vector2Array.append(Vector2(tileSize/2,-tileSize/2))
	_Vector2Array.append(Vector2(tileSize/2,tileSize/2))
	_Vector2Array.append(Vector2(-tileSize/2,tileSize/2))
	return _Vector2Array

func getVector2ArrayFromCollision(_selectedNode):
	return _selectedNode.get_node("StaticBody2D/CollisionPolygon2D").get_polygon()

func getNavPolygon(_selectedNode):
	var _navPoly = NavigationPolygon.new()
	var _polyArray = null
	if getPolygonFromCollision:
		_polyArray = getVector2ArrayFromCollision(_selectedNode)
	else:
		_polyArray = getVector2ArrayFromSprite(_selectedNode)
	_navPoly.add_outline(_polyArray)
	_navPoly.add_polygon(PoolIntArray([0, 1, 2, 3]))
	_navPoly.set_vertices(_polyArray)
	return _navPoly

func getOccPolygon2D(_selectedNode):
	var _occPoly = OccluderPolygon2D.new()
	var _polyArray = null
	if getPolygonFromCollision:
		_polyArray = getVector2ArrayFromCollision(_selectedNode)
	else:
		_polyArray = getVector2ArrayFromSprite(_selectedNode)
	_occPoly.set_polygon(_polyArray)
	return _occPoly

func tilesize(_newTileSize):
	tileSize = int(_newTileSize)
	if (tileSize < oneImageSelectedSize.x && tileSize > 0) || (oneImageSelectedSize.x != oneImageSelectedSize.y && tileSize > 0):
		hFrames = oneImageSelectedSize.x/tileSize
		vFrames = oneImageSelectedSize.y/tileSize
		dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").text = "0"
		dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").text = str(hFrames*vFrames)
		dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_editable(true)
		dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_editable(true)
	else:
		disableFramesGui()


func show_dialog():
	if fileDialog == null:
		fileDialog = EditorFileDialog.new()
		get_editor_interface().get_base_control().add_child(fileDialog) #get theme from editor

	fileDialog.set_mode(FileDialog.MODE_OPEN_FILES)
	fileDialog.set_current_path("res://")
	fileDialog.set_access(FileDialog.ACCESS_RESOURCES)
	fileDialog.clear_filters()
	fileDialog.add_filter("*.png ; PNG Images");
	fileDialog.set_custom_minimum_size(Vector2(500,500))
	fileDialog.popup_centered()
	fileDialog.show()
	if not fileDialog.is_connected("files_selected",self,"on_files_selected"):
		fileDialog.connect("files_selected",self,"on_files_selected")

func on_files_selected(_imagePathArray):
	imagesPath = _imagePathArray
	var _newTexture  = ImageTexture.new()
	var _newName
	var _newSize
	dock.get_node(mainGuiPath+"HBoxImage/CheckBox").set_pressed(true)
	setImageCheck(true)
	if _imagePathArray.size() == 1:
		oneImageSelected = true
		_newTexture.load(_imagePathArray[0])
		var _newTextureWidth = _newTexture.get_width()
		var _newTextureHeight = _newTexture.get_height()
		if _newTextureWidth == _newTextureHeight:
			_newSize = _newTextureWidth
			disableFramesGui()
		elif _newTextureWidth < _newTextureHeight:
			_newSize = _newTextureWidth
			dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").text = str(_newTextureHeight/_newSize)
		else:
			_newSize = _newTextureHeight
			dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").text = str(_newTextureWidth/_newSize)
		oneImageSelectedSize = Vector2(_newTextureWidth,_newTextureHeight)
		if _newTextureWidth > 64 || _newTextureHeight > 64:
			_newTexture.set_size_override(Vector2(64,64))
		_newName = getFileName(_imagePathArray[0])
	else:
		oneImageSelected = false
		oneImageSelectedSize = Vector2(0,0)
		_newSize = ""
		_newTexture.load("res://addons/ch.fischspiele.tilesethelper/gui_image_multiple.png")
		_newName = "..."
	dock.get_node(mainGuiPath+"HBoxImage/ImageContainer/TextureFrame").texture = _newTexture
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/sizeBox/size").text = str(_newSize)
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/name/lblName").text = _newName
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").text ="0"

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
	if dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").is_editable():
		for _imagePath in imagesPath:
			var _newTexture  = null
			_newTexture = ResourceLoader.load(_imagePath,"ImageTexture")
			_newTexture.set_flags(0)
			var _startFrame = int(dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").text)
			var _endFrame = int(dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").text)
			var offsetX = int(dock.get_node(mainGuiPath+"HBoxFrameOffset/XOffset").text)
			var offsetY = int(dock.get_node(mainGuiPath+"HBoxFrameOffset/YOffset").text)
			var tilesWide = int((_newTexture.get_size().x + offsetX) / (int(tileSize) + offsetX))
			var tilesTall = int((_newTexture.get_size().y + offsetY) / (int(tileSize) + offsetY))
			for _frame in range(_startFrame,_endFrame):
				var _imageName = dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/name/lblName").get_text()+str(_frame)
				var _newSpriteNode
				if !_root.has_node(_imageName):
					_newSpriteNode = Sprite.new()
					_newSpriteNode.texture = _newTexture
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
						var _position = Vector2 ((tmpX + int(tileSize)) * (int(_frame) % tilesWide) , (tmpY + int(tileSize)) * int((int(_frame) / tilesWide)))
						_newSpriteNode.set_region_rect( Rect2( _position, Vector2(int(tileSize), int(tileSize))) )
						_newSpriteNode.position = _position
					else:
						_newSpriteNode.position = Vector2(0,0)
					
					_newSpriteNode.set_frame(_frame)
					_root.add_child(_newSpriteNode)
					_newSpriteNode.set_owner(_root)
					_newSpriteNode.set_name(_imageName)
				else:
					_newSpriteNode = _root.get_node(_imageName)
					_newSpriteNode.texture = _newTexture
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
		for i in range(imagesPath.size()):
			var _imagePath = imagesPath[i]
			print(_imagePath)
			var _newTexture  = null
			_newTexture = ResourceLoader.load(_imagePath,"ImageTexture")
			_newTexture.set_flags(0)
			tileSize = _newTexture.get_width()
			var _imageName = getFileName(_imagePath)
			var _newSpriteNode
			if !_root.has_node(_imageName):
				_newSpriteNode = Sprite.new()
				_newSpriteNode.texture = _newTexture
				_root.add_child(_newSpriteNode)
				_newSpriteNode.position = Vector2(tileSize*i,0)
				_newSpriteNode.set_owner(_root)
				_newSpriteNode.set_name(_imageName)
			else:
				_newSpriteNode = _root.get_node(_imageName)
				_newSpriteNode.texture = _newTexture
			if checkCollision:
				setCollisionPolygon(_newSpriteNode)
			if checkNavigation:
				setNavigation(_newSpriteNode)
			if checkOccluder:
				setOccluder(_newSpriteNode)

###
###  - - GUI Helper functions
###
func setCollisionPolygonCheck(_newValue):
	checkCollision = _newValue

func setImageCheck(_newValue):
	checkImage = _newValue

func setNavigationCheck(_newValue):
	checkNavigation = _newValue

func setOccluderCheck(_newValue):
	checkOccluder = _newValue

func setGetPolygonFromCollisionCheck(_newValue):
	print("setGetPolygonFromCollisionCheck",_newValue)
	getPolygonFromCollision = _newValue

func disableFramesGui():
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").text = "0"
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").text = "0"
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_editable(false)
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_editable(false)
	vFrames = 0
	hFrames = 0

func _exit_tree():
	remove_control_from_docks(dock)
	if dock:
		dock.queue_free()

###
### - - Helper functions
###
func getFileName(_path):
	var _fileName = _path.substr(_path.find_last("/")+1, _path.length() - _path.find_last("/")-1)
	var _dotPos = _fileName.find_last(".")
	if _dotPos != -1:
		_fileName = _fileName.substr(0,_dotPos)
	return _fileName
