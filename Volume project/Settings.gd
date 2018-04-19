extends VBoxContainer

onready var volume = $"../../Volume"

func _slice_count_changed(value):
	volume.set_slices(value)
	$SliceNumber/Label2.text = str(value)

func _shaded_changed(button_pressed):
	volume.set_shaded(button_pressed)

func _colour_changed(color):
	volume.set_modulate(color)

func _texture_pyramid():
	volume.set_texture(preload("pyramid_volume.png"))

func _sphere_texture():
	volume.set_texture(preload("sphere_volume.png"))

func _suzanne_texture():
	volume.set_texture(preload("suzanne_volume.png"))

func _cup_texture():
	volume.set_texture(preload("cup_volume.png"))
