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

As of Version 1.1, volunes cannot be affected by lights anymore. But don't worry. It will come back.

