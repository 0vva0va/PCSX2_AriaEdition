/**
 * HDR
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Not actual HDR - It just tries to mimic an HDR look (relatively high performance cost)
 */

//-----------------------------------------------------------------------------------
Texture2D Texture;
SamplerState Sampler;

cbuffer cb0
{
	float4 params;
};


float4 HDRPass(float2 texcoord, float2 pixelSize)
{
    float HDRPower = params.x;
    float radius1  = params.y;
    float radius2  = params.z;
	
	float3 sColour = Texture.Sample(Sampler, texcoord).rgb;

    float3 bloomSum1 = float3(0.0, 0.0, 0.0);
	bloomSum1  = Texture.Sample(Sampler, texcoord + float2(1.5, -1.5)  * radius1 * pixelSize).rgb;
	bloomSum1 += Texture.Sample(Sampler, texcoord + float2(-1.5, -1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += Texture.Sample(Sampler, texcoord + float2( 1.5,  1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += Texture.Sample(Sampler, texcoord + float2(-1.5,  1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += Texture.Sample(Sampler, texcoord + float2( 0.0, -2.5) * radius1 * pixelSize).rgb;
	bloomSum1 += Texture.Sample(Sampler, texcoord + float2( 0.0,  2.5) * radius1 * pixelSize).rgb;
	bloomSum1 += Texture.Sample(Sampler, texcoord + float2(-2.5,  0.0) * radius1 * pixelSize).rgb;
	bloomSum1 += Texture.Sample(Sampler, texcoord + float2( 2.5,  0.0) * radius1 * pixelSize).rgb;

	bloomSum1 *= 0.005;

    float3 bloomSum2 = float3(0.0, 0.0, 0.0);
	bloomSum2  = Texture.Sample(Sampler, texcoord + float2(1.5, -1.5)  * radius2 * pixelSize).rgb;
	bloomSum2 += Texture.Sample(Sampler, texcoord + float2(-1.5, -1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += Texture.Sample(Sampler, texcoord + float2( 1.5,  1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += Texture.Sample(Sampler, texcoord + float2(-1.5,  1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += Texture.Sample(Sampler, texcoord + float2( 0.0, -2.5) * radius2 * pixelSize).rgb;	
	bloomSum2 += Texture.Sample(Sampler, texcoord + float2( 0.0,  2.5) * radius2 * pixelSize).rgb;
	bloomSum2 += Texture.Sample(Sampler, texcoord + float2(-2.5,  0.0) * radius2 * pixelSize).rgb;
	bloomSum2 += Texture.Sample(Sampler, texcoord + float2( 2.5,  0.0) * radius2 * pixelSize).rgb;

	bloomSum2 *= 0.010;

	float dist   = radius2 - radius1;
	float3 HDR   = (sColour + (bloomSum2 - bloomSum1)) * dist;
	float3 blend = HDR + sColour;

	sColour = pow(abs(blend), float3(abs(HDRPower), abs(HDRPower), abs(HDRPower))) + HDR; 
	
	return float4(saturate(sColour), 1.0);
}


struct PS_INPUT
{
	float4 p : SV_Position;
	float2 t : TEXCOORD0;
};

float4 ps_main(PS_INPUT input) : SV_Target0
{
	float2 pixelSize;
	Texture.GetDimensions(pixelSize.x, pixelSize.y);
	float2 pixelSizeRcp = float2(1.0 / float(pixelSize.x), 1.0 / float(pixelSize.y));

	return HDRPass(input.t, pixelSizeRcp);
}