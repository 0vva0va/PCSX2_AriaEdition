/**
 * Tonemap version 1.1
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 */


Texture2D Texture;
SamplerState Sampler;

cbuffer cb0
{
    float4 params;
    float2 params2;
    float4 fogColour;
};

#define CoefLuma float3(0.2126, 0.7152, 0.0722)



float4 TonemapPass(float3 sColour)
{
    float Gamma = params.x;
    float Exposure = params.y;
    float Saturation = params.z;

    float Bleach = params2.x;
    float Defog = params2.y;

    float3 FogColor = fogColour;
	
	float3 color  = sColour;
	     color  = saturate(color - Defog * FogColor * 2.55); // Defog
	     color *= pow(2.0, Exposure);                        // Exposure
	     color  = pow(color, Gamma);                         // Gamma

	float lum = dot(CoefLuma, color);
	
	float L = saturate(10.0 * (lum - 0.45));
	float3 A2 = Bleach * color;

	float3 result1 = 2.0 * color * lum;
	float3 result2 = 1.0 - 2.0 * (1.0 - lum) * (1.0 - color);
	
	float3 newColor = lerp(result1, result2, L);
	float3 mixRGB   = A2 * newColor;
    
	color += ((1.0 - A2) * mixRGB);
	
	float3 middlegray = dot(color, (1.0 / 3.0));
	float3 diffcolor  = color - middlegray;

	color = (color + diffcolor * Saturation) / (1 + (diffcolor * Saturation)); // Saturation
	
	return float4(color, 1.0);
}



struct PS_INPUT
{
    float4 p : SV_Position;
    float2 t : TEXCOORD0;
};


float4 ps_main(PS_INPUT input) : SV_Target0
{
    float3 sColour = Texture.Sample(Sampler, input.t).rgb;

    return TonemapPass(sColour);
}