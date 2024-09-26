////////////////////////////////////////////////////////////////////////////////
//
// 5xBr_NoBlend filter from (DirectX 9+ & OpenGL)
//
//    https://github.com/libretro/common-shaders/blob/master/xbr/shaders/legacy/5xbr-v4.0-noblend.cg
//
// Ported by spiderh @2018
//
// NOTE:  Only work with pixelated games.
//
////////////////////////////////////////////////////////////////////////////////
/*
   Hyllian's 5xBR v4.0 (LEVEL 3) No Blending - Shader
   
   Copyright (C) 2011/2013 Hyllian/Jararaca - sergiogdb@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
////////////////////////////////////////////////////////////////////////////////


uniform float coef <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 10.0;
	ui_label = "Strength";
	ui_tooltip = "Strength of the effect (1.5)";
> = 1.5;


#include "ReShade.fxh"


const static float y_weight = 48.0;
const static float u_weight = 7.0;
const static float v_weight = 6.0;

const static float4 eq_threshold = float4( 10.0, 10.0, 10.0, 10.0 );

const static float4x4 yuv_weighted = float4x4( y_weight * float4( 0.299,  0.587,  0.114,  0),
                                               u_weight * float4(-0.169, -0.331,  0.499,  0),
                                               v_weight * float4( 0.499, -0.418, -0.0813, 0),
                                               float4(0,0,0,0) );


float4 df( float4 A, float4 B )
{
  return float4( abs(A - B) );
}


float c_df( float4 c1, float4 c2 )
{
  float4 df = abs(c1 - c2);
  return df.r + df.g + df.b;
}


bool4 eq( float4 A, float4 B )
{
  return ( df(A, B) < eq_threshold );
}

bool4 eq2( float4 A, float4 B )
{
  return ( df(A, B) < float4(2.0, 2.0, 2.0, 2.0) );
}


float4 weighted_distance( float4 a, float4 b, float4 c, float4 d, float4 e, float4 f, float4 g, float4 h )
{
  return ( df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0*df(g,h) );
}


// --------------------
// --  MAIN  ----------
// --------------------

// Vertex shader generating a triangle covering the entire screen
void VS_XBR5X_NOBLEND( in  uint   id       : SV_VertexID,
                       out float4 position : SV_Position,
                       out float2 texcoord : TEXCOORD0,
                       out float4 t1       : TEXCOORD1,
                       out float4 t2       : TEXCOORD2,
                       out float4 t3       : TEXCOORD3,
                       out float4 t4       : TEXCOORD4,
                       out float4 t5       : TEXCOORD5,
                       out float4 t6       : TEXCOORD6,
                       out float4 t7       : TEXCOORD7
              )
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
  
  float width  = BUFFER_WIDTH  / coef;
  float height = BUFFER_HEIGHT / coef;
  
	float dx = ( 1.0 / width  );
	float dy = ( 1.0 / height );
  
	//  A1 B1 C1
	//  A0 A  B  C C4
	//  D0 D  E  F F4
	//  G0 G  H  I I4
	//  G5 H5 I5

  t1 = texcoord.xxxy + float4(     -dx,   0, dx, -2.0*dy ); // A1 B1 C1
  t2 = texcoord.xxxy + float4(     -dx,   0, dx,     -dy ); // A B C
  t3 = texcoord.xxxy + float4(     -dx,   0, dx,       0 ); // D E F
  t4 = texcoord.xxxy + float4(     -dx,   0, dx,      dy ); // G H I
  t5 = texcoord.xxxy + float4(     -dx,   0, dx,  2.0*dy ); // G5 H5 I5
  t6 = texcoord.xyyy + float4( -2.0*dx, -dy,  0,      dy ); // A0 D0 G0
  t7 = texcoord.xyyy + float4(  2.0*dx, -dy,  0,      dy ); // C4 F4 I4
}


float3 PS_XBR5X_NOBLEND( float4 pos : SV_Position,
                         float2 uv  : TexCoord0,
                         float4 t1  : TexCoord1,
                         float4 t2  : TexCoord2,
                         float4 t3  : TexCoord3,
                         float4 t4  : TexCoord4,
                         float4 t5  : TexCoord5,
                         float4 t6  : TexCoord6,
                         float4 t7  : TexCoord7
                       ) : COLOR
{
  bool4 edr, edr_left, edr_up, edr3_left, edr3_up, px; // px = pixel, edr = edge detection rule
  bool4 interp_restriction_lv1, interp_restriction_lv2_left, interp_restriction_lv2_up;
  bool4 interp_restriction_lv3_left, interp_restriction_lv3_up;
  bool4 nc; // new_color
  bool4 fx, fx_left, fx_up, fx3_left, fx3_up; // inequations of straight lines.
  
  float width  = BUFFER_WIDTH  / coef;
  float height = BUFFER_HEIGHT / coef;
   
  float2 fp = frac( uv * float2(width, height) );
  
  float4 A1 = tex2D(ReShade::BackBuffer, t1.xw).rgba;
  float4 B1 = tex2D(ReShade::BackBuffer, t1.yw).rgba;
  float4 C1 = tex2D(ReShade::BackBuffer, t1.zw).rgba;

  float4  A = tex2D(ReShade::BackBuffer, t2.xw).rgba;
  float4  B = tex2D(ReShade::BackBuffer, t2.yw).rgba;
  float4  C = tex2D(ReShade::BackBuffer, t2.zw).rgba;

  float4  D = tex2D(ReShade::BackBuffer, t3.xw).rgba;
  float4  E = tex2D(ReShade::BackBuffer, t3.yw).rgba;
  float4  F = tex2D(ReShade::BackBuffer, t3.zw).rgba;

  float4  G = tex2D(ReShade::BackBuffer, t4.xw).rgba;
  float4  H = tex2D(ReShade::BackBuffer, t4.yw).rgba;
  float4  I = tex2D(ReShade::BackBuffer, t4.zw).rgba;

  float4 G5 = tex2D(ReShade::BackBuffer, t5.xw).rgba;
  float4 H5 = tex2D(ReShade::BackBuffer, t5.yw).rgba;
  float4 I5 = tex2D(ReShade::BackBuffer, t5.zw).rgba;

  float4 A0 = tex2D(ReShade::BackBuffer, t6.xy).rgba;
  float4 D0 = tex2D(ReShade::BackBuffer, t6.xz).rgba;
  float4 G0 = tex2D(ReShade::BackBuffer, t6.xw).rgba;

  float4 C4 = tex2D(ReShade::BackBuffer, t7.xy).rgba;
  float4 F4 = tex2D(ReShade::BackBuffer, t7.xz).rgba;
  float4 I4 = tex2D(ReShade::BackBuffer, t7.xw).rgba;

  float4 b = mul( float4x4(B, D, H, F), yuv_weighted[0] );
  float4 c = mul( float4x4(C, A, G, I), yuv_weighted[0] );
  float4 e = mul( float4x4(E, E, E, E), yuv_weighted[0] );
  float4 d = b.yzwx;
  float4 f = b.wxyz;
  float4 g = c.zwxy;
  float4 h = b.zwxy;
  float4 i = c.wxyz;

  float4 i4 = mul( float4x4(I4, C1, A0, G5), yuv_weighted[0] );
  float4 i5 = mul( float4x4(I5, C4, A1, G0), yuv_weighted[0] );
  float4 h5 = mul( float4x4(H5, F4, B1, D0), yuv_weighted[0] );
  float4 f4 = h5.yzwx;

  float4 c1 = i4.yzwx;
  float4 g0 = i5.wxyz;
  float4 b1 = h5.zwxy;
  float4 d0 = h5.wxyz;


  float4 Ao = float4( 1.0, -1.0, -1.0,  1.0 );
  float4 Bo = float4( 1.0,  1.0, -1.0, -1.0 );
  float4 Co = float4( 1.5,  0.5, -0.5,  0.5 );
  float4 Ax = float4( 1.0, -1.0, -1.0,  1.0 );
  float4 Bx = float4( 0.5,  2.0, -0.5, -2.0 );
  float4 Cx = float4( 1.0,  1.0, -0.5,  0.0 );
  float4 Ay = float4( 1.0, -1.0, -1.0,  1.0 );
  float4 By = float4( 2.0,  0.5, -2.0, -0.5 );
  float4 Cy = float4( 2.0,  0.0, -1.0,  0.5 );

  float4 Az = float4( 6.0, -2.0, -6.0,  2.0 );
  float4 Bz = float4( 2.0,  6.0, -2.0, -6.0 );
  float4 Cz = float4( 5.0,  3.0, -3.0, -1.0 );
  float4 Aw = float4( 2.0, -6.0, -2.0,  6.0 );
  float4 Bw = float4( 6.0,  2.0, -6.0, -2.0 );
  float4 Cw = float4( 5.0, -1.0, -3.0,  3.0 );

  // These inequations define the line below which interpolation occurs.
  fx       = ( (Ao * fp.y) + (Bo * fp.x > Co) );
  fx_left  = ( (Ax * fp.y) + (Bx * fp.x > Cx) );
  fx_up    = ( (Ay * fp.y) + (By * fp.x > Cy) );
  fx3_left = ( (Az * fp.y) + (Bz * fp.x > Cz) );
  fx3_up   = ( (Aw * fp.y) + (Bw * fp.x > Cw) );

  interp_restriction_lv1      = ( (e != f) && (e != h)   && 
                                (!eq(f,b) && !eq(h,d) || eq(e,i) && !eq(f,i4) && !eq(h,i5) || eq(e,g) || eq(e,c)) &&
                                (f != f4 && f != i || h != h5 && h != i || h != g || f != c || eq(b,c1) && eq(d,g0)) );
                                
  interp_restriction_lv2_left = ( (e != g)  && (d != g)    );
  interp_restriction_lv2_up   = ( (e != c)  && (b != c)    );
  interp_restriction_lv3_left = ( eq2(g,g0) && !eq2(d0,g0) );
  interp_restriction_lv3_up   = ( eq2(c,c1) && !eq2(b1,c1) );


  edr       = ( weighted_distance( e, c, g, i, h5, f4, h, f) < weighted_distance( h, d, i5, f, i4, b, e, i) ) && interp_restriction_lv1;
  edr_left  = ( (coef * df(f,g)) <= df(h,c) ) && interp_restriction_lv2_left;
  edr_up    = ( df(f,g) >= (coef * df(h,c)))  && interp_restriction_lv2_up;
  edr3_left = interp_restriction_lv3_left;
  edr3_up   = interp_restriction_lv3_up;


  nc = ( edr && (fx || edr_left && (fx_left || edr3_left && fx3_left) || edr_up && (fx_up || edr3_up && fx3_up)) );
  
  px = ( df(e,f) <= df(e,h) );

  float4 res1 = nc.x ? px.x ? F : H : nc.y ? px.y ? B : F : nc.z ? px.z ? D : B : nc.w ? px.w ? H : D : E;
  float4 res2 = nc.w ? px.w ? H : D : nc.z ? px.z ? D : B : nc.y ? px.y ? B : F : nc.x ? px.x ? F : H : E;

  float4 res = lerp( res1, res2, step(c_df(E, res1), c_df(E, res2)) );

  return float3( res.r, res.g, res.b );
}


technique xBR5x_NoBlend
{
	pass
	{
		VertexShader = VS_XBR5X_NOBLEND;
		PixelShader  = PS_XBR5X_NOBLEND;
	}
}
