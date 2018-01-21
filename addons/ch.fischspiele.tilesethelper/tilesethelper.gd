tool
extends EditorPlugin

var dock = null
var toolButton = null

func _enter_tree():
	dock = preload("res://addons/ch.fischspiele.tilesethelper/tilesethelper_dock.tscn").instance()
	get_selection().connect("selection_changed", self, "on_selection_changed")
	toolButton = add_control_to_bottom_panel(dock,"TileSet Helper")
	toolButton.connect("pressed",self,"on_selection_changed")

func _exit_tree():
	remove_control_from_bottom_panel(dock)
	if dock:
		dock.queue_free()

func on_selection_changed():
	if toolButton.is_pressed(): #only react when TileSet Helper is visible
		dock.selectedNodes = get_selection().get_selected_nodes()
		dock.on_selection_changed()