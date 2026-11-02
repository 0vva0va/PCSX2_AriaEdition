#version 420
//---------------------------------------------------------------@//
#ifdef FRAGMENT_SHADER

uniform vec4 params;

in vec2 PSin_t;

layout(binding = 0) uniform sampler2D TextureSampler;

layout(location = 0) out vec4 SV_Target0;


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
    vec4 sColour = texture(TextureSampler, PSin_t);
    SV_Target0   = VibrancePass(sColour);
}

#endif