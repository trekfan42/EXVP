shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.0, 0.8, 0.8, 1.0); // yellowish
uniform vec4 color2 : source_color = vec4(0.0, 0.08, 0.9, 1.0); // deep blue
uniform vec4 color3 : source_color = vec4(0.4, 0.1, 0.6, 1.0); // reddish
uniform vec4 color4 : source_color = vec4(0.0, 0.04, 0.4, 1.0); // light blue

uniform float speed = 1.0;
uniform float frequency = 5.0;
uniform float amplitude = 30.0;
uniform float rotation_strength = 720.0;

uniform float scale = 1.0; // Zoom in/out
uniform bool use_bg_color = true;
uniform vec4 bg_color : source_color = vec4(0.05, 0.05, 0.1, 1.0); // optional

// Smoothstep helper
float S(float a, float b, float t) {
	return smoothstep(a, b, t);
}

// Hash function (2D)
vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(2127.1, 81.17)), dot(p, vec2(1269.5, 283.37)));
	return fract(sin(p) * 43758.5453);
}

// 2D Gradient noise
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	
	float n = mix(
		mix(dot(-1.0 + 2.0 * hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
		    dot(-1.0 + 2.0 * hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(-1.0 + 2.0 * hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
		    dot(-1.0 + 2.0 * hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y);
	return 0.5 + 0.5 * n;
}

// 2D rotation
mat2 Rot(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(vec2(c, -s), vec2(s, c));
}


void fragment() {
	vec2 uv = UV * scale;
	vec2 tuv = uv - 0.5;

	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;

	// Noise-based rotation
	float degree = noise(vec2(TIME * 0.1 * speed, tuv.x * tuv.y));
	tuv.y /= ratio;
	tuv *= Rot(radians((degree - 0.5) * rotation_strength + 180.0));
	tuv.y *= ratio;

	// Wavy distortion
	float t = TIME * speed;
	tuv.x += sin(tuv.y * frequency + t) / amplitude;
	tuv.y += sin(tuv.x * frequency * 1.5 + t) / (amplitude * 0.5);

	// Color blend layers
	vec3 layer1 = mix(color1.rgb, color2.rgb, S(-0.3, 0.2, (tuv * Rot(radians(-5.0))).x));
	vec3 layer2 = mix(color3.rgb, color4.rgb, S(-0.3, 0.2, (tuv * Rot(radians(-5.0))).x));
	vec3 blended = mix(layer1, layer2, S(0.5, -0.3, tuv.y));

	// Final color
	vec3 col = blended;
	if (use_bg_color) {
		col = mix(bg_color.rgb, col, 0.99);
	}
	COLOR = vec4(col, 1.0);
	
	vec4 tex_color = texture(TEXTURE, UV);

	float blend = tex_color.a; // 0 = transparent, 1 = opaque
	COLOR = mix(tex_color, vec4(col, 1.0), blend);


}
