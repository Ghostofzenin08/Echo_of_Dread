shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float aberration_amount : hint_range(0.0, 0.05) = 0.015;
uniform float scanline_count : hint_range(50.0, 800.0) = 360.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.7;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.6;
uniform float distortion_amount : hint_range(0.0, 0.1) = 0.015;
uniform float time_speed = 8.0;

void fragment() {
	if (intensity <= 0.0001) {
		COLOR = texture(screen_texture, SCREEN_UV);
	} else {
		vec2 uv = SCREEN_UV;
		
		// VHS-style wave distortion & glitch jitter
		float wave = sin(uv.y * 40.0 + TIME * time_speed) * distortion_amount * intensity;
		float jitter = sin(TIME * 60.0) * cos(uv.y * 100.0) * 0.003 * intensity;
		uv.x += wave + jitter;
		
		// Chromatic aberration (R / G / B spatial offsets)
		float offset = aberration_amount * intensity;
		vec2 uv_r = clamp(uv + vec2(offset, 0.0), vec2(0.001), vec2(0.999));
		vec2 uv_g = clamp(uv, vec2(0.001), vec2(0.999));
		vec2 uv_b = clamp(uv - vec2(offset, 0.0), vec2(0.001), vec2(0.999));
		float r = texture(screen_texture, uv_r).r;
		float g = texture(screen_texture, uv_g).g;
		float b = texture(screen_texture, uv_b).b;
		vec3 color = vec3(r, g, b);
		
		// CRT scanlines
		float scanline = sin(SCREEN_UV.y * scanline_count * 3.14159265 * 2.0);
		scanline = (scanline + 1.0) * 0.5;
		color -= scanline * scanline_intensity * intensity * color;
		
		// Temporal rewind cyan tint wash
		vec3 rewind_tint = vec3(0.25, 0.85, 1.0);
		color = mix(color, color * rewind_tint * 1.4, 0.25 * intensity);
		
		// Radial vignette
		vec2 centered_uv = SCREEN_UV - vec2(0.5);
		float dist = length(centered_uv);
		float vig = smoothstep(0.8, 0.2, dist * vignette_intensity);
		color = mix(color * vig, color, 1.0 - (vignette_opacity * intensity));
		
		COLOR = vec4(color, 1.0);
	}
}
