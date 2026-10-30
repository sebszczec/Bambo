shader_type canvas_item;

// Radar cone of the Guard, styled after its Gemini clip: a soft cyan wedge
// with bright arcs travelling outward. The apex is at the top middle of the
// texture, the cone points down (+Y), so the node's +Y is the beam direction.

uniform vec2 size = vec2(100.0, 145.0);
uniform float half_angle = 0.29;
uniform vec4 beam_color : source_color = vec4(0.42, 0.86, 0.92, 1.0);
uniform vec4 arc_color : source_color = vec4(0.71, 0.98, 1.0, 1.0);
uniform vec4 alert_color : source_color = vec4(1.0, 0.25, 0.2, 1.0);
// 0 = scanning, 1 = player detected
uniform float alert : hint_range(0.0, 1.0) = 0.0;
uniform float wave_speed = 70.0;
uniform float wave_spacing = 34.0;
// HDR boost so the glow catches the arcs
uniform float intensity = 1.4;
// spawn fade in, same name as in the Dissolve shader so the enemy script drives both
uniform float DissolveValue : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 p = (UV - vec2(0.5, 0.0)) * size;
	float r = length(p);
	float angle = abs(atan(p.x, p.y));
	float range = size.y;

	// soft cone edges and a fade towards the end of the range
	float side = 1.0 - smoothstep(half_angle * 0.8, half_angle, angle);
	float reach = 1.0 - smoothstep(range * 0.75, range, r);
	float mask = side * reach * smoothstep(0.0, 6.0, r);

	// wedge fill, a bit stronger at the edges like a scanner
	float fill = 0.16 + 0.12 * smoothstep(half_angle * 0.5, half_angle * 0.9, angle);
	fill *= 1.0 - 0.5 * r / range;

	// arcs moving outward, sharp front and soft tail
	float w = fract((r - TIME * wave_speed) / wave_spacing);
	float arc = smoothstep(0.0, 0.06, w) * (1.0 - smoothstep(0.06, 0.3, w));
	arc *= 0.9 * (1.0 - 0.6 * r / range);

	vec3 base = mix(beam_color.rgb, alert_color.rgb, alert);
	vec3 bright = mix(arc_color.rgb, alert_color.rgb * 1.3, alert);
	vec3 rgb = mix(base, bright, clamp(arc * 1.4, 0.0, 1.0)) * intensity;
	float a = clamp(fill + arc, 0.0, 1.0) * mask * DissolveValue;
	COLOR = vec4(rgb, a * COLOR.a);
}
