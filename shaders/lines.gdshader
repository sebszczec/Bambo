shader_type canvas_item;

#define S smoothstep
#define IS(x, y, z) (1.0 - smoothstep(x, y, z))

uniform vec2 resolution = vec2(600, 400);
uniform vec3 line_color : source_color = vec3(0.2, 0.6, 0.2);
uniform float line_thickness: hint_range(0.01, 1.0, 0.01) = 0.05;
uniform float speed = 0.5;
uniform float amp_coeff = 0.1;
uniform float freq_coeff = 0.5; 
uniform float iterations: hint_range(1.0, 20.0, 1) = 5;
uniform float brightness: hint_range(0.1, 20.0, 0.1) = 0.5;

vec3 draw_line(vec2 uv, vec3 color, float shift, float freq) {
	uv.y += IS(0.0, 1.0, abs(uv.x)) * sin(uv.x + shift * freq) * amp_coeff * sin(uv.x + shift);
	return IS(0.0, line_thickness * S(-0.2, 0.9, abs(uv.x)), abs(uv.y)) * color;
}

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= resolution.x / resolution.y;
	float shift = TIME * speed;
	vec3 color = vec3(0.0);
	for (float i = 0.0; i < iterations; i += 1.0) {
		color += draw_line(uv, line_color, shift + i * 0.4, 1.0 + freq_coeff);
	}
	
	COLOR = vec4(color * brightness, 1.0);

}

