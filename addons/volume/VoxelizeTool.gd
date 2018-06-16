tool
extends Button

var resolution = 64
var thickness = 50
var closed_mesh = false
var item_relation = 0

onready var plugin = get_node('/root/EditorNode/VolumePlugin')

func _on_self_pressed():
	$WindowDialog.popup_centered()
	$PopupDialog.hide()
	_on_resolution_changed(resolution)

func _on_resolution_changed(value):
	resolution = value
	$WindowDialog/VBoxContainer/Label.text = 'Volume Dimensions: '
	var size = $PopupDialog.get_volume_dimensions(plugin.edited_node, resolution)
	$WindowDialog/VBoxContainer/Label.text += str(size.x)+'x'+str(size.y)+'x'+str(size.z)

func _on_closed_mesh_toggled(button_pressed):
	closed_mesh = button_pressed

func _on_thickness_changed(value):
	thickness = value

func _on_item_relation_selected(ID):
	item_relation = ID

func _on_confirm_voxelization():
	$WindowDialog.hide()
	$PopupDialog.popup_centered()
	$PopupDialog.generate_volume(plugin.edited_node, resolution, thickness, closed_mesh)

func _on_exiting_tree():
	plugin.remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, self)
