bl_info = {
    'name': 'Godot Volume Generator',
    'description': 'This addon creates volumetric textures from meshes. The generated images are meant to be used with the Godot plugin Volume Renderer.',
    'author': 'SIsilicon',
    'version': (1, 0, 0),
    'blender': (2, 79, 0),
    'location': 'Properties > Render',
    'category': 'Render'
}

import bpy

from math import *
from mathutils import *

def create_override(area_name):
    for area in bpy.context.screen.areas:
        if area.type == area_name:
            for region in area.regions:
                if region.type == 'WINDOW':
                    return {'area': area, 'region':region}

def get_tile_dimension(depth):
    tile_dimension = (0, 0)
    
    last_factor = depth
    for i in range(1,depth+1):
    
        candidate_factor = depth/i
        if (candidate_factor - floor(candidate_factor)) == 0.0:
            if i == candidate_factor:
                tile_dimension = (i, i)
                break
            elif i == last_factor:
                tile_dimension = (int(candidate_factor), int(last_factor))
                break
            last_factor = candidate_factor
    
    if tile_dimension[0] == 1:
        return get_tile_dimension(depth+1)
    else:
        return tile_dimension

def bake():
    adjust_geom()
    volume = get_volume(resolution)
    tiling = get_tile_dimension(volume[2])
    dimensions = bpy.context.object.dimensions
    override = create_override('VIEW_3D')
    
    bpy.ops.view3d.copybuffer(override)
    
    bpy.ops.scene.new()
    bpy.ops.mesh.primitive_plane_add(enter_editmode=True)
    bpy.ops.transform.resize(value=dimensions/2)
    
    for i in range(1, volume[2]):
        bpy.ops.mesh.primitive_plane_add(location = ((i%tiling[0])*dimensions[0], -floor(i/tiling[0])*dimensions[1], i/volume[2]*(dimensions[2]+1/volume[2])))
        bpy.ops.transform.resize(value=dimensions/2)
    
    bpy.ops.object.editmode_toggle()
    bpy.ops.object.camera_add(view_align=False, location=(tiling[0]*dimensions[0]/2-dimensions[0]/2,
         -tiling[1]*dimensions[1]/2+dimensions[1]/2, 10))
    
    bpy.context.scene.name = 'vol'
    vol_camera = bpy.data.scenes['vol'].objects[0]
    vol_capture = bpy.data.scenes['vol'].objects[1]
    vol_capture.name = 'vol_capture'
    
    vol_camera.data.type = 'ORTHO'
    vol_camera.data.ortho_scale = tiling[1]*dimensions[1]
    
    bpy.context.scene.objects.active = vol_capture
    bpy.ops.object.editmode_toggle()
    bpy.ops.mesh.select_all(action='TOGGLE')
    bpy.ops.mesh.select_all(action='TOGGLE')
    
    bpy.ops.uv.unwrap(override, margin=0)
    bpy.ops.object.editmode_toggle()
    
    bpy.ops.view3d.pastebuffer(override)
    
    obj = 0
    for i_obj in bpy.data.scenes['vol'].objects:
        if i_obj is not vol_capture or i_obj is not vol_camera:
            obj = i_obj
    obj.location = (0, 0, dimensions[2]/2)
    
    arrays = {'x': (dimensions[0], 0, 0),
              'y': (0, -dimensions[1], 0)}
    for axis, displace in arrays.items():
        mod = obj.modifiers.new(axis, 'ARRAY')
        if axis == 'x':
            mod.count = tiling[0]
        elif axis == 'y':
            mod.count = tiling[1]
        mod.use_constant_offset = True
        mod.use_relative_offset = False
        mod.constant_offset_displace = displace
    
    bpy.context.scene.objects.active = obj
    paint = obj.modifiers.new('paint', 'DYNAMIC_PAINT')
    paint.ui_type = 'BRUSH'
    bpy.ops.dpaint.type_toggle(type='BRUSH')
        
    #paint.brush_settings.use_material = True
    #paint.brush_settings.material = obj.data.materials[0]
    
    paint.brush_settings.paint_color = color
        
    bpy.context.scene.objects.active = vol_capture
    canvas = vol_capture.modifiers.new('paint', 'DYNAMIC_PAINT')
    canvas.ui_type = 'CANVAS'
    bpy.ops.dpaint.type_toggle(type='CANVAS')
    surface = canvas.canvas_settings.canvas_surfaces['Surface']
    surface.surface_format = 'IMAGE'
    surface.image_resolution = max(volume[0], volume[1]) * tiling[1]
    surface.frame_end = 1
    surface.uv_layer = 'UVMap'
    surface.image_output_path = '/temp_vol_data'
    
    obj.hide_render = True
    bpy.context.scene.objects.active = vol_capture
    bpy.data.scenes['vol'].cursor_location = volume
    
    bpy.ops.dpaint.bake()

