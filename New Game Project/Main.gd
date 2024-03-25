extends Node2D
var Room=load("res://rigid_body_2d.tscn")

@export var tile_size=16
@export var num_rooms=10
@export var min_size=4
@export var max_size=10
@export var hor_spread=400
@export var survive=0.5
var path:AStar2D
@onready var map=$TileMap
func _ready():
	randomize()
	make_rooms()
	
func make_rooms():
	for i in range(num_rooms):
		var pos=Vector2(randf_range(-hor_spread,hor_spread),0)
		var r:Node=Room.instantiate()
		var w=min_size+randi()%(max_size-min_size)
		var h=min_size+randi()%(max_size-min_size)
		r.make_room(pos,Vector2(w,h)*tile_size)
		$Rooms.add_child(r)
	await get_tree().create_timer(1.1).timeout
	
	var roomPositions=[]
	for room:RigidBody2D in $Rooms.get_children():
		if survive<randf():
			room.queue_free()
		else:
			roomPositions.append(Vector2(room.position.x,room.position.y))
			room.freeze_mode=RigidBody2D.FREEZE_MODE_STATIC
	path=find_mst(roomPositions)
	await get_tree().process_frame
	
func find_mst(roomPos):
	var path =AStar2D.new()
	path.add_point(path.get_available_point_id(),roomPos.pop_front())
	while roomPos:
		var min_dist=INF
		var min_p=null
		var p=null
		
		for pz in path.get_point_ids():
			var p1=path.get_point_position(pz)
			
			for p2 in roomPos:
				if p1.distance_to(p2)<min_dist:
					min_dist=p1.distance_to(p2)
					min_p=p2
					p=p1
		var n=path.get_available_point_id()
		path.add_point(n,min_p)
		path.connect_points(path.get_closest_point(p),n)
		roomPos.erase(min_p)
	return path
			
			
	
	
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position-room.size,room.size*2),Color(32,228,0),false)
	if path:
		for p in path.get_point_ids():
			for c in path.get_point_connections(p):
				var pp=path.get_point_position(p)
				var cc =path.get_point_position(c)
				draw_line(Vector2(pp.x,pp.y),Vector2(cc.x,cc.y),Color(1,1,0),15,true)
func _process(delta):
	queue_redraw()
		
func _input(event):
	if event.is_action_pressed('ui_select'):
		for n in $Rooms.get_children():
			n.queue_free()
		make_rooms()
	
	if event.is_action_pressed("ui_focus_next"):
		make_map()

func make_map():
	map.clear()
	var full_rect=Rect2()
	for rooms in $Rooms.get_children():
		var r=Rect2(rooms.position-rooms.size,rooms.get_node("CollisionShape2D").shape.extents*2)
		full_rect=full_rect.merge(r)
	var topLeft=map.local_to_map(full_rect.position)
	var bottomRight=map.local_to_map(full_rect.end)
	for x in range(topLeft.x,bottomRight.x):
		for y in range(topLeft.y,bottomRight.y):
			map.set_cell(0,Vector2i(x,y),1,Vector2i(0,0))
	
	var cooridoors=[]
	for room in $Rooms.get_children():
		var s=(room.size/tile_size).floor()
		var pos=map.local_to_map(room.position)
		var ul=(room.position/tile_size).floor()-s
		for x in range(2,s.x*2-1):
			for y in range(2,s.y*2-1):
				map.set_cell(0,Vector2i(ul.x+x,ul.y+y),1,Vector2i(18,5))
		var p=path.get_closest_point(room.position)
		for conn in path.get_point_connections(p):
			if !conn in cooridoors:
				var start=map.local_to_map(Vector2(path.get_point_position(p).x,path.get_point_position(p).y))
				var end=map.local_to_map(Vector2(path.get_point_position(conn).x,path.get_point_position(conn).y))
				carve_path(start,end)
		cooridoors.append(p)

func carve_path(pos1,pos2):
	var x_diff=sign(pos2.x-pos1.x)
	var y_diff=sign(pos2.y-pos1.y)
	if x_diff==0:x_diff=pow(-1.0,randi()%2)
	if y_diff==0:y_diff=pow(-1.0,randi()%2)
	var x_y=pos1
	var y_x=pos2
	for x in range(pos1.x,pos2.x,x_diff):
		map.set_cell(0,Vector2(x,x_y.y),1,Vector2(18,5))
		map.set_cell(0,Vector2(x,x_y.y+y_diff),1,Vector2(18,5))
	for y in range(pos1.y,pos2.y,y_diff):
		map.set_cell(0,Vector2(y_x.x,y),1,Vector2(18,5))
		map.set_cell(0,Vector2(y_x.x+y_diff,y),1,Vector2(18,5))
	
