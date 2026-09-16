//#version 420 // Keep it for editor detection
/**
 * HDR
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Not actual HDR - It just tries to mimic an HDR look (relatively high performance cost)
 */

//-----------------------------------------------------------------------------------
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
	vec4 params;
};

layout(set = 0, binding = 0) uniform sampler2D samp0;
layout(location = 0) in vec2 v_tex;
layout(location = 0) out vec4 o_col0;


#define saturate(x) clamp(x, 0.0, 1.0)

vec4 HDRPass(vec2 texcoord, vec2 pixelSize)
{
	float HDRPower = params.x;
    float radius1  = params.y;
    float radius2  = params.z;

	vec3 sColour = texture(samp0, texcoord).rgb;

    vec3 bloomSum1 = vec3(0.0, 0.0, 0.0);
	bloomSum1  = texture(samp0, texcoord + vec2(1.5, -1.5)  * radius1 * pixelSize).rgb;
	bloomSum1 += texture(samp0, texcoord + vec2(-1.5, -1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(samp0, texcoord + vec2( 1.5,  1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(samp0, texcoord + vec2(-1.5,  1.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(samp0, texcoord + vec2( 0.0, -2.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(samp0, texcoord + vec2( 0.0,  2.5) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(samp0, texcoord + vec2(-2.5,  0.0) * radius1 * pixelSize).rgb;
	bloomSum1 += texture(samp0, texcoord + vec2( 2.5,  0.0) * radius1 * pixelSize).rgb;

	bloomSum1 *= 0.005;

    vec3 bloomSum2 = vec3(0.0, 0.0, 0.0);
	bloomSum2  = texture(samp0, texcoord + vec2(1.5, -1.5)  * radius2 * pixelSize).rgb;
	bloomSum2 += texture(samp0, texcoord + vec2(-1.5, -1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(samp0, texcoord + vec2( 1.5,  1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(samp0, texcoord + vec2(-1.5,  1.5) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(samp0, texcoord + vec2( 0.0, -2.5) * radius2 * pixelSize).rgb;	
	bloomSum2 += texture(samp0, texcoord + vec2( 0.0,  2.5) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(samp0, texcoord + vec2(-2.5,  0.0) * radius2 * pixelSize).rgb;
	bloomSum2 += texture(samp0, texcoord + vec2( 2.5,  0.0) * radius2 * pixelSize).rgb;

	bloomSum2 *= 0.010;

	float dist = radius2 - radius1;
	vec3 HDR   = (sColour + (bloomSum2 - bloomSum1)) * dist;
	vec3 blend = HDR + sColour;

	// pow requires both arguments to have the same vector type when operating on vectors.
	// Convert the scalar HDRPower to a vec3 so the overload matches.
	sColour = pow(abs(blend), vec3(abs(HDRPower))) + HDR; 
	
	return vec4(saturate(sColour), 1.0);
}


void main()
{
    vec2 pixelSize = vec2(textureSize(samp0, 0));
    vec2 pixelSizeRcp = vec2(1.0 / pixelSize.x, 1.0 / pixelSize.y);

    o_col0 = HDRPass(v_tex, pixelSizeRcp);
}

#endif