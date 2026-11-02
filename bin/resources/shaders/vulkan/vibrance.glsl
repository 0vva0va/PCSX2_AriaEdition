#version 420
//---------------------------------------------------------------@//
#ifdef VERTEX_SHADER

layout(location = 0) in vec4 a_pos;
layout(location = 1) in vec2 a_tex;

layout(location = 0) out vec2 v_tex;

void main()
{
	gl_Position = vec4(a_pos.x, -a_pos.y, a_pos.z, a_pos.w);
	v_tex = a_tex;
}

#endif

#ifdef FRAGMENT_SHADER

layout(push_constant) uniform cb0
{
	vec3 params;
};

layout(set = 0, binding = 0) uniform sampler2D samp0;
layout(location = 0) in vec2 v_tex;
layout(location = 0) out vec4 o_col0;


#define CoefLuma vec3(0.2126, 0.7152, 0.0722)
#define saturate(x) clamp(x, 0.0, 1.0)
//---------------------------------------------------------------@//


//---- MAIN PASS ------@//
vec4 VibrancePass(vec3 color)
{
    float Vibrance = params.x;
    vec3 VibranceRGBBalance = params.yzw;
	
	float luma = dot(CoefLuma, color);

	float max_color = max(color.r, max(color.g, color.b)); // Find the strongest color
	float min_color = min(color.r, min(color.g, color.b)); // Find the weakest color

	float color_saturation = max_color - min_color; // The difference between the two is the saturation

	// Extrapolate between luma and original by 1 + (1-saturation) - current
	vec3 coeffVibrance = vec3(VibranceRGBBalance * Vibrance);
	color = lerp(luma, color, 1.0 + (coeffVibrance * (1.0 - (sign(coeffVibrance) * color_saturation))));

	return vec4(color, 1.0);
}




void main()
{
    vec4 c = texture(samp0, v_tex);
    o_col0 = VibrancePass(c);
}

#endif