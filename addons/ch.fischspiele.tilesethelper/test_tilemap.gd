extends TileMap

func _ready():
	randomize()
	prepareTileMap()

func prepareTileMap():
	var _tileset = get_tileset()
	for _cell in get_used_cells():
		var _id = get_cellv(_cell)
		var _material = _tileset.tile_get_material(_id)
		if _material != null:
			var flip_x = is_cell_x_flipped(_cell.x,_cell.y)
			var flip_y = is_cell_y_flipped(_cell.x,_cell.y)
			var transposed = is_cell_transposed(_cell.x,_cell.y)
			if _material.get_shader_param("flipX"):
				var _flipX = _material.get_shader_param("flipX")
				if _flipX:
					flip_x = randomArrayValue([false,true])
			if _material.get_shader_param("flipY"):
				var _flipY = _material.get_shader_param("flipY")
				if _flipY:
					flip_y = randomArrayValue([false,true])
			var _tileNr = 0
			var _tileNrList = []
			while _material.get_shader_param("tile"+str(_tileNr)) != null:
				_tileNrList.append(_material.get_shader_param("tile"+str(_tileNr)))
				_tileNr += 1
			if _tileNrList.size() > 0:
				_id = randomArrayValue(_tileNrList)
			set_cell(_cell.x,_cell.y,_id,flip_x,flip_y,transposed)

func randomArrayValue(_array):
	return _array[randi()%_array.size()]
	
