
Texture2D Texture;
SamplerState Sampler;

cbuffer cb0
{
	float4 params;
};

#define CoefLuma float3(0.2126, 0.7152, 0.0722)


// ----------------------------------------------
float4 LumaSharpenPass(float4 sColour, float2 tex, float2 pixelSize)
{
    float sharp_strength = params.x;
    float sharp_clamp    = params.y;
    int   pattern        = (int)params.z;
    float offset_bias    = params.w;

    float3 ori = sColour.rgb; // ori = original pixel

    float3 sharp_strength_luma = (CoefLuma * sharp_strength); // combining the strength and luma multipliers

    float3 blur_ori;
    
    // Sampling Patterns
    //   [ NW,   , NE ] Each texture lookup (except ori)
    //   [   ,ori,    ] samples 4 pixels
    //   [ SW,   , SE ]

    if (pattern == 0)  // Pattern 1 - A (fast) 7 tap gaussian using only 2+1 texture fetches.
    {
        // -- Gaussian filter --
        //   [ 1/9, 2/9,    ]     [ 1 , 2 ,   ]
        //   [ 2/9, 8/9, 2/9]  =  [ 2 , 8 , 2 ]
        //   [    , 2/9, 1/9]     [   , 2 , 1 ]
        
        blur_ori  = Texture.Sample(Sampler, tex + (pixelSize / 3.0) * offset_bias).rgb; // North West
        blur_ori += Texture.Sample(Sampler, tex + (-pixelSize / 3.0) * offset_bias).rgb; // South East
        //blur_ori += tex2D(ReShade::BackBuffer, tex + (pixelSize / 3.0) * offset_bias); // North East
        //blur_ori += tex2D(ReShade::BackBuffer, tex + (-pixelSize / 3.0) * offset_bias); // South West

        blur_ori /= 2;              // divide by the number of texture fetches
        sharp_strength_luma *= 1.5; // adjust strength to aproximate the strength of pattern 2
    }

    
    if (pattern == 1)      // Pattern 2 - A 9 tap gaussian using 4+1 texture fetches.
    {
        // -- Gaussian filter --
        //   [ .25, .50, .25]     [ 1 , 2 , 1 ]
        //   [ .50,   1, .50]  =  [ 2 , 4 , 2 ]
        //   [ .25, .50, .25]     [ 1 , 2 , 1 ]

        blur_ori  = Texture.Sample(Sampler, tex + float2(pixelSize.x, -pixelSize.y) * 0.5 * offset_bias).rgb; // South East
        blur_ori += Texture.Sample(Sampler, tex - pixelSize * 0.5 * offset_bias).rgb;                         // South West
        blur_ori += Texture.Sample(Sampler, tex + pixelSize * 0.5 * offset_bias).rgb;                         // North East
        blur_ori += Texture.Sample(Sampler, tex - float2(pixelSize.x, -pixelSize.y) * 0.5 * offset_bias).rgb; // North West

        blur_ori *= 0.25; // divide by the number of texture fetches
    }

    
    if (pattern == 2)    // Pattern 3 - An experimental 17 tap gaussian using 4+1 texture fetches.
    {
        // -- Gaussian filter --
        //   [   , 4 , 6 ,   ,   ]
        //   [   ,16 ,24 ,16 , 4 ]
        //   [ 6 ,24 ,   ,24 , 6 ]
        //   [ 4 ,16 ,24 ,16 ,   ]
        //   [   ,   , 6 , 4 ,   ]

        blur_ori  = Texture.Sample(Sampler, tex + pixelSize * float2(0.4, -1.2) * offset_bias).rgb; // South South East
        blur_ori += Texture.Sample(Sampler, tex - pixelSize * float2(1.2, 0.4) * offset_bias).rgb;  // West South West
        blur_ori += Texture.Sample(Sampler, tex + pixelSize * float2(1.2, 0.4) * offset_bias).rgb;  // East North East
        blur_ori += Texture.Sample(Sampler, tex - pixelSize * float2(0.4, -1.2) * offset_bias).rgb; // North North West

        blur_ori *= 0.25;
        sharp_strength_luma *= 0.51;
    }

    
    if (pattern == 3)        // Pattern 4 - A 9 tap high pass (pyramid filter) using 4+1 texture fetches.
    {
        // -- Gaussian filter --
        //   [ .50, .50, .50]     [ 1 , 1 , 1 ]
        //   [ .50,    , .50]  =  [ 1 ,   , 1 ]
        //   [ .50, .50, .50]     [ 1 , 1 , 1 ]

        blur_ori  = Texture.Sample(Sampler, tex + float2(0.5 * pixelSize.x, -pixelSize.y * offset_bias)).rgb; // South South East
        blur_ori += Texture.Sample(Sampler, tex + float2(offset_bias * -pixelSize.x, 0.5 * -pixelSize.y)).rgb; // West South West
        blur_ori += Texture.Sample(Sampler, tex + float2(offset_bias * pixelSize.x, 0.5 * pixelSize.y)).rgb; // East North East
        blur_ori += Texture.Sample(Sampler, tex + float2(0.5 * -pixelSize.x, pixelSize.y * offset_bias)).rgb; // North North West

        blur_ori *= 0.25;
        sharp_strength_luma *= 0.666; // adjust strength to aproximate the strength of pattern 2
    }

    /*-----------------------------------------------------------.
    /                            Sharpen                         /
    '-----------------------------------------------------------*/
    float3 sharp = ori - blur_ori; // subtracting the blurred image from the original image
    
    float4 sharp_strength_luma_clamp = float4(sharp_strength_luma * (0.5 / sharp_clamp), 0.5); // adjust strength of the sharpening and clamp it

    float sharp_luma = saturate(dot(float4(sharp, 1.0), sharp_strength_luma_clamp)); // calculate the luma, adjust the strength, scale up and clamp
          sharp_luma = (sharp_clamp * 2.0) * sharp_luma - sharp_clamp;               // scale down

    float3 outputcolor = ori + sharp_luma; // add the sharpening to the the original.

    return float4(saturate(outputcolor), 1.0);
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
    
    float2 pixelSizeRcp = float2(1.0 / pixelSize.x, 1.0 / pixelSize.y);

	float4 c = Texture.Sample(Sampler, input.t);
    
	return LumaSharpenPass(c, input.t, pixelSizeRcp);
}
