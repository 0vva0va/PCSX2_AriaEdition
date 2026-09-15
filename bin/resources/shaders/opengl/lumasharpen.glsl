//#version 420 // Keep it for editor detection

#ifdef FRAGMENT_SHADER

uniform vec4 params;

in vec2 PSin_t;

layout(binding = 0) uniform sampler2D TextureSampler;
layout(location = 0) out vec4 SV_Target0;


#define CoefLuma vec3(0.2126, 0.7152, 0.0722)
#define saturate(x) clamp(x, 0.0, 1.0)

// ----------------------------------------------
vec4 LumaSharpenPass(vec4 sColour, vec2 tex, vec2 pixelSize)
{
    float sharp_strength = params.x;
    float sharp_clamp    = params.y;
    int   pattern        = int(params.z);
    float offset_bias    = params.w;

    vec3 ori = sColour.rgb; // ori = original pixel

    vec3 sharp_strength_luma = (CoefLuma * sharp_strength); // combining the strength and luma multipliers

    // Sampling Patterns
    vec3 blur_ori;
    //   [ NW,   , NE ] Each texture lookup (except ori)
    //   [   ,ori,    ] samples 4 pixels
    //   [ SW,   , SE ]

    // -- Pattern 1 -- A (fast) 7 tap gaussian using only 2+1 texture fetches.
    if (pattern == 0)
    {
        // -- Gaussian filter --
        //   [ 1/9, 2/9,    ]     [ 1 , 2 ,   ]
        //   [ 2/9, 8/9, 2/9]  =  [ 2 , 8 , 2 ]
        //   [    , 2/9, 1/9]     [   , 2 , 1 ]
        blur_ori  = texture(TextureSampler, tex + (pixelSize / 3.0) * offset_bias).rgb; // North West
        blur_ori += texture(TextureSampler, tex + (-pixelSize / 3.0) * offset_bias).rgb; // South East

        //blur_ori += tex2D(ReShade::BackBuffer, tex + (pixelSize / 3.0) * offset_bias); // North East
        //blur_ori += tex2D(ReShade::BackBuffer, tex + (-pixelSize / 3.0) * offset_bias); // South West

        blur_ori /= 2; //Divide by the number of texture fetches

        sharp_strength_luma *= 1.5; // Adjust strength to aproximate the strength of pattern 2
    }

    // -- Pattern 2 -- A 9 tap gaussian using 4+1 texture fetches.
    if (pattern == 1)
    {
        // -- Gaussian filter --
        //   [ .25, .50, .25]     [ 1 , 2 , 1 ]
        //   [ .50,   1, .50]  =  [ 2 , 4 , 2 ]
        //   [ .25, .50, .25]     [ 1 , 2 , 1 ]

        blur_ori  = texture(TextureSampler, tex + vec2(pixelSize.x, -pixelSize.y) * 0.5 * offset_bias).rgb; // South East
        blur_ori += texture(TextureSampler, tex - pixelSize * 0.5 * offset_bias).rgb; // South West
        blur_ori += texture(TextureSampler, tex + pixelSize * 0.5 * offset_bias).rgb; // North East
        blur_ori += texture(TextureSampler, tex - vec2(pixelSize.x, -pixelSize.y) * 0.5 * offset_bias).rgb; // North West

        blur_ori *= 0.25; // ( /= 4) Divide by the number of texture fetches
    }

    // -- Pattern 3 -- An experimental 17 tap gaussian using 4+1 texture fetches.
    if (pattern == 2)
    {
        // -- Gaussian filter --
        //   [   , 4 , 6 ,   ,   ]
        //   [   ,16 ,24 ,16 , 4 ]
        //   [ 6 ,24 ,   ,24 , 6 ]
        //   [ 4 ,16 ,24 ,16 ,   ]
        //   [   ,   , 6 , 4 ,   ]

        blur_ori  = texture(TextureSampler, tex + pixelSize * vec2(0.4, -1.2) * offset_bias).rgb; // South South East
        blur_ori += texture(TextureSampler, tex - pixelSize * vec2(1.2, 0.4) * offset_bias).rgb; // West South West
        blur_ori += texture(TextureSampler, tex + pixelSize * vec2(1.2, 0.4) * offset_bias).rgb; // East North East
        blur_ori += texture(TextureSampler, tex - pixelSize * vec2(0.4, -1.2) * offset_bias).rgb; // North North West

        blur_ori *= 0.25; // ( /= 4) Divide by the number of texture fetches

        sharp_strength_luma *= 0.51;
    }

    // -- Pattern 4 -- A 9 tap high pass (pyramid filter) using 4+1 texture fetches.
    if (pattern == 3)
    {
        // -- Gaussian filter --
        //   [ .50, .50, .50]     [ 1 , 1 , 1 ]
        //   [ .50,    , .50]  =  [ 1 ,   , 1 ]
        //   [ .50, .50, .50]     [ 1 , 1 , 1 ]

        blur_ori  = texture(TextureSampler, tex + vec2(0.5 * pixelSize.x, -pixelSize.y * offset_bias)).rgb; // South South East
        blur_ori += texture(TextureSampler, tex + vec2(offset_bias * -pixelSize.x, 0.5 * -pixelSize.y)).rgb; // West South West
        blur_ori += texture(TextureSampler, tex + vec2(offset_bias * pixelSize.x, 0.5 * pixelSize.y)).rgb; // East North East
        blur_ori += texture(TextureSampler, tex + vec2(0.5 * -pixelSize.x, pixelSize.y * offset_bias)).rgb; // North North West

        //blur_ori += (2 * ori); // Probably not needed. Only serves to lessen the effect.

        blur_ori /= 4.0; //Divide by the number of texture fetches

        sharp_strength_luma *= 0.666; // Adjust strength to aproximate the strength of pattern 2
    }

    /*-----------------------------------------------------------.
    	/                            Sharpen                          /
    	'-----------------------------------------------------------*/

    // -- Calculate the sharpening --
    vec3 sharp = ori - blur_ori; //Subtracting the blurred image from the original image

    // -- Adjust strength of the sharpening and clamp it--
    vec4 sharp_strength_luma_clamp = vec4(sharp_strength_luma * (0.5 / sharp_clamp), 0.5); //Roll part of the clamp into the dot

    //sharp_luma = saturate((0.5 / sharp_clamp) * sharp_luma + 0.5); //scale up and clamp
    float sharp_luma = saturate(dot(vec4(sharp, 1.0), sharp_strength_luma_clamp)); //Calculate the luma, adjust the strength, scale up and clamp
    sharp_luma = (sharp_clamp * 2.0) * sharp_luma - sharp_clamp; //scale down

    // -- Combining the values to get the final sharpened pixel	--
    vec3 outputcolor = ori + sharp_luma; // Add the sharpening to the the original.s

    return vec4(saturate(outputcolor), 1.0);
}

void ps_main()
{
    vec2 pixelSize = vec2(textureSize(TextureSampler, 0));
    vec2 pixelSizeRcp = 1.0 / pixelSize;
    vec4 color = texture(TextureSampler, PSin_t);

    SV_Target0 = LumaSharpenPass(color, PSin_t, pixelSizeRcp);
}

#endif