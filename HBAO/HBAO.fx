/**
 * Horizon Based Ambient Occlusion
 * by Ethatron, tomerk and Marty McFly
 * 
 * 
 * Ported from ReShade Framework
 * to ReShade 3.0+ by mbah.primbon
 *
 */

//------------------- Non GUI Settings -------------------
#define AO_BLUR_STEPS    11        //Offset count for AO smoothening. Higher means more smooth AO but also blurrier AO.
#define AO_SHARPNESS     0.8       //AO sharpness, higher means more sharp geometry edges but noisier AO, less means smoother AO but blurry in the distance.


//-------------------- GUI Settings ----------------------
uniform bool bHBAODebug <
	ui_label = "HBAO Debug View";
	ui_tooltip = "Enables raw AO/IL output for debugging and tuning purposes.";
> = false;

uniform float fHBAOScale <
	ui_type = "drag";
	ui_min = 0.25; ui_max = 1.00;
    ui_label = "HBAO Scale";
	ui_tooltip = "Scale of AO resolution. Lower resolution means less pixels to process and more performance but also less quality.";
> = 1.00;

uniform float fHBAOFadeStart <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00; ui_step = 0.01;
    ui_label = "HBAO Fade Start";
	ui_tooltip = "Distance from camera where AO starts to fade out. 0.0 means camera itself, 1.0 means infinite distance.";
> = 0.40;

uniform float fHBAOFadeEnd <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00; ui_step = 0.01;
    ui_label = "HBAO Fade End";
	ui_tooltip = "Distance from camera where AO fades out completely. 0.0 means camera itself, 1.0 means infinite distance.";
> = 0.90;

uniform int iHBAOSamples <
	ui_type = "drag";
	ui_min = 2; ui_max = 64;
    ui_label = "HBAO Samples";
	ui_tooltip = "Amount of samples. Higher means more accurate AO but also less performance.";
> = 7;

uniform float fHBAOSamplingRange <
	ui_type = "drag";
	ui_min = 0.50; ui_max = 5.00;
    ui_label = "HBAO Sampling Range";
	ui_tooltip = "Range of HBAO sampling. Higher values ignore small geometry details and shadow more globally.";
> = 1.3;

uniform float fHBAOAmount <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 10.00;
    ui_label = "HBAO Amount";
	ui_tooltip = "Amount of HBAO shadowing.";
> = 2.50;

uniform float fHBAOClamp <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
    ui_label = "HBAO Clamp";
	ui_tooltip = "Clamps HBAO power. 0.0 means full power, 1.0 means no HBAO.";
> = 0.20;

uniform float fHBAOAttenuation <
	ui_type = "drag";
	ui_min = 0.001; ui_max = 0.20;
    ui_label = "HBAO Attenuation";
	ui_tooltip = "Affects the HBAO range, prevents shadowing of very far objects which are close in screen space.";
> = 0.32;

//------------------------------------------------------------------------
#include "ReShade.fxh"

// Textures and samplers
texture texHBAO1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;  Format = RGBA16F;};
texture texHBAO2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;  Format = RGBA16F;};
sampler SamplerHBAO1 {Texture = texHBAO1;};
sampler SamplerHBAO2 {Texture = texHBAO2;};

// Functions
#define InvFocalLen 	float2(tan(0.5f*radians(75.0)) / (float)BUFFER_RCP_HEIGHT * (float)BUFFER_RCP_WIDTH, tan(0.5f*radians(75.0)))
float3 GetEyePosition(in float2 uv, in float eye_z) {
	uv = (uv * float2(2.0, -2.0) - float2(1.0, -1.0));
	float3 pos = float3(uv * InvFocalLen * eye_z, eye_z);
	return pos;
}

float2 GetRandom2_10(in float2 uv) {
	float noiseX = (frac(sin(dot(uv, float2(12.9898,78.233) * 2.0)) * 43758.5453));
	float noiseY = sqrt(1 - noiseX * noiseX);
	return float2(noiseX, noiseY);
}


