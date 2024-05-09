class_name GenerateTexture
extends Sprite2D

static var instance : GenerateTexture
func _init():
	instance = self

func generate_mask(triangle_count : int, points : Array[Vector2]):
	var rd := RenderingServer.create_local_rendering_device()
	
	var shader_file := load("res://mask_generator.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	var fmt := RDTextureFormat.new()
	fmt.width = 100
	fmt.height = 100
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view := RDTextureView.new()
	
	var output_image := Image.create(100, 100, false, Image.FORMAT_RGBAF)
	var output_tex = rd.texture_create(fmt, view, [output_image.get_data()])
	var output_tex_uniform := RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_tex)
	var uniform_set := rd.uniform_set_create([output_tex_uniform], shader, 0)
	
	var input_size = PackedInt32Array([triangle_count])
	var input_size_bytes = input_size.to_byte_array()
	var size_buffer := rd.storage_buffer_create(input_size_bytes.size(), input_size_bytes)
	var size_uniform := RDUniform.new()
	size_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	size_uniform.binding = 1
	size_uniform.add_id(size_buffer)
	var size_uniform_set := rd.uniform_set_create([size_uniform], shader, 1)
	
	var input_triangles := PackedVector2Array(points)
	var input_triangles_bytes := input_triangles.to_byte_array()
	var triangles_buffer := rd.storage_buffer_create(input_triangles_bytes.size(), input_triangles_bytes)
	var triangles_uniform := RDUniform.new()
	triangles_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	triangles_uniform.binding = 2
	triangles_uniform.add_id(triangles_buffer)
	var triangles_uniform_set := rd.uniform_set_create([triangles_uniform], shader, 2)
	
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, size_uniform_set, 1)
	rd.compute_list_bind_uniform_set(compute_list, triangles_uniform_set, 2)
	rd.compute_list_dispatch(compute_list, 100, 100, 1)
	rd.compute_list_end()
	
	rd.submit()
	# await here
	rd.sync()
	
	var output_bytes := rd.texture_get_data(output_tex,0)
	output_image.set_data(100,100,false,Image.FORMAT_RGBAF, output_bytes)
	texture = ImageTexture.create_from_image(output_image)
	
	
	"""
	
	var input := PackedFloat32Array([1,2,3,4,5,6,7,8,9,10])
	var input_bytes := input.to_byte_array()
	
	var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)
	
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)
	var uniform_set := rd.uniform_set_create([uniform], shader, 0)
	
	
	
	var output_bytes := rd.buffer_get_data(buffer)
	var output = output_bytes.to_float32_array()
	print("Input: ", input)
	print("Output: ", output)
	
	"""
	
	#var image = Image.create(100, 100, false, Image.FORMAT_R8)
	#for x in 100:
	#	for y in 100:
	#		if x < y:
	#			image.set_pixel(x,y,Color.ALICE_BLUE)
	#texture = ImageTexture.create_from_image(image)
