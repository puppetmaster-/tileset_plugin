tool
extends EditorPlugin

var dock = null
var tileSize = 64
var getPolygonFromCollision = true
var checkCollision = false
var checkNavigation = false
var checkImage = false
var checkOccluder = false
var mainGuiPath = "VBoxContainer/PanelContainer/VBoxContainer/"
var imagesPath
var fileDialog = null

func _enter_tree():
	dock = preload("res://addons/tileset_dock/tileset_dock.tscn").instance()
	#image
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/size/x").connect("text_changed",self,"tilesize")
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/size/x").set_text(str(tileSize))
	dock.get_node(mainGuiPath+"HBoxImage/CheckBox").connect("toggled",self,"setImageCheck")
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

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

func collisionPolygon():
	print("add/remove collisionPolygon")
	for n in get_selection().get_selected_nodes():
		setCollisionPolygon(n)

func setCollisionPolygon(n):
	if n.get_owner() != null:
		var owner = n.get_owner()
		var _node = setStaticBody(n,owner)
		var _node2 = CollisionPolygon2D.new()
		_node2.set_polygon(getVector2ArrayFromSprite(n))
		_node2.set_name("CollisionPolygon2D")
		_node.add_child(_node2)
		_node2.set_owner(owner)
	else:
		print("Error: root node selected")

func occluder():
	print("add/remove occluder")
	for n in get_selection().get_selected_nodes():
		setOccluder(n)

func setOccluder(n):
	if n.get_owner() != null:
		if n.get_type() == "Sprite":
			if n.has_node("LightOccluder2D"):
				print("deleting LightOccluder2D")
				n.remove_child(n.get_node("LightOccluder2D"))
			var _node = LightOccluder2D.new()
			_node.set_occluder_polygon(getOccPolygon2D(n))
			_node.set_name("LightOccluder2D")
			n.add_child(_node)
			_node.set_owner(n.get_parent())
		else:
			print("Error: no sprite selected")
	else:
		print("Error: root node selected")

func navigation():
	print("add/remove navigation")
	for n in get_selection().get_selected_nodes():
		setNavigation(n)

func setNavigation(n):
	if n.get_owner() != null:
		if n.get_type() == "Sprite":
			if n.has_node("NavigationPolygonInstance"):
				n.remove_child(n.get_node("NavigationPolygonInstance"))
			var _node = NavigationPolygonInstance.new()
			_node.set_navigation_polygon(getNavPolygon(n))
			_node.set_name("NavigationPolygonInstance")
			n.add_child(_node)
			_node.set_owner(n.get_parent())
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
	print("set tilesize to: ", newTileSize)
	tileSize = int(newTileSize)

func setStaticBody(selectedNode,owner):
	if selectedNode.has_node("StaticBody2D"):
		selectedNode.remove_child(selectedNode.get_node("StaticBody2D"))
	var _node = StaticBody2D.new()
	_node.set_name("StaticBody2D")
	var _cps = ConvexPolygonShape2D.new()
	_cps.set_points(getVector2ArrayFromSprite(selectedNode))
	_node.clear_shapes()
	_node.add_shape(_cps)
	selectedNode.add_child(_node)
	_node.set_owner(owner)
	return _node

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
	print("set checkCollision to: ", newValue)
	checkCollision = newValue
	
func setImageCheck(newValue):
	print("set checkImage to: ", newValue)
	checkImage = newValue

func setNavigationCheck(newValue):
	print("set checkNavigation to: ", newValue)
	checkNavigation = newValue

func setOccluderCheck(newValue):
	print("set checkOccluder to: ", newValue)
	checkOccluder = newValue

func setGetPolygonFromCollisionCheck(newValue):
	print("set getPolygonFromCollision to: ", newValue)
	getPolygonFromCollision = newValue

func on_files_selected(_aPath):
	imagesPath = _aPath
	var image  = ImageTexture.new()
	var imageName
	var imageSize
	dock.get_node(mainGuiPath+"HBoxImage/CheckBox").set_pressed(true)
	setImageCheck(true)
	if _aPath.size() == 1:
		image.load(_aPath[0])
		imageSize = image.get_width()
		if image.get_width() > 64 || image.get_height() > 64:
			image.set_size_override(Vector2(64,64))
		imageName = getFileName(_aPath[0])
	else:
		imageSize = ""
		image.load("res://addons/tileset_dock/multiple.png")
		imageName = "..."
	
	dock.get_node(mainGuiPath+"HBoxImage/ImageContainer/TextureFrame").set_texture(image)
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/size/x").set_text(str(imageSize))
	#dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/size/y").set_text(str(image.get_height()))
	dock.get_node(mainGuiPath+"HBoxImage/VBoxImage/name/lblName").set_text(imageName)

func getFileName(_path):
	var _fileName = _path.substr(_path.find_last("/")+1, _path.length() - _path.find_last("/")-1)
	var _dotPos = _fileName.find_last(".")
	if _dotPos != -1:
		_fileName = _fileName.substr(0,_dotPos)
	return _fileName

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
	for _path in imagesPath:
		var _image  = ImageTexture.new()
		_image.load(_path)
		tileSize = _image.get_width()
		var _imageName = getFileName(_path)
		var _spriteNode
		if !_root.has_node(_imageName):
			_spriteNode = Sprite.new()
			_spriteNode.set_texture(_image)
			_root.add_child(_spriteNode)
			_spriteNode.set_pos(Vector2(0,0))
			_spriteNode.set_owner(_root)
			_spriteNode.set_name(_imageName)
		else:
			_spriteNode = _root.get_node(_imageName)
			_spriteNode.set_texture(_image)
		if checkCollision:
			setCollisionPolygon(_spriteNode)
		if checkNavigation:
			setNavigation(_spriteNode)
		if checkOccluder:
			setOccluder(_spriteNode)
	
	
	
	
	
	