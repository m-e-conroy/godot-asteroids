shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float scanline_strength : hint_range(0.0, 0.5) = 0.14;
uniform float scanline_density : hint_range(100.0, 1000.0) = 320.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;
uniform float chromatic_aberration : hint_range(0.0, 0.005) = 0.0012;
uniform float phosphor_glow : hint_range(0.0, 0.5) = 0.16;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Subtle edge chromatic aberration
	vec2 dir = uv - vec2(0.5);
	float dist = length(dir);
	vec2 offset = dir * dist * chromatic_aberration;
	
	float r = texture(SCREEN_TEXTURE, uv + offset).r;
	float g = texture(SCREEN_TEXTURE, uv).g;
	float b = texture(SCREEN_TEXTURE, uv - offset).b;
	vec3 col = vec3(r, g, b);
	
	// Subtle phosphor bloom sample (4-tap soft halo)
	vec2 px = SCREEN_PIXEL_SIZE * 2.5;
	vec3 blur = (
		texture(SCREEN_TEXTURE, uv + vec2(px.x, 0.0)).rgb +
		texture(SCREEN_TEXTURE, uv - vec2(px.x, 0.0)).rgb +
		texture(SCREEN_TEXTURE, uv + vec2(0.0, px.y)).rgb +
		texture(SCREEN_TEXTURE, uv - vec2(0.0, px.y)).rgb
	) * 0.25;
	col += blur * phosphor_glow;
	
	// Horizontal CRT scanlines
	float scan = sin(uv.y * scanline_density * 3.14159265) * 0.5 + 0.5;
	col *= 1.0 - (scan * scanline_strength);
	
	// Gentle CRT edge vignette
	float vig = smoothstep(0.95, 0.25, dist);
	col *= mix(1.0 - vignette_strength, 1.0, vig);
	
	COLOR = vec4(col, 1.0);
}

