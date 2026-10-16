// Real clothes and skin on the Universal Base Characters (Person's wardrobe, made
// by tools/blender/wardrobe.py): each piece one colour, with a soft mottle in the
// rest pose's space (CUSTOM0, from Person.bake) so cloth doesn't look painted on,
// and a sheen at grazing angles for wool; or a texture, the body's own skin,
// tinted from its average colour to the person's skin.
//
// Some pieces are single sheets (the jacket's shell), so both sides are drawn and
// the back side lit as if it faced the camera.
shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 color : source_color = vec3(0.5);
uniform float roughness = 0.8;
uniform float metallic = 0.0;
uniform float specular = 0.5;
// How much the colour wanders over the cloth (0 for skin, leather and metal).
uniform float mottle = 0.0;
// Fabric sheen at grazing angles.
uniform float sheen = 0.0;
uniform bool textured = false;
uniform sampler2D tex : source_color, hint_default_white, filter_linear_mipmap_anisotropic, repeat_disable;
// The texture's own average colour: it's tinted from this to `color`.
uniform vec3 tex_mean : source_color = vec3(1.0);

// The same as person.gdshader's, so a dressed person lights up and fades the same.
instance uniform float hurt = 0.0;
instance uniform float dim = 0.0;

varying vec3 rest;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	rest = CUSTOM0.xyz;
}

void fragment() {
	vec3 c = color;
	if (textured) {
		c = texture(tex, UV).rgb * color / max(tex_mean, vec3(0.001));
	}
	float n = noise3(rest * 22.0) * 0.6 + noise3(rest * 61.0) * 0.4;
	c *= 1.0 + (n - 0.5) * mottle;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = mix(c, vec3(1.0, 0.9, 0.85), clamp(hurt, 0.0, 1.0) * 0.5) * (1.0 - dim * 0.4);
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
	RIM = sheen;
	RIM_TINT = 0.6;
	EMISSION = vec3(1.0, 0.5, 0.3) * clamp(hurt, 0.0, 1.0) * 0.4;
}
