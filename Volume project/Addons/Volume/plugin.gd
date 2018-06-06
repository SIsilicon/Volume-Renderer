tool
extends EditorPlugin

const VolumeType = "Volume"
const VolumeTex = "VolumeTexture"

var root

var editor_camera
var scene_camera

var slice_generator = preload("SliceGenerator.tscn")

func _enter_tree():
	root = get_node('/root')
	
	add_custom_type(VolumeType, "ImmediateGeometry", preload("volume.gd"), preload("icon.png"))
	add_custom_type(VolumeTex, "Resource", preload("VolumeTexture.gd"), preload("icon.png"))
	
	slice_generator = slice_generator.instance()
	if not root.is_a_parent_of(slice_generator):
		root.call_deferred("add_child", slice_generator)
	else:
		print('slice generator already exists..')
	
	set_input_event_forwarding_always_enabled()
	set_process(true)

#func _exit_tree():
#	remove_custom_type(VolumeType)
#	remove_custom_type(VolumeTex)
#	
#	print('we have exited from the root: ' + str(root))
#	if root.is_a_parent_of(slice_generator):
#		root.remove_child(slice_generator)
#	else:
#		print('slice generator was never here..')

func _process(delta):
	pass
	#if editor_camera and scene_camera:
	#	scene_camera.global_transform = editor_camera.global_transform

func handles(object):
	return object is preload("volume.gd")

func edit(object):
	object

func forward_spatial_gui_input(camera, event):
	editor_camera = camera
	#scene_camera = $'../../EditorNode/@@5/@@6/@@14/@@16/@@20/@@24/@@25/@@26/@@42/@@43/@@50/@@51/@@6456/@@6322/@@6323/@@6324/@@6325/@@6326/@@6327/Spatial/Camera'
