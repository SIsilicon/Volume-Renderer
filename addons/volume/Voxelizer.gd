tool
extends PopupDialog

const TRIANGLE_INC = 64

signal voxelization_done(texture, tiling, relation)

func generate_volume(mesh_inst, resolution, thickness, closed):
	var triangle_img = Image.new()
	var triangle_tex_array = ImageTexture.new()
	
	var triangles = mesh_inst.mesh.get_faces()
	
	var vol = get_volume_dimensions(mesh_inst, resolution)
	var tiling = get_tile_dimensions(vol.z)
	
	for i in range(triangles.size()):
		triangles[i] /= vol / resolution
		triangles[i] /= mesh_inst.get_aabb().get_longest_axis_size() / 2.0
	
	$voxelizer/voxel_canvas.material = preload('VoxelizerShader.tres')
	
	triangle_tex_array.set_storage(ImageTexture.STORAGE_RAW)
	
	var triangle_count = triangles.size()/3
	
	$voxelizer/voxel_canvas.material.set_shader_param("tiling", Vector3(tiling.x, tiling.y, vol.z))
	$voxelizer.size = tiling * Vector2(vol.x, vol.y)
	$voxelizer.render_target_update_mode = Viewport.UPDATE_ONCE
	
	$voxelizer/voxel_canvas.polygon = PoolVector2Array([Vector2(), Vector2($voxelizer.size.x, 0), $voxelizer.size, Vector2(0, $voxelizer.size.y)])
	
	var temp_img = Image.new()
	temp_img.create($voxelizer.size.x, $voxelizer.size.y, false, Image.FORMAT_RGBAH)
	temp_img.fill(Color(100,1,0))
	
	var copied_tex = ImageTexture.new()
	copied_tex.create_from_image(temp_img, 0)
	
	triangle_img.create(3, TRIANGLE_INC, false, Image.FORMAT_RGBH)
	for i in range(0, triangle_count, TRIANGLE_INC):
		update_voxelizer_progress(i, triangle_count)
		
		var end_index = min(i+TRIANGLE_INC, triangle_count)
		triangle_img.fill(Color(0,0,0))
		triangle_img.resize(3, end_index - i)
		triangle_img.lock()
		for j in range(i, end_index):
			var point1 = triangles[j*3]
			var point2 = triangles[j*3+1]
			var point3 = triangles[j*3+2]
			
			triangle_img.set_pixel(0, j-i, Color(point1.x, point1.y, point1.z))
			triangle_img.set_pixel(1, j-i, Color(point2.x, point2.y, point2.z))
			triangle_img.set_pixel(2, j-i, Color(point3.x, point3.y, point3.z))
		triangle_img.unlock()
		triangle_tex_array.create_from_image(triangle_img, 0)
		
		$voxelizer/voxel_canvas.material.set_shader_param("triangles", triangle_tex_array)
		$voxelizer/voxel_canvas.material.set_shader_param("continuation", copied_tex)
		$voxelizer.render_target_update_mode = Viewport.UPDATE_ONCE
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		copied_tex.set_data($voxelizer.get_texture().get_data())
	
	$voxelizer/voxel_canvas.material.set_shader_param("triangles", null)
	$voxelizer/voxel_canvas.material.set_shader_param("continuation", null)
	
	$voxelizer/voxel_canvas.material = preload("FinalVoxConvert.tres")
	$voxelizer/voxel_canvas.material.set_shader_param("tex", copied_tex)
	$voxelizer/voxel_canvas.material.set_shader_param("thickness", thickness)
	$voxelizer/voxel_canvas.material.set_shader_param("closed_mesh", closed)
	$voxelizer.render_target_update_mode = Viewport.UPDATE_ONCE
	
	update_voxelizer_progress(triangle_count, triangle_count)
	yield(get_tree(), "idle_frame")
	
	var voxel_data = $voxelizer.get_texture().get_data()
	voxel_data.convert(Image.FORMAT_RGBA8)
	
	#voxel_data.save_png('res://suzanne_volume.png')
	copied_tex.create_from_image(voxel_data, ImageTexture.FLAGS_DEFAULT)
	
	$voxelizer/voxel_canvas.material.set_shader_param("tex", null)
	
	#The voxel button's second child is the progress popup
	#_voxel_button.get_child(1).hide()
	hide()
	
	print('successful voxelization!')
	emit_signal('voxelization_done', copied_tex, tiling, get_parent().item_relation)

func get_tile_dimensions(depth):
	var tile_dimension = Vector2()
	
	var last_factor = depth
	for i in range(1,depth+1):
		
		var candidate_factor = depth/float(i)
		if (candidate_factor - floor(candidate_factor)) == 0.0:
			if i == candidate_factor:
				tile_dimension = Vector2(i, i)
				break
			elif i == last_factor:
				tile_dimension = Vector2(int(candidate_factor), int(last_factor))
				break
			last_factor = candidate_factor
	
	if tile_dimension.x == 1:
		return get_tile_dimensions(depth+1)
	else:
		return tile_dimension

func get_volume_dimensions(mesh, res):
	var bound_box = mesh.get_aabb()
	var vol = Vector3()
	var longest_side = bound_box.get_longest_axis_size()
	vol.x = ceil(res * bound_box.size.x / longest_side)
	vol.y = ceil(res * bound_box.size.y / longest_side)
	vol.z = ceil(res * bound_box.size.z / longest_side)
	
	return vol

func update_voxelizer_progress(tri_done, tri_total):
	$VSplitContainer/Label.text = 'Voxelized: '+str(tri_done)+'/'+str(tri_total)+' Triangles'
	$VSplitContainer/ProgressBar.value = float(tri_done) / tri_total
