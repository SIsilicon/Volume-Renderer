# Volume-Renderer

This Godot addon allows to visualize 3D atlas-based textures.
It adds a node called 'Volume', and it has the following parameters.

- SliceCount: The amount of slices the volume is made of. More slices are better but slower.
- Dither: How much noise is applied to the volume. This can help reduce banding artifacts that come from a low slice number.
- Modulate: This colour is multiplied with the volume's own colour. The alpha component determines overall density.
- Texture: The texture the volume will draw with.
- Tiling: This Vector is used with the texture so that reads it correctly. You will need it if you're using a texture of your own.

And in the demo project you can change your view with the WASD keys.

## What happened to shaded?

As of Version 1.2, volunes cannot be affected by lights anymore. But don't worry. It will come back.

## And what about the volume generator?

As of Version 1.3, the volume generator is now a built-in feature in the editor. Whenever you select a `MeshInstance` a button will appear in the toolbar called `VoxelizeMesh`. Pressing it will open a popup with the following options.

- Resolution: the number of pixels wide the longest side of the volume will be. The volume's dimensions will appear below that.
- Thickness: the base density of the resulting volume. It's best understood when tried out.
- Closed Mesh: Whether to have actual 'stuff' inside the volume, or just a shell. Be careful though. It the mesh had holes or rouge triangles inside of itself, having a closed mesh will most likely lead to artifacts. Like in the Suzanne volume in the demo.
- Have the volume at: self explanatory.

Pressing `voxelize` and waiting will give you the volume you want.
