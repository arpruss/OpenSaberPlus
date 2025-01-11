shader_type spatial;
render_mode cull_disabled,diffuse_burley,specular_schlick_ggx;

const float sub_emission_energy = 0.18;
const float cut_white_margin = 0.04;

uniform vec4 color : source_color;
uniform bool cutted = false;
uniform float cut_dist_from_center = 0.0;
uniform float cut_angle = 0.0;
uniform float cut_vanish = 0.0;

// [firepal]TODO: Build matrix on CPU (I tried but couldn't')
mat3 rotation3dZ(float angle) {
	float s = sin(angle);
	float c = cos(angle);

	return mat3(
		vec3(c, s, 0.0),
		vec3(-s, c, 0.0),
		vec3(0.0, 0.0, 1.0)
	);
}

varying float cut_interp;
void vertex() {
	if (cutted) {
		float cut_line = cut_dist_from_center+(VERTEX*rotation3dZ(cut_angle)).x;
		cut_interp = cut_line - cut_vanish;
	} else {
		// not cut, ensure no discard later
		cut_interp = 1.0;
	}
}

void fragment() {
	// Discard all pixels "in the cut"
	if (cut_interp < 0.0) {
		discard;
	}

	ALBEDO = color.rgb;
	METALLIC = 0.3;
	ROUGHNESS = 0.2;
	if (FRONT_FACING) {
		float x_centered = UV.x - 0.25;
		float y_centered = UV.y - 0.25;
		float dist_from_center_squared = x_centered * x_centered + y_centered * y_centered;
		if (dist_from_center_squared <= 0.001) {
			EMISSION = vec3(1.0);
		} else {
			EMISSION = color.rgb * sub_emission_energy;
			if (cutted){
				// soft white margin
				EMISSION += vec3(smoothstep(cut_white_margin+0.01,cut_white_margin,cut_interp));
				// hard white margin
				//EMISSION += vec3( float(cut_white_margin < cut_interp) );
			}
		}
	} else {
		EMISSION = vec3(1.0);
	}
}
