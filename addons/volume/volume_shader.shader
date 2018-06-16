shader_type spatial;
render_mode blend_mix;
render_mode cull_disabled, unshaded, depth_test_disable;

uniform sampler2D texture_vol;
uniform vec4 color : hint_color;
uniform vec3 scale;
uniform vec2 tile_uv;
uniform float dither_strength: hint_range(0, 10);
uniform int slice_number;

vec4 texture3D(sampler2D tex, vec3 UVW, vec2 tiling, float LOD) {
	
	/*if(any(lessThan(UVW, vec3(0.0))) || any(greaterThan(UVW, vec3(1.0)))) {
		return vec4(0.0);
	}*/
	
	float zCoord = -(1.0 - UVW.z) * tiling.x * tiling.y;
	float zOffset = fract(zCoord);
	zCoord = floor(zCoord);
	
	vec2 uv = UVW.xy / tiling;
	float ratio = tiling.y / tiling.x;
	vec2 slice0Offset = vec2(float(int(zCoord) % int(tiling.x)), floor(ratio * zCoord / tiling.y));
	zCoord++;
	vec2 slice1Offset = vec2(float(int(zCoord) % int(tiling.x)), floor(ratio * zCoord / tiling.y));
	
	vec4 slice0Color = textureLod(tex, slice0Offset/tiling + uv, LOD);
	vec4 slice1Color = textureLod(tex, slice1Offset/tiling + uv, LOD);
	
	//return slice0Color; //no filtering.
	return mix(slice0Color, slice1Color, zOffset);
}

vec4 volume(vec3 sample, float LOD) {
	vec3 new_sample = sample;
	return texture3D(texture_vol, (new_sample/2.0 + 0.5), tile_uv, LOD);
}

vec4 modulated_volume(vec3 sample, vec4 modulate, float LOD) {
	vec4 vol = volume(sample, LOD);
	vec3 colour = vol.rgb * modulate.rgb;
	float alpha = clamp(16.0 * vol.a * modulate.a / float(slice_number), 0.0, 1.0);
	return vec4(colour, alpha);
}

varying mat4 camera_matrix;
varying vec3 pos;

void vertex() {
	
	VERTEX.xy *= 1.2;
	VERTEX.z *= 1.2;
	VERTEX *= max(scale.x, max(scale.y, scale.z));
	
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(-CAMERA_MATRIX[0], -CAMERA_MATRIX[1], -CAMERA_MATRIX[2], WORLD_MATRIX[3]);
	
	camera_matrix = transpose(WORLD_MATRIX) * CAMERA_MATRIX;
	
	pos = (camera_matrix * -vec4(VERTEX,0.0)).xyz;
	pos /= scale * scale;
}

float hash(vec2 p) {
	float q = dot(p, vec2(127.1, 311.7));
	return fract(sin(q) * 43758.5453);
}

void fragment() {
	
	vec4 cam_ray = camera_matrix * vec4(VERTEX, 0.0);
	float dither = (hash(FRAGCOORD.xy)*2.0 - 1.0) * dither_strength;
	vec3 upos = pos + normalize(cam_ray.xyz)*dither;
	
	float bias = 0.0;
	if(any(lessThan(upos, -vec3(1.0-bias))) || any(greaterThan(upos, vec3(1.0-bias)))) {
		discard;
	}
	
	vec3 dx_vtc = dFdx(pos);
	vec3 dy_vtc = dFdy(pos);
	float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));
	float mml = 0.5 * log2(delta_max_sqr) + 6.5;
	
	float depth_tex = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
	world_pos /= world_pos.w;
	
	if(VERTEX.z-dither < world_pos.z) discard;
	
	vec4 colour = modulated_volume(upos, color, mml);
	
	ALBEDO = colour.rgb;
	ALPHA = colour.a;
	//ALPHA_SCISSOR = 0.02;
}

/* LIGHT SHADER DEPRECATED UNTIL FURTHER NOTICE :(

void light() {
	
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
	SPECULAR_LIGHT = vec3(0.0);
}