def prep():
    
    tiling = get_tile_dimension(resolution)
    width_height = resolution
    
    vol_capture = bpy.context.object
    
    mat = bpy.data.materials.new(name='vol')
    mat.use_shadeless = True
    mat.use_transparency = True
    mat.alpha = 0
    vol_capture.data.materials.append(mat)
    
    tex = bpy.data.textures.new(name='vol', type='IMAGE')
    tex.use_mipmap = False
    
    directpath = bpy.path.abspath('//temp_vol_data\\paintmap0001.png')
    paintmap = bpy.data.images.load(directpath)
    tex.image = paintmap
    
    slot = mat.texture_slots.add()
    slot.texture = tex
    slot.uv_layer = 'UVMap'
    slot.use_map_alpha = True
    
    bpy.context.scene.render.resolution_x = width_height*tiling[0]
    bpy.context.scene.render.resolution_y = width_height*tiling[1]
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.alpha_mode = 'TRANSPARENT'

def cleanup():
    bpy.ops.scene.delete()
    for block in bpy.data.objects:
        if block.users == 0:
            bpy.data.objects.remove(block)
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.cameras:
        if block.users == 0:
            bpy.data.cameras.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)
    for block in bpy.data.textures:
        if block.users == 0:
            bpy.data.textures.remove(block)
    for block in bpy.data.images:
        if block.users == 0:
            bpy.data.images.remove(block)
    
    tiling = get_tile_dimension(resolution)
    
    bpy.context.scene.render.resolution_x = tiling[0]
    bpy.context.scene.render.resolution_y = tiling[1]

def adjust_geom():
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.location_clear()
    minv = Vector((0,0,0))
    maxv = Vector((0,0,0))
    for vert in bpy.context.object.data.vertices:
        coord = Vector(vert.co)
        minv.x = min(minv.x, coord.x)
        minv.y = min(minv.y, coord.y)
        minv.z = min(minv.z, coord.z)
        
        maxv.x = max(maxv.x, coord.x)
        maxv.y = max(maxv.y, coord.y)
        maxv.z = max(maxv.z, coord.z)
    avg = (minv + maxv) / 2
    bpy.ops.transform.translate(value=(avg.x, avg.y, avg.z))
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    avg *= -1
    bpy.ops.transform.translate(value=(avg.x, avg.y, avg.z))
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.location_clear()
    
    bpy.context.scene.objects.active.dimensions = [2.0,2.0,2.0]
    bpy.ops.object.transform_apply(scale=True)
    

def get_volume(res):
    obj = bpy.context.object
    longest_side = max(obj.dimensions)
    vol = [0, 0, 0]
    for side in range(0, 3):
        vol[side] = ceil(res * obj.dimensions[side] / longest_side)
    
    return vol


#*** USERS VARIABLES HERE ***#
resolution = 64
color = [1, 1, 1] #each color component value is between 0 and 1

#*** USERS TYPE FUNCTIONS HERE ***#
