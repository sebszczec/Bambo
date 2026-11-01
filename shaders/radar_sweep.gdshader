shader_type canvas_item;

// 360 degree scanner of the Boulder Beetle: a sweep line turning around the
// beetle with a fading wedge behind it, a thin ring at the trigger range and
// faint arcs moving outward. Same colors as the Guard's radar_beam.
// The quad is `size` px square and centered on the beetle; `radius` can grow
// up to size / 2 (the ring shows the blast range while charging).

uniform float size = 420.0;
uniform float radius = 140.0;
uniform vec4 scan_color : source_color = vec4(0.42, 0.86, 0.92, 1.0);
uniform vec4 sweep_color : source_color = vec4(0.71, 0.98, 1.0, 1.0);
// amber-orange of the art bible, the beetle is about to blow
uniform vec4 alert_color : source_color = vec4(1.0, 0.48, 0.29, 1.0);
// 0 = scanning, 1 = charging
uniform float alert : hint_range(0.0, 1.0) = 0.0;
uniform float sweep_speed = 2.4;
// length of the fading wedge behind the sweep line, in radians
uniform float trail = 1.5;
// random per beetle, so a group does not sweep in sync
uniform float phase = 0.0;
uniform float wave_speed = 45.0;
uniform float wave_spacing = 46.0;
// HDR boost so the glow catches the line and the ring
uniform float intensity = 1.4;
// spawn fade in, same name as in the Dissolve shader so the enemy script drives both
uniform float DissolveValue : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * size;
	float r = length(p);

	float inside = 1.0 - smoothstep(radius - 1.5, radius, r);
	// nothing under the body
	float hole = smoothstep(16.0, 30.0, r);

	// angle behind the sweep line, 0 on the line
	float a = atan(p.y, p.x);
	float behind = mod(TIME * sweep_speed + phase - a, TAU);
	float wedge = pow(clamp(1.0 - behind / trail, 0.0, 1.0), 2.0);
	float line = 1.0 - smoothstep(0.0, 0.04, behind);

	// thin ring at the range, brighter where the sweep just passed
	float ring = smoothstep(radius - 4.0, radius - 1.5, r) * inside;
	ring *= 0.35 + 0.65 * wedge;

	// arcs moving outward, sharp front and soft tail
	float w = fract((r - TIME * wave_speed) / wave_spacing);
	float arc = smoothstep(0.0, 0.05, w) * (1.0 - smoothstep(0.05, 0.25, w));
	arc *= 0.18 * (1.0 - 0.7 * r / max(radius, 1.0));

	float fill = 0.02 + 0.2 * wedge + 0.75 * line;
	fill *= 0.6 + 0.4 * r / max(radius, 1.0);

	// a charging beetle pulses
	float pulse = 1.0 + alert * 0.5 * sin(TIME * 18.0);

	vec3 base = mix(scan_color.rgb, alert_color.rgb, alert);
	vec3 bright = mix(sweep_color.rgb, alert_color.rgb * 1.4, alert);
	float shine = clamp(line + ring, 0.0, 1.0);
	vec3 rgb = mix(base, bright, shine) * intensity;
	float alpha = clamp(fill + ring + arc, 0.0, 1.0) * inside * hole * pulse * DissolveValue;
	COLOR = vec4(rgb, clamp(alpha, 0.0, 1.0) * COLOR.a);
}
