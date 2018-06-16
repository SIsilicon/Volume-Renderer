extends VBoxContainer

onready var volume = $"../../Volume"

func _process(delta):
	$"../../FrameRate".text = str(Engine.get_frames_per_second())

func _slice_count_changed(value):
	volume.set_slices(value)
	$SliceNumber/Label2.text = str(value)

func _dither_strength_changed(value):
	volume.set_dither(value)
	$DitherStrength/Label2.text = str(value)

func _blend_mode_changed(item_selected):
	volume.set_blend(item_selected)

func _colour_changed(color):
	volume.set_modulate(color)

func _texture_changed(item):
	match item:
		0: volume.set_texture(preload("suzanne_volume.png"))
		1: volume.set_texture(preload("pyramid_volume.png"))
		2: volume.set_texture(preload("sphere_volume.png"))
		3: volume.set_texture(preload("cup_volume.png"))
	
	match item:
		0: volume.set_tiling(Vector2(8,10))
		_: volume.set_tiling(Vector2(8,16))