// Pixel shaders
void PS_AO_HBAO(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 Occlusion1R : SV_Target)		
{
	texcoord.xy /= fHBAOScale;
	if(texcoord.x > 1.0 || texcoord.y > 1.0) discard;

	float depth = ReShade::GetLinearizedDepth(texcoord.xy).x;
	float blurkey = depth;
	if(depth > min(0.9999,fHBAOFadeEnd)) Occlusion1R = float4(1.0,1.0,1.0,blurkey);
	else {
		float2 sample_offset[8] =
		{
			float2(1, 0),
			float2(0.7071f, 0.7071f),
			float2(0, 1),
			float2(-0.7071f, 0.7071f),
			float2(-1, 0),
			float2(-0.7071f, -0.7071f),
			float2(0, -1),
			float2(0.7071f, -0.7071f)
		};

		float3 pos = GetEyePosition(texcoord.xy, depth);
		float3 dx = ddx(pos);
		float3 dy = ddy(pos);
		float3 norm = normalize(cross(dx,dy));
 
		float sample_depth=0;
		float3 sample_pos=0;
 
		float ao=0;
		float s=0.0;
 
		float2 rand_vec = GetRandom2_10(texcoord.xy);
		float2 sample_vec_divisor = InvFocalLen*depth/(fHBAOSamplingRange*float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT));
		float2 sample_center = texcoord.xy;
 
		for (int i = 0; i < 8; i++)
		{
			float theta,temp_theta,temp_ao,curr_ao = 0;
			float3 occlusion_vector = 0.0;
 
			float2 sample_vec = reflect(sample_offset[i], rand_vec);
			sample_vec /= sample_vec_divisor;
			float2 sample_coords = (sample_vec*float2(1,(float)BUFFER_WIDTH/(float)BUFFER_HEIGHT))/iHBAOSamples;
 
			for (int k = 1; k <= iHBAOSamples; k++)
			{
				sample_depth = ReShade::GetLinearizedDepth(sample_center + sample_coords*(k-0.5*(i%2))).x;
				sample_pos = GetEyePosition(sample_center + sample_coords*(k-0.5*(i%2)), sample_depth);
				occlusion_vector = sample_pos - pos;
				temp_theta = dot( norm, normalize(occlusion_vector) );			
 
				if (temp_theta > theta)
				{
					theta = temp_theta;
					temp_ao = 1-sqrt(1 - theta*theta );
					ao += (1/ (1 + fHBAOAttenuation * pow(length(occlusion_vector)/fHBAOSamplingRange*5000,2)) )*(temp_ao-curr_ao);
					curr_ao = temp_ao;
				}
			}
			s += 1;
		}
 
		ao /= max(0.00001,s);
 		ao = 1.0-ao*fHBAOAmount;
		ao = clamp(ao,fHBAOClamp,1);

		Occlusion1R = float4(ao.xxx, blurkey);
	}

}

void PS_AO_AOBlurV(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 Occlusion2R : SV_Target)
{
	//It's better to do this here, upscaling must produce artifacts and upscale-> blur is better than blur -> upscale
	//besides: code is easier an I'm very lazy :P
	texcoord.xy *= fHBAOScale;
	float  sum,totalweight=0;
	float4 base = tex2D(SamplerHBAO1, texcoord.xy), temp=0;
	
	[loop]
	for (int r = -AO_BLUR_STEPS; r <= AO_BLUR_STEPS; ++r) 
	{
		float2 axis = float2(0.0, 1.0);
		temp = tex2D(SamplerHBAO1, texcoord.xy + axis * ReShade::PixelSize * r);
		float weight = AO_BLUR_STEPS-abs(r); 
		weight *= max(0.0, 1.0 - (1000.0 * AO_SHARPNESS) * abs(temp.w - base.w));
		sum += temp.x * weight;
		totalweight += weight;
	}

	Occlusion2R = float4(sum / (totalweight+0.0001),0,0,base.w);
}

void PS_AO_AOBlurH(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 Occlusion1R : SV_Target)
{
	float  sum,totalweight=0;
	float4 base = tex2D(SamplerHBAO2, texcoord.xy), temp=0;
	
	[loop]
	for (int r = -AO_BLUR_STEPS; r <= AO_BLUR_STEPS; ++r) 
	{
		float2 axis = float2(1.0, 0.0);
		temp = tex2D(SamplerHBAO2, texcoord.xy + axis * ReShade::PixelSize * r);
		float weight = AO_BLUR_STEPS-abs(r); 
		weight *= max(0.0, 1.0 - (1000.0 * AO_SHARPNESS) * abs(temp.w - base.w));
		sum += temp.x * weight;
		totalweight += weight;
	}

	Occlusion1R = float4(sum / (totalweight+0.0001),0,0,base.w);
}

float4 PS_AO_AOCombine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	float ao = tex2D(SamplerHBAO1, texcoord.xy).x;

	if(bHBAODebug)
	{	 
		float depth = ReShade::GetLinearizedDepth(texcoord.xy).x;
		ao = lerp(ao,1.0,smoothstep(fHBAOFadeStart,fHBAOFadeEnd,depth));
		return ao;
	}
	else
	{
		float depth = ReShade::GetLinearizedDepth(texcoord.xy).x;
		ao = lerp(ao,1.0,smoothstep(fHBAOFadeStart,fHBAOFadeEnd,depth));

		color.xyz *= ao;
		return color;
	}
}

// Rendering passes
technique HBAO
{
	pass HBAmbientOcclusion
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_AO_HBAO;
		RenderTarget = texHBAO1;
	}
	
	pass BlurV
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_AO_AOBlurV;
		RenderTarget = texHBAO2;
	}
	
	pass BlurH
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_AO_AOBlurH;
		RenderTarget = texHBAO1;
	}
	
	pass Combine
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_AO_AOCombine;
	}
	
}