/*
   Deblur Upscaling shader
   
   Copyright (C) 2006 - 2019 guest(r) - guest.r@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#include "ReShadeUI.fxh"
#include "ReShade.fxh" 

static const float3  dt = float3(1.0,1.0,1.0);

uniform float OFFSET < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 2.0;
	ui_label = "Filter Width";
	ui_tooltip = "Filter Width";
> = 1.0; 
 
uniform float DBL < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 9.0;
	ui_label = "Deblur Strength";
	ui_tooltip = "Deblur Strength";
> = 6.0; 

uniform float SMART < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Smart Deblur";
	ui_tooltip = "Smart Deblur intensity";
> = 0.7; 

uniform float SHARPEN < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.7;
	ui_label = "Sharpen";
	ui_tooltip = "Sharpen intensity";
> = 0.20; 

texture TextureDAA { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler TextureDAAS { Texture = TextureDAA; };
 
float3 DEB(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	// Calculating texel coordinates
	float2 inv_size = OFFSET * ReShade::PixelSize;	
	float2 size     = 1.0/inv_size;

	float2 dx = float2(inv_size.x,0.0);
	float2 dy = float2(0.0, inv_size.y);
	float2 g1 = float2(inv_size.x,inv_size.y);
	float2 g2 = float2(-inv_size.x,inv_size.y);
	
	float2 pC4 = uv;	
	
	// Reading the texels
	float3 c00 = tex2D(ReShade::BackBuffer,pC4 - g1).rgb; 
	float3 c10 = tex2D(ReShade::BackBuffer,pC4 - dy).rgb;
	float3 c20 = tex2D(ReShade::BackBuffer,pC4 - g2).rgb;
	float3 c01 = tex2D(ReShade::BackBuffer,pC4 - dx).rgb;
	float3 c11 = tex2D(ReShade::BackBuffer,pC4     ).rgb;
	float3 c21 = tex2D(ReShade::BackBuffer,pC4 + dx).rgb;
	float3 c02 = tex2D(ReShade::BackBuffer,pC4 + g2).rgb;
	float3 c12 = tex2D(ReShade::BackBuffer,pC4 + dy).rgb;
	float3 c22 = tex2D(ReShade::BackBuffer,pC4 + g1).rgb;

	float3 d11 = c11;
	
	float3 mn1 = min (min (c00,c01),c02);
	float3 mn2 = min (min (c10,c11),c12);
	float3 mn3 = min (min (c20,c21),c22);
	float3 mx1 = max (max (c00,c01),c02);
	float3 mx2 = max (max (c10,c11),c12);
	float3 mx3 = max (max (c20,c21),c22);
   
	mn1 = min(min(mn1,mn2),mn3);
	mx1 = max(max(mx1,mx2),mx3);
	float3 contrast = mx1-mn1;
	float m = max(max(contrast.r,contrast.g),contrast.b);
	
	float DB1 = DBL; float dif;

	float3 dif1 = abs(c11-mn1) + 0.0001; float3 df1 = pow(dif1,float3(DB1,DB1,DB1));
	float3 dif2 = abs(c11-mx1) + 0.0001; float3 df2 = pow(dif2,float3(DB1,DB1,DB1)); 

	dif1 *= dif1*dif1;
	dif2 *= dif2*dif2;
	
	float3 df = df1/(df1 + df2);
	float3 ratio = abs(dif1-dif2)/(dif1+dif2);
	d11 = lerp(c11, lerp(mn1,mx1,df), ratio);
	
	c11 = lerp(c11, d11, saturate(2.0*m-0.15));
	
	d11 = lerp(d11,c11,SMART);
	
	return d11;  
}

// Sharpen table, can be edited

static const float SW[12] = { 0.40, 0.45, 0.5, 0.55, 0.50, 0.40, 0.30, 0.23, 0.15, 0.08, 0.05, 0.05 };

float3 GetWeight(float3 color)
{
	color = color*10.0;
	int i1 = int(color.r);
	int i2 = int(color.g);
	int i3 = int(color.b);
	return lerp(float3(SW[i1], SW[i2], SW[i3]), float3(SW[i1+1], SW[i2+1], SW[i3+1]), frac(color));
}


float3 DEB1 (float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	float3 c10 = tex2Doffset(TextureDAAS, uv, int2( 0,-1)).rgb;
	float3 c01 = tex2Doffset(TextureDAAS, uv, int2(-1, 0)).rgb;
	float3 c11 = tex2Doffset(TextureDAAS, uv, int2( 0, 0)).rgb;
	float3 c21 = tex2Doffset(TextureDAAS, uv, int2( 1, 0)).rgb;
	float3 c12 = tex2Doffset(TextureDAAS, uv, int2( 0, 1)).rgb;

	float3 w10 = GetWeight(abs(c11-c10));
	float3 w01 = GetWeight(abs(c11-c01));
	float3 w21 = GetWeight(abs(c11-c21));
	float3 w12 = GetWeight(abs(c11-c12));
	
	float3 s11 = (3.5*c11 - w10*c10 - w01*c01 - w21*c21 - w12*c12)/(3.5 - w10 - w01 - w21 - w12);
	
	return saturate(lerp(c11,s11,SHARPEN));
} 

technique DeblurUpscaler
{
	pass deblur1
	{
		VertexShader = PostProcessVS;
		PixelShader = DEB;
		RenderTarget = TextureDAA;		
	}
	pass deblur2
	{
		VertexShader = PostProcessVS;
		PixelShader = DEB1;
	}	
}