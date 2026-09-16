//#version 420 // Keep it for editor detection
/**
 * HDR
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Not actual HDR - It just tries to mimic an HDR look (relatively high performance cost)
 */

//-----------------------------------------------------------------------------------
#ifdef FRAGMENT_SHADER

uniform vec4 params;

in vec2 PSin_t;

layout(binding = 0) uniform sampler2D TextureSampler;

layout(location = 0) out vec4 SV_Target0;


#define saturate(x) clamp(x, 0.0, 1.0)


vec4 HDRPass(vec2 texcoord, vec2 pixelSize)
{
	float HDRPower = params.x;
    float radius1  = params.y;
    float radius2  = params.z;

	vec3 sColour = texture(TextureSampler, texcoord).rgb;

    vec3 bloomSum1 = vec3(0.0, 0.0, 0.0);
	bloomSum1  = texture(TextureSampler, texcoord + vec2(1.5, -1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(TextureSampler, texcoord + vec2(-1.5, -1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(TextureSampler, texcoord + vec2( 1.5,  1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(TextureSampler, texcoord + vec2(-1.5,  1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(TextureSampler, texcoord + vec2( 0.0, -2.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(TextureSampler, texcoord + vec2( 0.0,  2.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(TextureSampler, texcoord + vec2(-2.5,  0.0) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(TextureSampler, texcoord + vec2( 2.5,  0.0) * radius1 * pixelSize).rgb;

	bloomSum1 *= 0.005;

    vec3 bloomSum2 = vec3(0.0, 0.0, 0.0);
	bloomSum2  = texture(TextureSampler, texcoord + vec2(1.5, -1.5)  * radius2 * pixelSize).rgb;
	bloomSum2 += texture(TextureSampler, texcoord + vec2(-1.5, -1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(TextureSampler, texcoord + vec2( 1.5,  1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(TextureSampler, texcoord + vec2(-1.5,  1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(TextureSampler, texcoord + vec2( 0.0, -2.5) * radius2 * pixelSize).rgb;	
	bloomSum2 += texture(TextureSampler, texcoord + vec2( 0.0,  2.5) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(TextureSampler, texcoord + vec2(-2.5,  0.0) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(TextureSampler, texcoord + vec2( 2.5,  0.0) * radius2 * pixelSize).rgb;

	bloomSum2 *= 0.010;

	float dist = radius2 - radius1;
	vec3 HDR   = (sColour + (bloomSum2 - bloomSum1)) * dist;
	vec3 blend = HDR + sColour;

	sColour = pow(abs(blend), vec3(abs(HDRPower))) + HDR; 
	
	return vec4(saturate(sColour), 1.0);
}


void main()
{
    vec2 pixelSize = vec2(textureSize(TextureSampler, 0));
    vec2 pixelSizeRcp = vec2(1.0 / pixelSize.x, 1.0 / pixelSize.y);

    SV_Target0 = HDRPass(PSin_t, pixelSizeRcp);
}

#endif