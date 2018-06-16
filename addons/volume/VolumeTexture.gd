tool
extends Resource

export(Image) var image
export(int) var depth

func setup(image, depth):
	self.depth = depth
	self.image = image

func set_shader_param(shader_mat, uni_tex, uni_tile):
	var tex = ImageTexture.new()
	tex.create_from_image(image, Texture.FLAGS_DEFAULT)
	shader_mat.set_shader_param(uni_tex, tex)
	shader_mat.set_shader_param(uni_tile, get_tiling())

func get_width():
	return image.get_width() / get_tiling().x

func get_height():
	return image.get_height() / get_tiling().y

func set_depth(depth):
	printerr("You WON'T be changing that!")

func get_depth():
	return depth

func get_tiling():
	return get_tile_dimensions(depth)

static func get_tile_dimensions(depth):
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