
//Diffuse Glow by Ioxa for ReShade 3.0
//Version 1.1

//Settings
#if !defined DiffuseSinglePass
	#define DiffuseSinglePass 1
#endif

uniform int BlurRadius <
	ui_type = "drag";
	ui_min = 0; ui_max = 4;
	ui_tooltip = "[0|1|2|3|4] Adjusts the blur radius. Higher values increase the radius. Add DiffuseSinglePass=0 to Preprocessor Definitions for a stronger blur";
> = 1;

uniform int BlendMode
<
	ui_type = "combo";
	ui_items = "Linear\0Screen\0WarmScreen\0";
	ui_tooltip = "Determines how the glow effect is applied to the original image.";
> = 0;

uniform int ThresholdMaskType <
	ui_type = "combo";
	ui_items = "\Max\0Average\0Min\0AvgMaxMin\0";
	ui_tooltip = "Determines what pixels are considered bright. Using the ThresholdMask option in DebugMode is helpful when selecting a mask type";
> = 3;

uniform float Threshold <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Everything above this value will be considered bright light and have the full strength of the effect applied to it.";
> = 0.800;

uniform float ThresholdRange <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the cutoff for the threshold.";
> = 0.800;

uniform float GlowPower <
	ui_type = "drag";
	ui_min = 1.0; ui_max = 10.0;
	ui_tooltip = "Adjusts the power of the glow.";
> = 2.0;

uniform float Slope <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 2.00;
	ui_tooltip = "";
> = 1.3;

uniform float SlopeMidPoint <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.0;
	ui_tooltip = "";
> = 0.0;

uniform float GlowSaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 4.0;
	ui_tooltip = "Adjusts the glow saturation.";
> = 1.0;

uniform float GrainStrength <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "Adds grain to the effect.";
> = 0.300;

uniform float Strength <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the strength of the effect.";
> = 0.300;

uniform int DebugMode
<
	ui_type = "combo";
	ui_items = "\None\0ThresholdMask\0Blur\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;

uniform float timer < source = "timer";>;

#include "ReShade.fxh"

#if DiffuseSinglePass == 0
texture DiffuseTex { Width = BUFFER_WIDTH*0.5; Height = BUFFER_HEIGHT*0.5; Format = RGBA8; };
sampler DiffuseSampler { Texture = DiffuseTex; MinFilter = POINT;};
#endif

float3 slope(float3 x, float c, float p)
{
	p = clamp(p,0.001,1.0);
	return (c*pow(p,c-1.0))/pow(p,c-1.0)*(x-p)+p;
}

float3 DiffuseFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

#if DiffuseSinglePass 
	#define FinalDiffuseSampler ReShade::BackBuffer
#else
	#define FinalDiffuseSampler DiffuseSampler 
#endif 

#if DiffuseSinglePass 

	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 blur = orig;
	
	if (BlurRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		blur *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * sampleWeights[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * sampleWeights[i];
		}
	}
	
	if (BlurRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		blur *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * sampleWeights[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * sampleWeights[i];
		}
	}

	if (BlurRadius == 3)
	{
		float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		blur *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * sampleWeights[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * sampleWeights[i];
		}
	}
	
	if (BlurRadius == 4)
	{
		float sampleOffsetsX[25] = { 				  0.0, 			       1.4584295168, 			 		   0, 	 		  1.4584295168,     	   	 1.4584295168,     		    3.4039848067,     		  			  0,     		 3.4039848067,     		   3.4039848067,     		 1.4584295168,    		   1.4584295168,     		  3.4039848067,     		  3.4039848067,		5.3518057801,			 0.0,	5.3518057801,	5.3518057801,   5.3518057801,	5.3518057801,	   1.4584295168,	    1.4584295168,	3.4039848067,	3.4039848067, 5.3518057801, 5.3518057801};
		float sampleOffsetsY[25] = {  				  0.0,   					   0, 	  		   1.4584295168, 	 		  1.4584295168,     		-1.4584295168,     					   0,     		   3.4039848067,     		    1.4584295168,    		     -1.4584295168,     	  3.4039848067,   	   -3.4039848067,     		  3.4039848067,    		     -3.4039848067, 		     0.0,	5.3518057801,	   1.4584295168,	  -1.4584295168,	3.4039848067,  -3.4039848067,	5.3518057801,	-5.3518057801,	5.3518057801,  -5.3518057801, 5.3518057801, -5.3518057801};
		float sampleWeights[25] = {                           0.05299184990795840687999609498603,              0.09256069846035847440860469965371,           0.09256069846035847440860469965371,           0.02149960564023589832299078385165,           0.02149960564023589832299078385165,                 0.05392678246987847562647201766774,              0.05392678246987847562647201766774,             0.01252588384627371007425549277902,             0.01252588384627371007425549277902,          0.01252588384627371007425549277902,         0.01252588384627371007425549277902,             0.00729770438775005041467389567467,               0.00729770438775005041467389567467, 	0.02038530184304811960185734706054,	0.02038530184304811960185734706054,	0.00473501127359426108157733854484,	0.00473501127359426108157733854484,	0.00275866461027743062478492361799,	0.00275866461027743062478492361799,	0.00473501127359426108157733854484,	 0.00473501127359426108157733854484,	0.00275866461027743062478492361799,	0.00275866461027743062478492361799, 0.00104282525148620420024312363461, 0.00104282525148620420024312363461};
		
		blur *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * sampleWeights[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * sampleWeights[i];
		}
		blur *= 1.2;
	}
