tool
extends ImmediateGeometry

export(int, 8, 512) var sliceCount = 64 setget set_slices
export(bool) var shaded = false setget set_shaded
export(Color) var modulate = Color(1,1,1) setget set_modulate

#export(int, 'Mix', 'Add', 'Sub', 'Mul') var blend_mode = 0 setget set_blend

export(Texture) var volume_texture setget set_texture
export(Vector2) var texture_tiling = Vector2(8, 16) setget set_tiling


func _init():
	material_override = ShaderMaterial.new()
	material_override.shader = preload("res://addons/volume/volume_shader.shader")
	
	set_slices(sliceCount)
	set_modulate(modulate)
	set_shaded(shaded)
	set_tiling(texture_tiling)

func _process(delta):
	material_override.set_shader_param("scale", scale)

func set_modulate(mod):
	modulate = mod
	material_override.set_shader_param("color", modulate)

func set_shaded(boolean):
	shaded = boolean
	material_override.set_shader_param("shaded", shaded)

#func set_blend(blend):
	#blend_mode = blend
	#var shader = material_override.shader.code
	#var render_mode_loc = shader.find('render_mode blend_')
	#
	#print(render_mode_loc)

func set_texture(tex):
	volume_texture = tex
	material_override.set_shader_param("texture_vol", tex)

func set_tiling(tiling):
	texture_tiling = tiling
	material_override.set_shader_param("tile_uv", texture_tiling)

func set_slices(sliceNum):
	sliceCount = sliceNum
	material_override.set_shader_param("slice_number", sliceNum)
	clear()
	for i in range(-sliceNum/2, sliceNum/2):
		var z = -i/(sliceNum/2.0-1)
		
		begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		add_vertex(Vector3(-1,1,z))
		add_vertex(Vector3(-1,-1,z))
		add_vertex(Vector3(1,1,z))
		add_vertex(Vector3(1,-1,z))
		end()