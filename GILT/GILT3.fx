/*
 *  Global illumination shader for Nvidia Ansel, written by Extravi.
 *  https://extravi.dev/
*/

#include "ReShade.fxh"

#define FAR_PLANE RESHADE_DEPTH_LINEARIZATION_FAR_PLANE

uniform int BLEND_MODE <
	ui_type = "combo";
	ui_items = "Soft Light\0Hard Light\0";
	ui_label = "Light Blend Mode";
> = 0;

uniform float NEAR_PLANE <
	ui_type = "slider";
	ui_min = 1.1;
	ui_max = 1000.0;
	ui_label = "Near Plane";
> = 1000.0;

uniform float total_strength <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Intensity";
> = 1.0;

uniform int samples <
    ui_type = "slider";
    ui_min = 1;
    ui_max = 16;
    ui_label = "Samples";
> = 8;

uniform float RAY_INC <
    ui_type = "slider";
    ui_min = 1;
    ui_max = 8;
    ui_label = "Ray Increment";
> = 1.0;

// aka ray steps
uniform float RAY_LEN <
    ui_type = "slider";
    ui_min = 1;
    ui_max = 32;
    ui_label = "Ray Length";
> = 16;

uniform float DEPTH_FADE < 
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Depth Fade";
> = 0.08;

uniform bool DEBUG <
    ui_type = "bool";
    ui_label = "Debug";
> = false;

// used for the light map
uniform float2 SAT_EXP <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 20.0;
    ui_label = "Saturation\n& Exposure";
> = float2(2.6, 2.0);

//////////////////////////////////////
// Textures and samplers
//////////////////////////////////////

// Light Map texture
texture LightMapTex {
    Width = BUFFER_WIDTH / 1;
    Height = BUFFER_HEIGHT / 1;
    MipLevels = 3;
};
// Buffer texture
texture BufferTex {
    Width = BUFFER_WIDTH / 1;
    Height = BUFFER_HEIGHT / 1;
    Format = R16F;
    MipLevels = 3;
};
// Normal texture
texture NormalTex {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    MipLevels = 1;
};
// Output texture
texture OutputTex {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
    MipLevels = 2;
};

// Light Map sampler
sampler LightMapSampler {
    Texture = LightMapTex;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;
};
// Buffer sampler
sampler BufferSampler {
    Texture = BufferTex;
};
// Normal sampler
sampler NormalSampler {
    Texture = NormalTex;
};
// Output sampler
sampler OutputSampler {
    Texture = OutputTex;
};

//////////////////////////////////////
// Functions
//////////////////////////////////////

// function for SAT_EXP uniform
float3 AdjustColor(float3 color, float2 SAT_EXP)
{
    float saturation = SAT_EXP.x;
    float exposure = SAT_EXP.y;

    // apply exposure
    color *= pow(2.0, exposure);

    // convert to grayscale
    float gray = dot(color, float3(0.299, 0.587, 0.114));

    // adjust saturation
    return lerp(float3(gray, gray, gray), color, saturation);
}

// function to get the buffer color
float3 GetBackBufferColor(float2 texcoord)
{
    return tex2D(ReShade::BackBuffer, texcoord).rgb;
}

float3 PS_LightMapAdjust(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float3 bufferColor = GetBackBufferColor(texcoord);
    return AdjustColor(bufferColor, SAT_EXP);
}

// function to get the depths buffer
float GetDepth(float2 texcoord)
{
    return ReShade::GetLinearizedDepth(texcoord);
}

float3 PS_DisplayDepth(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // defines far plane distance and near plane distance
    float f = FAR_PLANE;
    float n = NEAR_PLANE;

    // get the depth value at the texture coordinate
    float depth = GetDepth(texcoord);

    // linearize depth
    depth = lerp(n, f, depth);
    
    // normalize depth
    return depth / (f - n);
}

float3 PS_NormalBuffer(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // get the depth value at the texture coordinate
    float depth = GetDepth(texcoord);
    // buffer dimensions vector dims
    float2 dims = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    // horizontal differences
    float2 texOffset = float2(1, 0) / dims;
    float depthsX = depth - ReShade::GetLinearizedDepth(texcoord - texOffset);
    depthsX += (depth - ReShade::GetLinearizedDepth(texcoord + texOffset)) - depthsX;

    // vertical  differences
    texOffset = float2(0, 1) / dims;
    float depthsY = depth - ReShade::GetLinearizedDepth(texcoord - texOffset);
    depthsY += (depth - ReShade::GetLinearizedDepth(texcoord + texOffset)) - depthsY;

    // normalized normal
    return 0.5 + 0.5 * normalize(float3(depthsX, depthsY, depth / FAR_PLANE));
}

float3 RandomDirection(float2 seed) {
    float z = seed.x * 2.0 - 1.0;
    float r = sqrt(1.0 - z * z);
    float phi = 2.0 * 3.14159265359 * seed.y;
    return float3(r * cos(phi), r * sin(phi), z);
}

float3 eyePos(float2 xy, float z)
{
	z = -z;
    float3 eyp = float3(xy, 1 ) * z ;
    return eyp;
}

