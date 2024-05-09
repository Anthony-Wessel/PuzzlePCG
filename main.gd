extends Node2D

@export var vertex_prefab : PackedScene
@export var edge_prefab : PackedScene
@export var completed_piece_prefab : PackedScene

@export var size : Vector2i

@export var holder : Node2D

var vertices = []
var edges = []
var pieces = []

var rng = RandomNumberGenerator.new()
signal step_completed

func _ready():	
	#await get_tree().create_timer(3.0).timeout
	
	generate_vertices()
	await step_completed
	await get_tree().create_timer(0.5).timeout
	
	generate_edges()
	await step_completed
	compile_pieces()
	await get_tree().create_timer(0.5).timeout
	
	add_noise_to_vertices()
	await step_completed
	await get_tree().create_timer(0.5).timeout

	add_connectors()
	await step_completed
	await get_tree().create_timer(0.5).timeout
	
	construct_pieces()
	await step_completed
	await get_tree().create_timer(0.5).timeout
	
	remove_child(holder)
	holder.queue_free()
	#move_pieces()
	
	""" Show 1 large triangulated piece
	for piece in pieces:
		piece.node.queue_free()
	
	var t = pieces[17].create_triangulated_piece()
	for tri in t.triangles:
		var n = edge_prefab.instantiate()
		add_child(n)
		n.add_point(t.get_point(tri[0])*10 + Vector2(20,20))
		n.add_point(t.get_point(tri[1])*10 + Vector2(20,20))
		n.add_point(t.get_point(tri[2])*10 + Vector2(20,20))
		n.add_point(t.get_point(tri[0])*10 + Vector2(20,20))
	"""
	
	
	var triangulated_pieces = []
	for piece in pieces:
		triangulated_pieces.append(piece.create_triangulated_piece())
		#piece.node.queue_free()
	
	for x in triangulated_pieces:
		var triangle_count = x.triangles.size()
		var points : Array[Vector2]
		for triangle in x.triangles:
			points.append(x.get_point(triangle[0]))
			points.append(x.get_point(triangle[1]))
			points.append(x.get_point(triangle[2]))
		
		var mask = GenerateTexture.instance.generate_mask(triangle_count, points)
		
		var piece0 = completed_piece_prefab.instantiate()
		add_child(piece0)
		piece0.position = x.position + Vector2(50,50)
		piece0.texture = mask
		(piece0.get_child(0) as Sprite2D).region_rect.position = x.position - Vector2(10,10)
		await get_tree().create_timer(0.1).timeout


func generate_vertices():
	for y in size.y+1:
		for x in size.x+1:
			var new_node = vertex_prefab.instantiate()
			holder.add_child(new_node)
			
			var left_right_border = x == 0 or x == size.x
			var top_bottom_border = y == 0 or y == size.y
			var new_vertex = Vertex.new(Vector2(10+x*50,10+y*50), new_node, left_right_border, top_bottom_border)
			vertices.append(new_vertex)
			
			await get_tree().create_timer(0.01).timeout
	step_completed.emit()

func generate_edges():
	for y in size.y+1:
		for x in size.x+1:
			var v1 = vertices[y*(size.x+1) + x]
			if x < size.x:
				var new_edge_node = edge_prefab.instantiate()
				holder.add_child(new_edge_node)
				var v2 = vertices[y*(size.x+1) + x + 1]
				edges.append(Edge.new(v1, v2, new_edge_node, y == 0 or y == size.y))
			if y < size.y:
				var new_edge_node = edge_prefab.instantiate()
				holder.add_child(new_edge_node)
				var v2 = vertices[y*(size.x+1) + x + size.x+1]
				edges.append(Edge.new(v1, v2, new_edge_node, x == 0 or x == size.x))
			await get_tree().create_timer(0.01).timeout
	step_completed.emit()

func compile_pieces():
	for y in size.y:
		for x in size.x:
			var vList = []
			vList.append(vertices[y*(size.x+1) + x])
			vList.append(vertices[y*(size.x+1) + (x+1)])
			vList.append(vertices[(y+1)*(size.x+1) + (x+1)])
			vList.append(vertices[(y+1)*(size.x+1) + x])
			
			var eList = []
			for i in range(4):
				eList.append(get_edge(vList[i], vList[(i+1)%4], edges))

			pieces.append(Piece.new(Vector2i(x,y), eList))

func add_noise_to_vertices():
	for v in vertices:
		if !v.left_right_border:
			var movement = rng.randf_range(-5, 5)
			v.move_animated(v.position + Vector2(movement,0), 1.0)
		
		if !v.top_bottom_border:
			var movement = rng.randf_range(-5, 5)
			v.move_animated(v.position + Vector2(0, movement), 1.5)
	await get_tree().create_timer(0.01).timeout
	step_completed.emit()

func add_connectors():
	for edge in edges:
		if edge.border:
			continue
		
		# pick a point in range around middle of v1 and v2
		var diff = edge.v2.position-edge.v1.position
		var point = edge.v1.position + rng.randf_range(0.4,0.6) * diff
		
		# get perpendicular vector
		var flip = sign(rng.randf()-0.5)
		var perpendicular = diff.normalized().orthogonal() * flip
		var connector_center = point + perpendicular*10
		
		var start_angle = (-perpendicular).angle()
		edge.vList.append(point - diff.normalized()*5)
		for i in range(1,8):
			var angle = start_angle + flip*(i * (2*PI)/8)
			edge.vList.append(connector_center + Vector2.from_angle(angle)*5)
		edge.vList.append(point + diff.normalized()*5)
		edge.update_visual()
		
		await get_tree().create_timer(0.01).timeout
	step_completed.emit()

