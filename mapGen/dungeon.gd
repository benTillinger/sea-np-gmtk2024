extends Node2D

# big green squares = space
# gray = out of bounds
# red = floor
# orange = walls

# CONSTANTS

var DEBUG = true

var tile_size := 64

var source_id := 0

var tileMapFloorVector := Vector2i(0, 8)
var tileMapWallVector := Vector2i(0, 0)
var tileMapCornerVector := Vector2i(5, 0)

var tileMapTopAlt := 0
var tileMapBottomAlt := 1
var tileMapLeftAlt := 2
var tileMapRightAlt := 3

var tileMapTRAlt := 0
var tileMapTLAlt := 5
var tileMapBLAlt := 6
var tileMapBRAlt := 7

@export var default_spawn_percent: float = 0.025

# END CONSTANTS

var root_node: Branch
var tilemap: TileMap
var paths: Array = []

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var biters: Array = []

const ENEMY = preload("res://Entities/Enemies/dummyEnemy.tscn")
const BITE_ATTACK_TIMER = preload("res://Events/Timers/biteAttackTimer.tscn")
#const LIGHTNING_ATTACK_TIMER = preload("res://Entities/Enemies/meleeAttacker.tscn")
#const BULLET_ATTACK_TIMER = preload("res://Entities/Enemies/meleeAttacker.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = get_node("TileMap")
	root_node  = Branch.new(Vector2i(0, 0), Vector2i(90, 30)) # 90 tiles wide and 30 tall
	root_node.split(2, paths)
	setup_timers()
	queue_redraw()

func setup_timers():
	var biteTimer = BITE_ATTACK_TIMER.instantiate()
	#var lightningTimer = LIGHTNING_ATTACK_TIMER.instantiate()
	#var bulletTimer = BULLET_ATTACK_TIMER.instantiate()
	add_child(biteTimer)
	biteTimer.get_child(0).connect("timeout", self._on_biteTimer_timeout)
	#add_child(biteTimer)
	#add_child(biteTimer)

