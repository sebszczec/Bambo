shader_type canvas_item;

// Shock wave of the Boulder Beetle blast: a smooth ring racing out to `radius`
// that bends the picture behind it (screen texture refraction) and glows
// cyan inside, amber at the front. Everything is computed per pixel, so the
// ring has no polygon edges at any size. The quad is `size` px square.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float size = 360.0;
uniform float radius = 140.0;
// 0 = burst, 1 = ring at the full radius and faded out
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float thickness = 26.0;
// how far the background is pushed, in screen px
uniform float refraction = 16.0;
uniform vec4 core_color : source_color = vec4(0.42, 0.86, 0.92, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.48, 0.29, 1.0);
// HDR boost so the bloom catches the ring
uniform float intensity = 2.2;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * size;
	float r = length(p);
	vec2 dir = r > 0.001 ? p / r : vec2(0.0);

	float ring_r = mix(0.15, 1.0, progress) * radius;
	float fade = 1.0 - progress;
	float th = thickness * (1.0 - 0.5 * progress);
	// -1 behind the band, 0 on it, +1 in front
	float d = (r - ring_r) / th;
	float band = exp(-d * d * 2.5);

	// the front pushes the background outward, the back pulls it in
	vec2 offset = dir * d * band * refraction * fade * SCREEN_PIXEL_SIZE;
	vec3 bg = texture(screen_tex, SCREEN_UV - offset).rgb;

	// a sharp bright front over the soft band, amber outside, cyan inside
	float front = exp(-pow((r - ring_r) / (th * 0.3), 2.0));
	vec3 glow = mix(core_color.rgb, edge_color.rgb, smoothstep(0.1, 0.9, d)) * intensity;
	float g = (front + band * 0.4) * fade;
	// soft light left behind the wave
	float inner = (1.0 - smoothstep(0.0, ring_r, r)) * 0.1 * fade * fade;

	vec3 rgb = bg + glow * g + core_color.rgb * intensity * inner;
	// outside the band the pixel stays untouched
	float alpha = clamp(band * fade * 1.5 + g + inner, 0.0, 1.0);
	alpha *= 1.0 - smoothstep(size * 0.46, size * 0.5, r);
	COLOR = vec4(rgb, alpha);
}
