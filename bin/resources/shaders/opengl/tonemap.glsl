/**
 * Tonemap version 1.1
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 */

//#version 420 // Keep it for editor detection

#ifdef FRAGMENT_SHADER

uniform vec3 params;
uniform vec2 params2;
uniform vec3 fogColour;

in vec2 PSin_t;

layout(binding = 0) uniform sampler2D TextureSampler;

layout(location = 0) out vec4 SV_Target0;

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
    vec4 color = texture(TextureSampler, PSin_t);

    SV_Target0 = TonemapPass(color);
}

#endif