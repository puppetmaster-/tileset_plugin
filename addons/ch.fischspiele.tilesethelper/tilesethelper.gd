tool
extends EditorPlugin

var dock = null
var tileSize = 64
var oneImageSelected = false
var oneImageSelectedSize = 0
var hFrames = 0
var vFrames = 0
var getPolygonFromCollision = true
var checkCollision = false
var checkNavigation = false
var checkImage = false
var checkOccluder = false
var mainGuiPath = "VBoxContainer/PanelContainer/VBoxContainer/"
var imagesPath
var fileDialog = null
var lastPosition
var gap = 10

func _enter_tree():
	dock = preload("res://addons/ch.fischspiele.tilesethelper/tilesethelper_dock.tscn").instance()
	#image
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/sizeBox/size").connect("text_changed",self,"updateTilesize")
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/sizeBox/size").set_text(str(tileSize))
	dock.get_node(mainGuiPath+"HBoxImage/CheckBox").connect("toggled",self,"setImageCheck")
	#frames
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_text("0")
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_text("0")
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_editable(false)
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_editable(false)
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
	dock.get_node(mainGuiPath+"HBoxSettings/CheckGetPolyColli").set_toggle_mode(getPolygonFromCollision)
	#tiles
	dock.get_node(mainGuiPath+"create_tiles").connect("pressed",self,"create_tiles")
	add_control_to_dock( DOCK_SLOT_RIGHT_BL, dock )


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
	if _root != null:
		lastPosition = getStartingPosition()
		if dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").is_editable():
			#Image cutting
			for _imagePath in imagesPath:
				var _newTexture  = ImageTexture.new()
				_newTexture.load(_imagePath)
				_newTexture.set_flags(0)
				var _startFrame = int(dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").get_text())
				var _endFrame = int(dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").get_text())
				for _frame in range(_startFrame,_endFrame):
					var column = int(_frame)%int(hFrames)
					var row = int(_frame/hFrames)
					var newPosition = Vector2(column*(tileSize+gap),lastPosition.y+row*(tileSize+gap))
					var _imageName = getFileName(_imagePath)+str(_frame)
					var _newSpriteNode
					if !_root.has_node(_imageName):
						_newSpriteNode = Sprite.new()
						_newSpriteNode.set_texture(_newTexture)
						_newSpriteNode.set_vframes(vFrames)
						_newSpriteNode.set_hframes(hFrames)
						_newSpriteNode.set_frame(_frame)
						_root.add_child(_newSpriteNode)
						_newSpriteNode.set_pos(newPosition)
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
					_newSpriteNode.set_pos(lastPosition)
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
				lastPosition = Vector2(lastPosition.x+tileSize+gap,lastPosition.y)
	else:
		printerr("ERROR: no root node found")

func collisionPolygon():
	print("add/remove collisionPolygon")
	for seletedNode in get_selection().get_selected_nodes():
		setCollisionPolygon(seletedNode)

func setCollisionPolygon(seletedNode):
	if seletedNode.get_owner() != null:
		var _owner = seletedNode.get_owner()
		var _newStaticBodyNode = setStaticBody(seletedNode,_owner)
		var _newCollisionPolygonNode = CollisionPolygon2D.new()
		_newCollisionPolygonNode.set_polygon(getVector2ArrayFromSprite(seletedNode))
		_newCollisionPolygonNode.set_name("CollisionPolygon2D")
		_newCollisionPolygonNode.set_meta("_edit_lock_",true)
		_newStaticBodyNode.add_child(_newCollisionPolygonNode)
		_newStaticBodyNode.set_meta("_edit_lock_",true)
		_newCollisionPolygonNode.set_owner(_owner)
	else:
		printerr("ERROR: root node selected")

func occluder():
	print("add/remove occluder")
	for seletedNode in get_selection().get_selected_nodes():
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
			_newLightOccluderNode.set_meta("_edit_lock_",true)
			seletedNode.add_child(_newLightOccluderNode)
			_newLightOccluderNode.set_owner(seletedNode.get_parent())
		else:
			printerr("ERROR: no sprite selected")
	else:
		printerr("ERROR: root node selected")

func navigation():
	print("add/remove navigation")
	for seletedNode in get_selection().get_selected_nodes():
		setNavigation(seletedNode)

func setNavigation(seletedNode):
	if seletedNode.get_owner() != null:
		if seletedNode.get_type() == "Sprite":
			if seletedNode.has_node("NavigationPolygonInstance"):
				seletedNode.remove_child(seletedNode.get_node("NavigationPolygonInstance"))
			var _newNavigationPolygonNode = NavigationPolygonInstance.new()
			_newNavigationPolygonNode.set_navigation_polygon(getNavPolygon(seletedNode))
			_newNavigationPolygonNode.set_name("NavigationPolygonInstance")
			_newNavigationPolygonNode.set_meta("_edit_lock_",true)
			seletedNode.add_child(_newNavigationPolygonNode)
			_newNavigationPolygonNode.set_owner(seletedNode.get_parent())
		else:
			printerr("ERROR: no sprite selected")
	else:
		printerr("ERROR: root node selected")

func getVector2ArrayFromSprite(selectedNode):
	var _Array = []
	var _Vector2Array = Vector2Array(_Array)
	_Vector2Array.append(Vector2(-tileSize/2,-tileSize/2))
	_Vector2Array.append(Vector2(tileSize/2,-tileSize/2))
	_Vector2Array.append(Vector2(tileSize/2,tileSize/2))
	_Vector2Array.append(Vector2(-tileSize/2,tileSize/2))
	return _Vector2Array

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

###
### - - Events
###
func updateTilesize(newTileSize):
	tileSize = int(newTileSize)
	gap = int(tileSize/2)
	if tileSize < oneImageSelectedSize.x && tileSize > 0 && isImageSizePowerOf2(oneImageSelectedSize):
		var _newTexture  = ImageTexture.new()
		_newTexture.load("res://addons/ch.fischspiele.tilesethelper/gui_image_tileset.png")
		hFrames = oneImageSelectedSize.x/tileSize
		vFrames = oneImageSelectedSize.y/tileSize
		dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_text("0")
		dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_text(str(hFrames*vFrames))
		dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_editable(true)
		dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_editable(true)
	else:
		disableFramesGui()

func on_files_selected(imagePathArray):
	imagesPath = imagePathArray
	var _newTexture  = ImageTexture.new()
	var _newName
	var _newSize
	dock.get_node(mainGuiPath+"HBoxImage/CheckBox").set_pressed(true)
	setImageCheck(true)
	disableFramesGui()
	if imagePathArray.size() == 1:
		oneImageSelected = true
		_newTexture.load(imagePathArray[0])
		_newSize = _newTexture.get_width()
		oneImageSelectedSize = Vector2(_newTexture.get_width(),_newTexture.get_height())
		if isImageSizePowerOf2(oneImageSelectedSize):
			dock.get_node(mainGuiPath+"HBoxImageFrame").show()
		if _newTexture.get_width() > 64 || _newTexture.get_height() > 64:
			_newTexture.set_size_override(Vector2(64,64))
		_newName = getFileName(imagePathArray[0])
	else:
		oneImageSelected = false
		oneImageSelectedSize = Vector2(0,0)
		_newSize = ""
		_newTexture.load("res://addons/ch.fischspiele.tilesethelper/gui_image_multiple.png")
		_newName = "..."
	
	dock.get_node(mainGuiPath+"HBoxImage/ImageContainer/TextureFrame").set_texture(_newTexture)
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/sizeBox/size").set_text(str(_newSize))
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/lblName").set_text(_newName)

###
###  - - GUI Helper functions
###
func show_dialog():
	if fileDialog == null:
		fileDialog = FileDialog.new()
		get_parent().add_child(fileDialog)
	
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

func disableFramesGui():
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_text("0")
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_text("0")
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame1").set_editable(false)
	dock.get_node(mainGuiPath+"HBoxImageFrame/frame2").set_editable(false)
	vFrames = 0
	hFrames = 0

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

###
### - - Helper functions
###
func getVector2ArrayFromCollision(selectedNode):
	return selectedNode.get_node("StaticBody2D/CollisionPolygon2D").get_polygon() 

func getFileName(_path):
	var _fileName = _path.substr(_path.find_last("/")+1, _path.length() - _path.find_last("/")-1)
	var _dotPos = _fileName.find_last(".")
	if _dotPos != -1:
		_fileName = _fileName.substr(0,_dotPos)
	return _fileName

func isImageSizePowerOf2(_imageSize):
	var _status = 0
	var _power2List = [2,4,8,16,32,64,128,256,512,1024,2048,4096,8192]
	for _power2Number in _power2List:
		if _imageSize.x == _power2Number:
			_status += 1
		if _imageSize.y == _power2Number:
			_status += 1
	if _status != 2:
		dock.get_node(mainGuiPath+"HBoxImageFrame").hide()
		print("WARN: selected image is not power of 2, frames disabled")
	return _status == 2

func getStartingPosition():
	var _root =  get_tree().get_edited_scene_root()
	if _root.get_children().size() == 0:
		return Vector2(0,0)
	else:
		var yPos = 0
		for child in _root.get_children():
			if child.get_pos().y > yPos:
				 yPos = child.get_pos().y
		return Vector2(0,yPos+(tileSize+gap))
			