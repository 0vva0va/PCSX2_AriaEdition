/**
 * Tonemap version 1.1
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 */

#version 420

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
	vec2 params2;
	vec3 fogColour;
};

layout(set = 0, binding = 0) uniform sampler2D samp0;
layout(location = 0) in vec2 v_tex;
layout(location = 0) out vec4 o_col0;


#define CoefLuma vec3(0.2126, 0.7152, 0.0722)
#define saturate(x) clamp(x, 0.0, 1.0)



vec4 TonemapPass(vec3 sColour)
{
	float Gamma = params.x;
	float Exposure = params.y;
	float Saturation = params.z;

	float Bleach = params2.x;
	float Defog = params2.y;

	vec3 FogColor = fogColour;

	vec3 color  = sColour;
	     color  = saturate(color - Defog * FogColor * 2.55); // Defog
	     color *= pow(2.0, Exposure);                        // Exposure
	     color  = pow(color, Gamma);                         // Gamma

	float lum = dot(CoefLuma, color);
	
	float L = saturate(10.0 * (lum - 0.45));
	vec3 A2 = Bleach * color;

	vec3 result1 = 2.0 * color * lum;
	vec3 result2 = 1.0 - 2.0 * (1.0 - lum) * (1.0 - color);
	
	vec3 newColor = lerp(result1, result2, L);
	vec3 mixRGB   = A2 * newColor;
    
	color += ((1.0 - A2) * mixRGB);
	
	vec3 middlegray = dot(color, (1.0 / 3.0));
	vec3 diffcolor  = color - middlegray;

	color = (color + diffcolor * Saturation) / (1 + (diffcolor * Saturation)); // Saturation
	
	return vec4(color, 1.0);
}


void main()
{
    vec4 c = texture(samp0, v_tex);
    o_col0 = TonemapPass(c);
}

#endif