float4 PS_ComputeGI(float4 position : SV_Position, float2 coord : TEXCOORD0) : SV_Target
{
    float2 dims = 1 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    // generate noise
    float3 Noise = frac(sin(dot(coord.xy , float2(12.9898,78.233))) * 43758.5453);

    // get depth and normal
    float depth = GetDepth(coord);
    float3 normal = normalize(PS_NormalBuffer(position, coord));

    // eye position
    float3 eye_position = eyePos(coord, depth);
    float3 ray_dir = normalize(eye_position);
    
    // ray increment
    float RayInc = RAY_INC * dims.x;
 
    float3 accumulatedColor = float3(0, 0, 0);
    float totalWeight = 0.0;

    for (int i = 0; i < samples; i++)
    {
        float2 randomSeed = frac(sin(float2(i, dot(coord.xy, Noise.xy))) * float2(43758.5453, 1964.1377));
        float3 sampleRay = reflect(RandomDirection(randomSeed), normal);
        float3 rayPos = eye_position;

        for(int j = 0; j < RAY_LEN; j++)
        {
            rayPos += sampleRay * RayInc;
            float2 sampleCoord = (rayPos.xy / rayPos.z);
            float sampleDepth = tex2D(BufferSampler, sampleCoord ).x;
            float3 sampleColor = tex2D(LightMapSampler, sampleCoord ).rgb;
            float difference = abs(depth - sampleDepth);
            accumulatedColor += sampleColor * step(lerp(0.000001f,0.1f,total_strength),difference);
            totalWeight++;
        }
    }

    // average out the accumulated color
    float3 DebugColor = accumulatedColor / totalWeight;

    // fix depths
    DebugColor = lerp(DebugColor, float3(0.5, 0.5, 0.5), depth);
    
    // Apply depth fade
    float fadeFactor = smoothstep(0.0, DEPTH_FADE, depth);
    DebugColor *= fadeFactor;
    
    return float4(DebugColor, 1.0);
}

// blend backBufferColor and OutputSampler
float3 SoftLightBlend(float3 base, float3 blend)
{
    float3 result;
    for (int i = 0; i < 3; i++)
    {
        if (blend[i] < 0.5)
        {
            result[i] = base[i] - (1.0 - 2.0 * blend[i]) * base[i] * (1.0 - base[i]);
        }
        else
        {
            result[i] = base[i] + (2.0 * blend[i] - 1.0) * (sqrt(base[i]) - base[i]);
        }
    }
    return result;
}

// blend backBufferColor and OutputSampler
float3 HardLightBlend(float3 base, float3 blend)
{
    float3 result;
    for (int i = 0; i < 3; i++)
    {
        if (blend[i] < 0.5)
        {
            result[i] = 2.0 * base[i] * blend[i] + base[i] * base[i] * (1.0 - 2.0 * blend[i]);
        }
        else
        {
            result[i] = 2.0 * base[i] * (1.0 - blend[i]) + sqrt(base[i]) * (2.0 * blend[i] - 1.0);
        }
    }
    return result;
}

// used to denoise
float3 GaussianBlur(sampler2D texSampler, float2 uv, float2 texSize)
{
    float3 blur = float3(0.0, 0.0, 0.0);

    const int radius = 5;
    const float sigma = 3.0;

    float2 texelSize = 1.0 / texSize;

    float kernel[11];
    float sum = 0.0;
    
    for (int i = -radius; i <= radius; ++i)
    {
        kernel[i + radius] = exp(-0.5 * (i * i) / (sigma * sigma));
        sum += kernel[i + radius];
    }

    for (int i = 0; i < 11; ++i)
    {
        kernel[i] /= sum;
    }

    for (int x = -radius; x <= radius; ++x)
    {
        for (int y = -radius; y <= radius; ++y)
        {
            float2 offset = float2(x, y) * texelSize;
            float weight = kernel[x + radius] * kernel[y + radius];
            blur += tex2D(texSampler, uv + offset).rgb * weight;
        }
    }

    return blur;
}

float4 Output(float4 position : SV_Position, float2 coord : TEXCOORD0) : SV_Target
{
    // sample the colors
    float3 backBufferColor = tex2D(ReShade::BackBuffer, coord).rgb;
    float3 finalColor = tex2D(OutputSampler, coord).rgb;

    // apply Gaussian blur
    float2 texSize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float3 blurredColor = GaussianBlur(OutputSampler, coord, texSize);

    // choose blend mode
    float3 blendedColor;
    if (BLEND_MODE == 0) // soft Light
    {
        blendedColor = SoftLightBlend(backBufferColor, blurredColor);
    }
    else // hard Light
    {
        blendedColor = HardLightBlend(backBufferColor, blurredColor);
    }

    if (DEBUG == true)
    {
        return float4(blurredColor, 1.0);
    }
    else
    {
        return float4(blendedColor, 1.0);
    }
}

// Global Illumination Lighting Technique
technique GILT
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LightMapAdjust;
        RenderTarget = LightMapTex;
    }
    pass
	{
        VertexShader = PostProcessVS;
        PixelShader = PS_DisplayDepth;
        RenderTarget = BufferTex;
	}
    pass
	{
        VertexShader = PostProcessVS;
        PixelShader = PS_NormalBuffer;
        RenderTarget = NormalTex;
	}
    pass
	{
        VertexShader = PostProcessVS;
        PixelShader = PS_ComputeGI;
        RenderTarget = OutputTex;
	}
    pass
	{
        VertexShader = PostProcessVS;
        PixelShader = Output;
	}
}