shader_type canvas_item;

uniform vec2 resolution = vec2(1920, 1080);
uniform float density : hint_range(1.0, 500.0, 1.0) = 500.0;
uniform vec3 color : source_color = vec3(0.5);
uniform float compression : hint_range(0.1, 1.0, 0.01) = 0.5;
uniform float trail_size : hint_range(5.0, 100.0, 0.1) = 50.0;
uniform float speed : hint_range(0.01, 5.0, 0.01) = 3.0;
uniform float brightness : hint_range(0.1, 10.0, 0.1) = 5;
uniform float center_size : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float center_edge : hint_range(0.0, 1.0, 0.01) = 0.4;


void fragment() {
	float time = TIME * speed;
	vec2 uv = UV - 0.5;
	uv.x *= resolution.x / resolution.y;
	float circle = smoothstep(center_size - center_edge, center_size, length(uv));
	float dist = length(uv); 
	float angle = atan(uv.x, uv.y);
	uv = vec2(angle / PI, 1.0 / dist);
	uv.x *= density;
	vec2 duv = vec2(floor(uv.x), uv.y) * compression;
	float offset = sin(duv.x);
	float fall = cos(duv.x * 30.0);
	float trail = mix (100.0, trail_size, fall); 
	float drop = fract(duv.y + time * fall + offset) * trail;
	drop = 1.0 / drop;
	drop = smoothstep(0.0, 1.0, drop * drop);
	drop = sin(drop * PI) * fall * brightness;
	float shape = sin(fract(uv.x) * PI);
	drop *= shape * shape;
	COLOR = vec4(color * drop * circle, 1.0);
}

