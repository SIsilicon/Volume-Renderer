tool
extends EditorPlugin

const Volume = preload("volume.gd")
#const VolumeTex = preload("VolumeTexture.gd")

#var editor_cam = null
var edited_node = null

var _voxel_button = null

func _enter_tree():
	name = 'VolumePlugin'
	
	add_custom_type('Volume', "ImmediateGeometry", Volume, preload("icon.png"))
	#add_custom_type('VolumeTexture', "Resource", VolumeTex, preload("icon.png"))
	
	if not _voxel_button:
		_voxel_button = preload('res://addons/volume/VoxelizeTool.tscn').instance()
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _voxel_button)
		_voxel_button.hide()
		_voxel_button.get_child(1).connect('voxelization_done', self, '_finalize_volume')
	
	#set_input_event_forwarding_always_enabled()
	print('VolumeRenderer has entered the game.')

func _exit_tree():
	remove_custom_type('Volume')
	print('VolumeRenderer has left the game.')

func handles(object):
	var handle = object is Volume
	handle = handle or object is MeshInstance
	if not handle: _voxel_button.hide()
	return handle

func edit(object):
	edited_node = object
	if edited_node is MeshInstance:
		_voxel_button.show()
	else:
		_voxel_button.hide()

func clear():
	edited_node = null
	_voxel_button.hide()

#func forward_spatial_gui_input(camera, event):
#	editor_cam = camera

func _finalize_volume(texture, tiling, relation):
	
	var volume = Volume.new()
	volume.set_texture(texture)
	volume.set_tiling(tiling)
	volume.scale = edited_node.get_aabb().size / 2.0
	
	match relation:
		0: edited_node.add_child(volume)
		1:
			edited_node.get_parent().add_child_below_node(edited_node, volume)
			volume.global_transform = edited_node.global_transform
		2: edited_node.replace_by(volume)
	volume.owner = get_editor_interface().get_edited_scene_root()
	if edited_node.name.match('MeshInstance*'):
		volume.name = 'Volume'
	else:
		volume.name = edited_node.name + '-vol'