#else
	float3 blur = tex2Dlod(FinalDiffuseSampler, float4(texcoord, 0.0, 10.0)).rgb;
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;

	if(BlurRadius == 0)	
	{
		float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
		float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
		blur *= weight[0];
	
		[loop]
		for(int i = 1; i < 4; ++i)
		{
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
		}
	}	

	if(BlurRadius == 1)	
	{
		float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
		float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
		blur *= weight[0];
	
		[loop]
		for(int i = 1; i < 6; ++i)
		{
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
		}
	}	

	if(BlurRadius == 2)	
	{
		float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
		float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
		blur *= weight[0];
	
		[loop]
		for(int i = 1; i < 11; ++i)
		{
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
		}
	}	

	if(BlurRadius == 3)	
	{
		float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
		float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
		blur *= weight[0];
	
		[loop]
		for(int i = 1; i < 15; ++i)
		{
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
		}
	}

	if(BlurRadius == 4)	
	{
		float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
		float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
		blur *= weight[0];
	
		[loop]
		for(int i = 1; i < 18; ++i)
		{
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
			blur += tex2Dlod(FinalDiffuseSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y), 0.0, 10.0)).rgb * weight[i];
		}
	}		
#endif 

	float3 color = blur;
	
	
	float luma = dot(color,0.333);
	color /= luma;
	
	luma = pow(luma,1/GlowPower);
	
	color *= luma;
	
	color = lerp(luma,color,GlowSaturation);
	
	color = slope(color,Slope,SlopeMidPoint);
	
	float thresholdMask = 1.0;
	
	if(Threshold != 1.000 && ThresholdRange != 0.000)
	{
	if(ThresholdMaskType == 0)
	{
		thresholdMask = max(blur.r,max(blur.g,blur.b));
	}
	
	if(ThresholdMaskType == 1)
	{
		thresholdMask = dot(blur,0.333333);
	}
	
	if(ThresholdMaskType == 2)
	{
		thresholdMask = min(blur.r,min(blur.g,blur.b));
	}
	
	if(ThresholdMaskType == 3)
	{
		thresholdMask = (min(blur.r,min(blur.g,blur.b)));
		thresholdMask += max(blur.r,max(blur.g,blur.b));
		thresholdMask *= 0.5;
	}
	
	thresholdMask = lerp(0.0,1.0,smoothstep(Threshold-(Threshold*ThresholdRange),Threshold,thresholdMask));

	}
	
		if(BlendMode == 1)
	{
		//Screen
		color = 1.0 - ((1.0-orig)*(1.0-color));
	}
	
	if(BlendMode == 2)
	{
		//WarmScreen
		color = (1.0 - (2*(1.0 - orig) * (1.0 - (color))));
	}
	
	color = lerp(orig,color,thresholdMask);
	
	orig = lerp(orig, color, Strength);
	
	float noise = 0.0;
	
	if(GrainStrength)
	{
	float t = (timer * 0.0005) ;
	float sine = sin(dot(texcoord, float2(12.9898,78.233)));
	noise = frac(sine * 43758.5453 + texcoord.x + t) * 0.048 - 0.024;
	}
	
	orig.rgb -= (noise*thresholdMask*GrainStrength);
	
	if(DebugMode == 1)
	{
		orig = thresholdMask;
	}
	
	if(DebugMode == 2)
	{
		orig = blur;
	}
	
	return saturate(orig);
}

#if DiffuseSinglePass == 0
float3 Diffuse1(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

float3 color = tex2Dlod(ReShade::BackBuffer, float4(texcoord, 0.0, 10.0)).rgb;

if(BlurRadius == 0)	
{
	float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0), 0.0, 10.0)).rgb * weight[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0), 0.0, 10.0)).rgb * weight[i];
	}
}	

if(BlurRadius == 1)	
{
	float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0), 0.0, 10.0)).rgb * weight[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0), 0.0, 10.0)).rgb * weight[i];
	}
}	

if(BlurRadius == 2)	
{
	float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0), 0.0, 10.0)).rgb * weight[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0), 0.0, 10.0)).rgb * weight[i];
	}
}	

if(BlurRadius == 3)	
{
	float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0)).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0)).rgb * weight[i];
	}
}	

if(BlurRadius == 4)	
{
	float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0)).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0)).rgb * weight[i];
	}
}	
	return saturate(color);
}
#endif 

technique DiffuseGlow
{

#if DiffuseSinglePass == 0
	pass Blur1
	{
		VertexShader = PostProcessVS;
		PixelShader = Diffuse1;
		RenderTarget = DiffuseTex;
	}
#endif
	
	pass BlurFinal
	{
		VertexShader = PostProcessVS;
		PixelShader = DiffuseFinal;
	}
}