func construct_pieces():
	for piece in pieces:
		var piece_node = edge_prefab.instantiate()
		add_child(piece_node)
		piece.create_piece_node(piece_node)
		
		await get_tree().create_timer(0.02).timeout
	step_completed.emit()

func move_pieces():
	$Camera2D.zoom_out()
	for piece in pieces:
		piece.stretch()

func get_edge(v1 : Vertex, v2 : Vertex, edges):
	for edge in edges:
		if edge.v1 == v1 and edge.v2 == v2:
			return edge
		elif edge.v1 == v2 and edge.v2 == v1:
			return edge



class Vertex:
	var position : Vector2 :
		set(value):
			position = value
			node.position = value
			on_vertex_updated.emit()
	var node : Node2D
	
	var left_right_border : bool
	var top_bottom_border : bool
	
	signal on_vertex_updated
	
	func _init(position : Vector2, node : Node2D, left_right_border : bool, top_bottom_border):
		self.node = node
		node.updated.connect(update_visual)
		self.position = position
		self.left_right_border = left_right_border
		self.top_bottom_border = top_bottom_border
	
	func update_visual():
		position = node.position
	
	func move_animated(target : Vector2, time : float):
		node.move_to(target, time)



class Edge:
	var v1 : Vertex
	var v2 : Vertex
	var vList = []
	
	var border : bool
	
	var node : Line2D
	
	func _init(v1 : Vertex, v2 : Vertex, node : Line2D, border : bool):
		self.node = node
		
		self.v1 = v1
		self.v2 = v2
		self.v1.node.updated.connect(update_visual)
		self.v2.node.updated.connect(update_visual)
		
		self.border = border
		
		update_visual()
	
	func update_visual():
		node.clear_points()
		node.add_point(v1.node.position)
		for point in vList:
			node.add_point(point)
		node.add_point(v2.node.position)




class Piece:
	var eList = []
	var pos : Vector2
	var node : Line2D
	
	func _init(position : Vector2i, eList):
		self.eList = eList
		pos = position
	
	func create_piece_node(node : Line2D):
		add_edge(node, eList[0], false)
		add_edge(node, eList[1], false)
		add_edge(node, eList[2], true)
		add_edge(node, eList[3], true)
		node.add_point(eList[0].v1.position)
		
		var rng = RandomNumberGenerator.new()
		node.default_color = Color(rng.randf()*0.5+0.5, rng.randf()*0.5+0.5, rng.randf()*0.5+0.5, 1)
	
	func add_edge(node : Line2D, edge : Edge, reverse : bool):
		self.node = node
		if reverse:
			node.add_point(edge.v2.position)
			var rev_list = []
			for v in edge.vList:
				rev_list.insert(0,v)
			for point in rev_list:
				node.add_point(point)
		else:
			node.add_point(edge.v1.position)
			for point in edge.vList:
				node.add_point(point)
	
	func stretch():
		for i in 100:
			for p in node.points.size():
				node.set_point_position(p, node.get_point_position(p) + pos*0.2)
			await node.get_tree().create_timer(0.01).timeout
	
	func create_triangulated_piece():
		var points = node.points
		var piece_pos := Vector2(-1,-1)
		for point in points:
			if piece_pos.x == -1:
				piece_pos = point
			else:
				if point.x < piece_pos.x:
					piece_pos.x = point.x
				if point.y < piece_pos.y:
					piece_pos.y = point.y
		
		for i in points.size():
			points[i] = points[i] - piece_pos
		
		points.remove_at(points.size()-1)
		return TriangulatedPiece.new(piece_pos, points)


class TriangulatedPiece:
	var position : Vector2
	var points : Array[Vector2]
	var triangles : Array[Vector3]
	
	func _init(pos : Vector2, point_list :  Array[Vector2]):
		for point in point_list:
			points.append(point)
		position = pos
		
		triangulate()
	
	func triangulate():
		var vertices = []
		for point in points:
			vertices.append(point)
		
		for loops in vertices.size()-3:
			for i in vertices.size():
				var p0 : Vector2 = vertices[i]
				var p1 : Vector2 = vertices[(i+1) % vertices.size()]
				var p2 : Vector2 = vertices[i-1]
				
				# check angle
				var diff1 : Vector2 = p1-p0
				var diff2 : Vector2 = p2-p0
				if diff1.angle_to(diff2) * 180/PI < 0:
					continue
				
				# check contents
				var area = 0.5 * (-p1.y*p2.x + p0.y*(-p1.x + p2.x) + p0.x*(p1.y - p2.y) + p1.x*p2.y)
				var contains_point = false
				for p in vertices:
					if p == p0 or p == p1 or p == p2:
						continue
					var s = 1/(2*area) * (p0.y*p2.x - p0.x*p2.y + (p2.y - p0.y)*p.x + (p0.x - p2.x)*p.y)
					var t = 1/(2*area) * (p0.x*p1.y - p0.y*p1.x + (p0.y - p1.y)*p.x + (p1.x - p0.x)*p.y)
					if s>=0 and t>=0 and s+t<=1:
						contains_point = true
						break
				
				if !contains_point:
					triangles.append(Vector3(get_index(p0), get_index(p1), get_index(p2)))
					vertices.erase(p0)
					break
		triangles.append(Vector3(get_index(vertices[0]), get_index(vertices[1]), get_index(vertices[2])))
	
	func get_index(point : Vector2):
		for i in points.size():
			if points[i] == point:
				return i
	
	func get_point(index : int):
		return points[index]
