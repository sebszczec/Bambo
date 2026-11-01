shader_type canvas_item;

// banner text: white flash on appear, a diagonal shine sweeping over the letters
// and a left to right disintegration with a glowing edge when it goes away
uniform float sweep_x = -10000.0;
uniform float band = 70.0;
uniform float flash = 0.0;
uniform float dissolve_x = -10000.0;
uniform float dissolve_spread = 80.0;
uniform vec4 edge_color : source_color = vec4(1.0);

varying vec2 local_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 c = COLOR;
	// keep the black outline untouched
	float bright = step(0.15, max(c.r, max(c.g, c.b)));
	float d = abs(local_pos.x + local_pos.y * 0.4 - sweep_x);
	float shine = smoothstep(band, 0.0, d);
	c.rgb = mix(c.rgb, vec3(1.0), clamp(shine * 0.85 + flash, 0.0, 1.0) * bright);

	// 3px blocks crumble at random times behind the dissolve front
	float n = hash(floor(local_pos / 3.0));
	float t = local_pos.x - dissolve_x + n * dissolve_spread;
	float edge = 1.0 - smoothstep(0.0, 12.0, t);
	c.rgb = mix(c.rgb, edge_color.rgb, edge);
	c.a *= step(0.0, t);
	COLOR = c;
}
