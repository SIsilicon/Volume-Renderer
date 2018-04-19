shader_type spatial;
render_mode cull_disabled;
render_mode blend_mix;

uniform sampler2D texture_vol;
uniform vec4 color : hint_color;
uniform vec3 scale;
uniform vec2 tile_uv;
uniform int slice_number;
uniform bool shaded;

vec4 texture3D(sampler2D tex, vec3 UVW, vec2 tiling, float LOD) {
	
	UVW = vec3(UVW.x, UVW.z, UVW.y);
	if(UVW.x < 0.0 || UVW.x > 1.0 || UVW.y < 0.0 || UVW.y > 1.0 || UVW.z < 0.0 || UVW.z > 1.0) {
		return vec4(0.0);
	}
	
	float zCoord = UVW.z * tiling.x * tiling.y;
	float zOffset = fract(zCoord);
	zCoord = floor(zCoord);
	
	vec2 uv = UVW.xy / tiling;
	float ratio = tiling.y / tiling.x;
	vec2 slice0Offset = vec2(float(int(zCoord) % int(tiling.x)), floor(ratio * zCoord / tiling.y));
	zCoord++;
	vec2 slice1Offset = vec2(float(int(zCoord) % int(tiling.x)), floor(ratio * zCoord / tiling.y));
	
	vec4 slice0Color = textureLod(tex, slice0Offset/tiling + uv, LOD);
	vec4 slice1Color = textureLod(tex, slice1Offset/tiling + uv, LOD);
	
	return mix(slice0Color, slice1Color, zOffset);
}

vec4 volume(vec3 sample, float LOD) {
	vec3 new_sample = sample;
	return texture3D(texture_vol, (new_sample/2.0 + 0.5), tile_uv, LOD).rgba;
}

vec4 modulated_volume(vec3 sample, vec4 modulate, float LOD) {
	vec4 vol = volume(sample, LOD);
	vec3 colour = vol.rgb * modulate.rgb;
	float alpha = clamp(16.0 * vol.a * modulate.a / float(slice_number), 0.0, 1.0);
	return vec4(colour, alpha);
}

varying vec3 pos;
varying mat4 camera_matrix;

void vertex() {
	
	VERTEX.xy *= 2.0;
	VERTEX.z *= 1.2;
	VERTEX *= max(scale.x, max(scale.y, scale.z));
	
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(-CAMERA_MATRIX[0], -CAMERA_MATRIX[1], -CAMERA_MATRIX[2], WORLD_MATRIX[3]);
	
	camera_matrix = transpose(WORLD_MATRIX) * CAMERA_MATRIX;
	pos = (camera_matrix * -vec4(VERTEX,0.0)).xyz;
	pos /= scale * scale;
	
}

void fragment() {
	
	float bias = 0.01;
	if(pos.x < -1.0+bias || pos.x > 1.0-bias || pos.y < -1.0+bias || pos.y > 1.0-bias || pos.z < -1.0+bias || pos.z > 1.0-bias) {
		discard;
	}
	
	vec4 colour = modulated_volume(pos, color, 0);
	ALBEDO = colour.rgb;
	ALPHA = colour.a;
	//ALPHA_SCISSOR = 0.02;
}

void light() {
	
	if(shaded) {
		
		//front scatter resolution
		int fsr = 10;
		
		vec3 front_scatter_dir = (camera_matrix * vec4(LIGHT, 0.0)).xyz;
		front_scatter_dir = normalize(front_scatter_dir) / float(fsr);
		
		float alpha = 0.0;
		for(int i = 1; i < fsr; i++) {
			alpha += modulated_volume(pos + front_scatter_dir*float(i), color, 0).a;
			if(alpha > 1.0) {
				alpha = 1.0;
				break;
			}
		}
		vec3 LIGHTING = LIGHT_COLOR * (1.0-alpha) * ATTENUATION;
		
		DIFFUSE_LIGHT += LIGHTING * ALBEDO;
	} else {
		DIFFUSE_LIGHT = ALBEDO;
	}
	SPECULAR_LIGHT = vec3(0.0);
}