func _draw():	
	for leaf in root_node.get_leaves():
		if (DEBUG):
			draw_rect(
			Rect2(
				leaf.position.x * tile_size, # x
				leaf.position.y * tile_size, # y
				leaf.size.x * tile_size, # width
				leaf.size.y * tile_size # height
			), 
			Color.GREEN, # colour
			false # is filled
		)
		
		var padding = Vector4i(
			rng.randi_range(2,2),
			rng.randi_range(2,2),
			rng.randi_range(2,2),
			rng.randi_range(2,2)
		)
		
		# Render floor
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				# Only render tiles in actual rooms
				var position = Vector2i(x + leaf.position.x,y + leaf.position.y)
				if not leaf.isNotFloorTile(x, y, padding):
					# 1 is the atlas ID
					# 0,8 is the tile location in the atlas
					tilemap.set_cell(0, position, source_id, tileMapFloorVector)
					spawn_enemy(Vector2i(tile_size*position.x, tile_size*position.y), default_spawn_percent)
				elif not leaf.isNotFloorTile(x, y + 1, padding):
					# Render top wall
					tilemap.set_cell(0, position, source_id, tileMapWallVector, tileMapTopAlt)
				elif not leaf.isNotFloorTile(x, y - 1, padding):
					# Render bottom wall
					tilemap.set_cell(0, position, source_id, tileMapWallVector, tileMapBottomAlt)
				elif not leaf.isNotFloorTile(x + 1, y, padding):
					# Render left wall
					tilemap.set_cell(0, position, source_id, tileMapWallVector, tileMapLeftAlt)
				elif leaf.isNotFloorTile(x, y, padding) and not leaf.isNotFloorTile(x - 1, y, padding):
					# Render right wall
					tilemap.set_cell(0, position, source_id, tileMapWallVector, tileMapRightAlt)
				elif leaf.isNotFloorTile(x, y, padding) and leaf.isNotFloorTile(x + 1, y, padding) and leaf.isNotFloorTile(x - 1, y, padding) and leaf.isNotFloorTile(x, y + 1, padding) and leaf.isNotFloorTile(x, y - 1, padding) and not leaf.isNotFloorTile(x + 1, y + 1, padding):
					# Render top left wall
					tilemap.set_cell(0, position, source_id, tileMapCornerVector, tileMapTLAlt)
				elif leaf.isNotFloorTile(x, y, padding) and leaf.isNotFloorTile(x + 1, y, padding) and leaf.isNotFloorTile(x - 1, y, padding) and leaf.isNotFloorTile(x, y + 1, padding) and leaf.isNotFloorTile(x, y - 1, padding) and not leaf.isNotFloorTile(x - 1, y + 1, padding):
					# Render top right wall
					tilemap.set_cell(0, position, source_id, tileMapCornerVector, tileMapTRAlt)
				elif leaf.isNotFloorTile(x, y, padding) and leaf.isNotFloorTile(x + 1, y, padding) and leaf.isNotFloorTile(x - 1, y, padding) and leaf.isNotFloorTile(x, y + 1, padding) and leaf.isNotFloorTile(x, y - 1, padding) and not leaf.isNotFloorTile(x + 1, y - 1, padding):
					# Render bottom left wall
					tilemap.set_cell(0, position, source_id, tileMapCornerVector, tileMapBLAlt)
				elif leaf.isNotFloorTile(x, y, padding) and leaf.isNotFloorTile(x + 1, y, padding) and leaf.isNotFloorTile(x - 1, y, padding) and leaf.isNotFloorTile(x, y + 1, padding) and leaf.isNotFloorTile(x, y - 1, padding) and not leaf.isNotFloorTile(x - 1, y - 1, padding):
					# Render bottom right wall
					tilemap.set_cell(0, position, source_id, tileMapCornerVector, tileMapBRAlt)
					
					
	# Render room connections
	for path in paths:
		if path['left'].y == path['right'].y:
			# horizontal
			for i in range(path['right'].x - path['left'].x):
				var pathPos = Vector2i(path['left'].x+i,path['left'].y)
				var upPos = Vector2i(path['left'].x+i,path['left'].y-1)
				var downPos = Vector2i(path['left'].x+i,path['left'].y+1)
				
				var cellDataBeforePath = tilemap.get_cell_tile_data(0, pathPos)
				var cellDataUp = tilemap.get_cell_tile_data(0, upPos)
				var cellDataDown = tilemap.get_cell_tile_data(0, downPos)
				
				# Now check if the tile to above or below is also dead space
				if cellDataUp == null:
					# Render top wall
					tilemap.set_cell(0, upPos, source_id, tileMapWallVector)
				if cellDataDown == null:
					# Render bottom wall
					tilemap.set_cell(0, downPos, source_id, tileMapWallVector, tileMapBottomAlt)
				
				if cellDataDown != null:
					if tilemap.get_cell_atlas_coords(0, downPos) == tileMapWallVector || tilemap.get_cell_atlas_coords(0, downPos) == tileMapCornerVector:
						# Render bottom wall
						tilemap.set_cell(1, downPos, source_id, tileMapWallVector, tileMapBottomAlt)
				if cellDataUp != null:
					if tilemap.get_cell_atlas_coords(0, upPos) == tileMapWallVector || tilemap.get_cell_atlas_coords(0, upPos) == tileMapCornerVector:
						# Render top wall
						tilemap.set_cell(1, upPos, source_id, tileMapWallVector)
				
				# This means the connecting path we are about to render is in dead space
				if cellDataBeforePath == null:
					pass

				else:
					 # This means we could be breaking down a wall, or just overwriting an existing floor tile
					 # If we're breaking down a wall, also render another wall piece on another layer above or below
					if (tilemap.get_cell_atlas_coords(0, pathPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, pathPos) == tileMapRightAlt):
						if (tilemap.get_cell_atlas_coords(0, upPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, upPos) == tileMapRightAlt) || (tilemap.get_cell_atlas_coords(0, upPos) == tileMapCornerVector):
							# Render top wall
							tilemap.set_cell(1, upPos, source_id, tileMapWallVector)
						if (tilemap.get_cell_atlas_coords(0, downPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, downPos) == tileMapRightAlt) || (tilemap.get_cell_atlas_coords(0, downPos) == tileMapCornerVector):
							# Render bottom wall
							tilemap.set_cell(1, downPos, source_id, tileMapWallVector, tileMapBottomAlt)
					elif (tilemap.get_cell_atlas_coords(0, pathPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, pathPos) == tileMapLeftAlt):
						if (tilemap.get_cell_atlas_coords(0, upPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, upPos) == tileMapLeftAlt) || (tilemap.get_cell_atlas_coords(0, upPos) == tileMapCornerVector):
							# Render top wall
							tilemap.set_cell(1, upPos, source_id, tileMapWallVector)
						if (tilemap.get_cell_atlas_coords(0, downPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, downPos) == tileMapLeftAlt) || tilemap.get_cell_atlas_coords(0, downPos) == tileMapCornerVector:
							# Render bottom wall
							tilemap.set_cell(1, downPos, source_id, tileMapWallVector, tileMapBottomAlt)
				
				# Now draw the path connection tiles
				tilemap.set_cell(0, Vector2i(path['left'].x+i,path['left'].y), source_id, Vector2i(0, 9))
				tilemap.set_cell(1, Vector2i(path['left'].x+i,path['left'].y), source_id, Vector2i(0, 15))
		else:
			# vertical
			pass
			for i in range(path['right'].y - path['left'].y):
				var pathPos = Vector2i(path['left'].x,path['left'].y+i)
				var leftPos = Vector2i(path['left'].x - 1,path['left'].y+i)
				var rightPos = Vector2i(path['left'].x + 1,path['left'].y+i)
				
				var cellDataBeforePath = tilemap.get_cell_tile_data(0, pathPos)
				var cellDataLeft = tilemap.get_cell_tile_data(0, leftPos)
				var cellDataRight = tilemap.get_cell_tile_data(0, rightPos)
				
				# Now check if the tile to our left or right is also dead space
				if cellDataLeft == null:
					# Render left wall
					tilemap.set_cell(0, leftPos, source_id, tileMapWallVector, tileMapLeftAlt)
				if cellDataRight == null:
					# Render right wall
					tilemap.set_cell(0, rightPos, source_id, tileMapWallVector, tileMapRightAlt)
				
				if cellDataLeft != null:
					if tilemap.get_cell_atlas_coords(0, leftPos) == tileMapWallVector || tilemap.get_cell_atlas_coords(0, leftPos) == tileMapCornerVector:
						# Render left wall
						tilemap.set_cell(1, leftPos, source_id, tileMapWallVector, tileMapLeftAlt)
				if cellDataRight != null:
					if tilemap.get_cell_atlas_coords(0, rightPos) == tileMapWallVector || tilemap.get_cell_atlas_coords(0, rightPos) == tileMapCornerVector:
						# Render right wall
						tilemap.set_cell(1, rightPos, source_id, tileMapWallVector, tileMapRightAlt)
				
				# This means the connecting path we are about to render is in dead space
				if cellDataBeforePath == null:
					pass
				else:
					# This means we could be breaking down a wall, or just overwriting an existing floor tile
					# If we're breaking down a wall, also render another wall piece on another layer one to the left or right
					if (tilemap.get_cell_atlas_coords(0, pathPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, pathPos) == tileMapTopAlt):
						if (tilemap.get_cell_atlas_coords(0, leftPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, leftPos) == tileMapTopAlt) || (tilemap.get_cell_atlas_coords(0, leftPos) == tileMapCornerVector):
							# Render left wall
							tilemap.set_cell(1, leftPos, source_id, tileMapWallVector, tileMapLeftAlt)
						if (tilemap.get_cell_atlas_coords(0, rightPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, rightPos) == tileMapTopAlt) || (tilemap.get_cell_atlas_coords(0, rightPos) == tileMapCornerVector):
							# Render right wall
							tilemap.set_cell(1, rightPos, source_id, tileMapWallVector, tileMapRightAlt)
					elif (tilemap.get_cell_atlas_coords(0, pathPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, pathPos) == tileMapBottomAlt):
						if (tilemap.get_cell_atlas_coords(0, leftPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, leftPos) == tileMapBottomAlt) || (tilemap.get_cell_atlas_coords(0, leftPos) == tileMapCornerVector):
							# Render left wall
							tilemap.set_cell(1, leftPos, source_id, tileMapWallVector, tileMapLeftAlt)
						if (tilemap.get_cell_atlas_coords(0, rightPos) == Vector2i(0,0) && tilemap.get_cell_alternative_tile(0, rightPos) == tileMapBottomAlt) || (tilemap.get_cell_atlas_coords(0, rightPos) == tileMapCornerVector):
							# Render right wall
							tilemap.set_cell(1, rightPos, source_id, tileMapWallVector, tileMapRightAlt)

				# Now draw the path connection tiles
				tilemap.set_cell(0, Vector2i(path['left'].x,path['left'].y+i), source_id, Vector2i(0, 11))
				tilemap.set_cell(1, Vector2i(path['left'].x,path['left'].y+i), source_id, Vector2i(0, 12))

func spawn_enemy(spawn_position: Vector2i, spawn_percent: float = 1):
	if !(rng.randf_range(0,1) <= spawn_percent):
		return
	var new_enemy = ENEMY.instantiate()
	new_enemy.position = spawn_position
	self.add_child(new_enemy)
	classify_entity(new_enemy)

func _on_biteTimer_timeout():
	for biter in biters:
		biter.get_node("BiteAttacker").attack()
	
func classify_entity(entity):
	if entity.is_in_group("BITER"):
		biters.append(entity)
