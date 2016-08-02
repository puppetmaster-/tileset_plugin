tool
extends EditorPlugin

var dock = null
var tileSize = 64
var getPolygonFromCollision = true

func _enter_tree():
	dock = preload("res://addons/tileset_dock/tileset_dock.tscn").instance()
	dock.get_node("VBoxContainer/PanelContainer/VBoxContainer/collisionPolygon").connect("pressed",self,"collisionPolygon")
	dock.get_node("VBoxContainer/PanelContainer/VBoxContainer/collisionShape").connect("pressed",self,"collisionShape")
	dock.get_node("VBoxContainer/PanelContainer/VBoxContainer/occluder").connect("pressed",self,"occluder")
	dock.get_node("VBoxContainer/PanelContainer/VBoxContainer/navigation").connect("pressed",self,"navigation")
	dock.get_node("VBoxContainer/HBoxContainer/tilesize").connect("text_changed",self,"tilesize")
	dock.get_node("VBoxContainer/HBoxContainer/tilesize").set_text(str(tileSize))
	dock.get_node("VBoxContainer/PanelContainer/VBoxContainer/CheckGetPolyColli").connect("toggled",self,"checkPolygonCollision")
	dock.get_node("VBoxContainer/PanelContainer/VBoxContainer/CheckGetPolyColli").set_toggle_mode(getPolygonFromCollision)
	add_control_to_dock( DOCK_SLOT_RIGHT_BL, dock )

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

func collisionPolygon():
	print("add/remove collisionPolygon")
	for n in get_selection().get_selected_nodes():
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

func collisionShape():
	print("add/remove collisionShape")
	for n in get_selection().get_selected_nodes():
		if n.get_owner() != null:
			var owner = n.get_owner()
			var _node = setStaticBody(n,owner)
			var _node2 = CollisionShape2D.new()
			var _recShape = RectangleShape2D.new()
			_recShape.set_extents(Vector2(tileSize/2,tileSize/2))
			_node2.set_shape(_recShape)
			_node2.set_name("CollisionShape2D")
			_node.add_child(_node2)
			_node2.set_owner(owner)
		else:
			print("Error: root node selected")

func occluder():
	print("add/remove occluder")
	for n in get_selection().get_selected_nodes():
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

func checkPolygonCollision(newValue):
	print("set check to: ", newValue)
	getPolygonFromCollision = newValue

func setStaticBody(selectedNode,owner):
	if selectedNode.has_node("StaticBody2D"):
		selectedNode.remove_child(selectedNode.get_node("StaticBody2D"))
	var _node = StaticBody2D.new()
	_node.set_name("StaticBody2D")
	selectedNode.add_child(_node)
	_node.set_owner(owner)
	return _node