tool
extends EditorPlugin

const Volume = preload("volume.gd");
const VolumeType = "Volume";

func _enter_tree():
	add_custom_type(VolumeType, "ImmediateGeometry", Volume, preload("icon.png"));

func _exit_tree():
	remove_custom_type(VolumeType);


