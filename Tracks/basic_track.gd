extends Node2D
func getTrackTiles() -> Array[Vector2i]:
	return $TileMapLayer2.get_used_cells()
