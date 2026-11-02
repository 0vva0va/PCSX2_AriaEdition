//---------------------------------------------------------------@//
Texture2D Texture;
SamplerState Sampler;

cbuffer cb0
{
    float4 params;
};


#define CoefLuma float3(0.2126, 0.7152, 0.0722)
//---------------------------------------------------------------@//


//---- MAIN PASS ------@//
float4 VibrancePass(float3 color)
{
    float Vibrance = params.x;
    float3 VibranceRGBBalance = params.yzw;
	
    float luma = dot(CoefLuma, color);

    float max_color = max(color.r, max(color.g, color.b)); // Find the strongest color
    float min_color = min(color.r, min(color.g, color.b)); // Find the weakest color

    float color_saturation = max_color - min_color; // The difference between the two is the saturation

	// Extrapolate between luma and original by 1 + (1-saturation) - current
    float3 coeffVibrance = float3(VibranceRGBBalance * Vibrance);
    color = lerp(luma, color, 1.0 + (coeffVibrance * (1.0 - (sign(coeffVibrance) * color_saturation))));

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
    return VibrancePass(sColour);
}