/*------------------.
| :: Description :: |
'-------------------/

Glamarye Fast Effects for ReShade (version 5)
======================================

**New in 5 ** HDR support. Faster AO. Better Fake GI, especially if depth is available. Better sharpen.

Author: Robert Jessop 

License: MIT
	
Copyright 2022 Robert Jessop 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	


About
-----
	
Designed for speed and quality, this shader for ReShade is for people who can't just run everything at max settings and want good enough post-processing without costing too much framerate. The FXAA quite a bit faster than as standard FXAA, and ambient occlusion more than twice as fast as other algorithms. Global Illumination is many times faster than other GI shaders, but it's not really the same - it's a fake 2D rough approximation (though it works surprising well!)
	
Glamarye Fast Effects combines several fast versions of common postprocessing enhancements in one shader for speed. Each can be enabled or disabled separately.
	
1. Fast FXAA (fullscreen approximate anti-aliasing). Fixes jagged edges. Almost twice as fast as normal FXAA, and it preserves fine details and GUI elements a bit better. However, long edges very close to horizontal or vertical aren't fixed so smoothly.
2. Intelligent Sharpening. Improves clarity of texture details.
3. Fast ambient occlusion. Shades concave areas that would receive less scattered ambient light. This is faster than typical implementations (e.g. SSAO, HBAO+). The algorithm gives surprisingly good quality with few sample points. It's designed for speed, not perfection - for highest possible quality you might want to try the game's built-in AO options, or a different ReShade shader instead. There is also the option, AO shine, for it to highlight convex areas, which can make images more vivid, adds depth, and prevents the image overall becoming too dark. 
4. Subtle Depth of Field. Softens distant objects. A sharpened background can distract from the foreground action; softening the background can make the image feel more real too. 
5. Detect Menus and Videos. Depending on how the game uses the depth buffer it may be possible to detect when not in-game and disable the effects.
6. Detect Sky. Depending on how the game uses the depth buffer it may be possible to detect background images behind the 3D world and disable effects for them.
7. Fake Global Illumination. Attempts to look like fancy GI shaders but using very simple approximations instead. Not the most realistic solution but very fast. It makes the lighting look less flat; you can even see bright colours reflecting off other surfaces in the area. The main part of it can be run in 2D mode for when depth info isn't available. With depth it can approximate local and distant indirect illumination even better, and add large scale ambient occlusion.
8. Adaptive contrast enchancement.
	
3, 4, 5 & 6 require depth buffer access. 7 improves with depth, but can work without.

High Dynamic Range (HDR) support: Glamayre detects HDR based on whether the game's output is 8, 10 or 16 bits, and adapts automatically.


Tested in Toussaint (and other places and games.)

![Screenshot](Glamayre%20v5.0%20double%20strength.png "Beauclair, The Witcher 3")

This was taken in version 5 with most effects' strengths doubled. Default settings are more subtle than this.

Comparison (version 5)
----------

[Comparison of v5 default, increase strength, no postprocessing, and Witcher 3's builtin FXAA, Sharpen and AO](https://imgsli.com/OTU0ODI)

	
Setup
-----
	
1. Install ReShade and configure it for your game (See https://reshade.me)
2. Copy Shaders/Glamarye_Fast_Effects.fx to ReShade's Shaders folder within the game's folder (e.g. C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3\bin\x64\reshade-shaders\Shaders)
3. Run the game
4. **Turn off the game's own FXAA, sharpen, depth of field & AO/SSAO/HBAO options** (if it has them).
	- Some games do not have individual options, but have a single "post-processing" setting. Setting that to the lowest value will probably disable them all.
5. Call up ReShade's interface in game and enable Glamarye_Fast_Effects ("Home" key by default)
6. Check if depth buffer is working and set up correctly. If it's not available then Depth of field, Ambient Occlusion, Detect Menus and Detect Sky won't work - disable them. 	
	- Use the built-in "Debug: show depth buffer" to check it's there. Close objects should be black and distant ones white.
	- Use "Debug: show depth and FXAA edges" to check it's aligned.
	- If it isn't right see [Marty McFly's Depth Buffer guide](https://github.com/martymcmodding/ReShade-Guide/wiki/The-Depth-Buffer).		
7. High Dynamic Range (HDR). Glamayre detects HDR based on whether the game's output is 8, 10 or 16 bits, and adapts automatically.
	
8. (Optional) Adjust based on personal preference and what works best & looks good in the game. 
	- Note: turn off "performance mode" in Reshade (bottom of panel) to configure, Turn it on when you're happy with the configuration.  
	

Troubleshooting
-----------

* For help installing and using ReShade see: (https://www.youtube.com/playlist?list=PLVJvgoR2kklkkDQxYjBsbR2y-ieWmgSZt) and for more troubleshooting (https://www.youtube.com/watch?v=hYUiWfvyafQ)
* Game crashes: disable anything else that also displays in game, such as Razer's FPS counter, or Steam's overlay. Some games have issues when more than one program is hooking DirectX.
* If you get "error X4505: maximum temp register index exceeded" on DirectX 9.0 games then in ReShade set FAST_AO_POINTS lower (4 should work).
* Fast Ambient Occlusion
	- If you see shadows in fog, mist, explosions etc then try tweaking **Reduce AO in bright areas** and **AO max distance** under Advanced Tuning and configuration.
	- If shadows in the wrong places then depth buffer needs configuring (see below)
	- If you see other artefacts (e.g. shadows look bad) then options are:
		- turn down the strength
		- increase the quality by setting FAST_AO_POINTS to 8 or 12.
		- Try tweaking the AO options in Advanced Tuning and configuration.
* Depth buffer issues:
	- Check ReShade's supported games list to see any notes about depth buffer first. 
	- Check in-game (playing, not in a menu or video cutscene):
	- If it's missing or looks different it may need configuration
		- Use right most tab in Reshade and try to manually find the depth buffer in the list of possible buffers.
		- Use ReShade's DisplayDepth shader to help find and set the right "global preprocessor definitions" to fix the depth buffer.
	- More guidance on depth buffer setup from Marty McFly: (https://github.com/martymcmodding/ReShade-Guide/wiki/The-Depth-Buffer)
* No effects do anything. Reset settings to defaults. If using "Detect menus & videos" remember it requires correct depth buffer - depth buffer is just black no effects are applied.
* HDR issues:
	- HDR support is new, please report any bugs, including ReShade's log, details of the game and your monitor. 16 bit mode in particular I haven't been able to test properly yet - there is an option, "HDR FP16 color is in nits", which only appears in 16 bit mode - try tweaking it.
* Things are too soft/blurry. 
	- Turn off DOF of turn down DOF blur. Depth of field blurs distant objects but not everyone wants that and if the depth buffer isn't set up well it might blur too much.
	- Make sure sharpen is on. FXAA may slightly blur fine texture details, sharpen can fix this.
* GShade: I have heard it works with GShade, but you might need to add "ReShade.fxh" and "ReShadeUI.fxh" from ReShade to your shaders directory too if you don't have them already.
* Everything is set up properly, but I want better quality.
	- use other reshade shaders instead. This is optimized for speed, some others have better quality.
	- Make sure you're not using two versions of the same effect at the same time. Modern games have built-in antialiasing and ambient occlusion (likely slower than Glamayre.) They might be called something like FXAA/SMAA/TAA and SSAO/HBAO or just hidden in a single postprocessing quality option. Disable the game's version or disable Glamayre's version.

		
Enabled/disable effects
-----------------------
	
**Fast FXAA** - Fullscreen approximate anti-aliasing. Fixes jagged edges. Recommendation: use with sharpen too, otherwise it can blur details slightly. 


**Intelligent Sharpen** - Sharpens details but not straight edges (avoiding artefacts). It works with FXAA and depth of field instead of fighting them. It darkens pixels more than it brightens them; this looks more realistic. 

**Fast Ambient Occlusion (AO) (requires depth buffer)** - Ambient occlusion shades places that are surrounded by points closer to the camera. It's an approximation of the reduced ambient light reaching occluded areas and concave shapes (e.g. under grass and in corners.)

**Depth of Field (DOF) (requires depth buffer)** - Softens distant objects subtly, as if slightly out of focus. 

**Detect menus & videos (requires depth buffer)** - Skip all processing if depth value is 0 (per pixel). Sometimes menus use depth 1 - in that case use Detect Sky option instead. Full-screen videos and 2D menus do not need anti-aliasing nor sharpenning, and may lose worse with them. Only enable if depth buffer always available in gameplay!

**Detect sky** - Skip all processing if depth value is 1 (per pixel). Background sky images might not need anti-aliasing nor sharpenning, and may look worse with them. Only enable if depth buffer always available in gameplay!
    

**Fake Global Illumination (Fake GI)** - Attempts to look like fancy GI shaders but using very simple approximations. Not as realistic, but very fast. 

_Note:_ Fake GI does not have a checkbox, instead you will see two versions of Glamayre in ReShade's effects list (with_Fake_GI and without_Fake_GI). Select the correct one to enable or disable Fake GI. This is because the extra shader passes it uses have some overhead that cannot be eliminated with a checkbox.

What is global illumination? The idea is to simulate how light moves around a scene - objects are lit not just by direct line of sight to lights, but also by light bouncing off other objects. This is hard to calculate in real time. Your game probably uses one of 3 types of lighting:

1. Modern games on modern GPUs may include actual global illumination, using ray tracing or path tracing. Adding Fake GI will make those look worse. 
2. Some games have pre-calculated static global illumination that doesn't change (or does in very limited ways). Moving objects might cast simple shadows but cannot cast or recieve bounced light. 
3. Some games have dynamic lighting, but only direct lighting and shadows. Secondary light bounces are not calculated and instead the a constant amount of ambient light is applied to every surface so they don't disappear completely when in shadow.

This Fake Global illumination doesn't calculate all the light bounces using physics. Instead it creates an effect that looks similar most of the time using some simple heuristics (e.g grey thing next to red thing will look a little bit redder). It's a fast approximation with no real understanding of the scene (in fact, it can work a purely 2D fashion if depth is not available). With luck, it looks like indirect bounced lighting and is close enough to make the image look better. It also tends to exagerate existing lighting in games, which if it is not too strong is okay.


Effects Intensity
-----------------

**Sharpen strength** - For values > 0.5 I suggest depth of field too. Values > 1 only recommended if you can't see individual pixels (i.e. high resolutions on small or far away screens.)

**AO strength** - Ambient Occlusion. Higher mean deeper shade in concave areas. Tip: if increasing also increase FAST_AO_POINTS preprocessor definition for higher quality.

**AO shine** - Normally AO just adds shade; with this it also brightens convex shapes. Maybe not realistic, but it prevents the image overall becoming too dark, makes it more vivid, and makes some corners clearer. Higher than 0.5 looks a bit unrealistic.

**DOF blur** - Depth of field. Applies subtle smoothing to distant objects. If zero it just cancels out sharpening on far objects. It's a small effect (1 pixel radius).

**AO Quality** - Due to compatibility with older drivers and D3D9 games this option has been removed - however you can still increase quality by changing the preprocessor definition FAST_AO_POINTS (defauly is 6, try 12 for best quality.)

Fake Global Illumination Settings
------------------------

These only work if you are using the _with Fake GI_ version of the shader. The first three options work even without depth information.

**Fake GI lighting strength** - Fake Global Illumination wide-area effect. Every pixel gets some light added from the surrounding area of the image.

**Fake GI saturation" - Fake Global Illumination can exaggerate colours in the image too much. Decrease this to reduce the colour saturation of the added light. Increase for more vibrant colours.

**Adaptive contrast enhancement** - Increases contrast relative to average light in surrounding area. Fake Global Illumination can reduce overall contrast; this setting compensates for that. It actually may be useful on it's own with lighting strength zeroed - it can improve contrast and clarity of any image. Recommendation: set to roughly half of GI lighting strength.

**Enable Fake GI effects that require depth** - This must be checked for the following sliders to have effect. If you don't have depth buffer data or don't want the AO effects then unchecking this and just using 2D Fake GI will make it slightly faster. 

**Fake GI big AO strength (requires depth)** - Large scale ambient occlusion. Higher = darker shadows. A big area effect providing subtle shading of enclosed spaces, which would recieve less ambient light. It is fast but very approximate. It is subtle and smooth so it's imperfections are not obvious nor annoying. Use in combination with normal ambient occlusion, not instead of it.

**Fake GI local AO strength (requires depth)** - Provides additional ambient occlusion with a flatter shape, subtly enhancing Fast Ambient Occlusion and bounce lighting, at very little cost. This Higher = darker shadows. This would have visible artefacts at high strength; therefore maximum shade added is very small. Use in combination with normal ambient occlusion, not instead of it.

**Fake GI local bounce strength (requires depth) ** - A bright red pillar next to a white wall will make the wall a bit red, but how red? It uses local depth and colour information to approximate short-range bounced light. It only affects areas made darker by Glamayre's fast ambient occlusion and Fake GI local AO (not big AO). Recommendation: keep near 1.

**Fake GI offset** - Fake global illumination uses a very blurred version of the image to collect approximate light from a wide area around each pixel. If use of depth is enabled, it adjusts the offset based on the angle of the local surface. This makes it better pick up colour from facing surfaces, but if set too big it may miss nearby surfaces in favour of further ones. The value is the maximum offset, as a fraction of screen size.

Output modes
-----------

**Normal** - Normal output

**Debug: show FXAA edges** - Highlights edges that are being smoothed by FXAA. The brighter green the more smoothing is applied. Don't worry if moderate smoothing appears where you don't think it should - sharpening will compensate.

**Debug: show AO shade & GI colour** - Shows amount of shading AO, bounce and Fake GI is adding, against a grey background. Use this if tweaking AO settings to help get them just right see the effect of each setting clearly. However, don't worry if it doesn't look perfect - it exaggerates the effect and many issues won't be noticable in the final image. The best final check is in normal mode.

**Debug: show depth buffer** - This image shows the distance to each pixel. However not all games provide it and there are a few different formats they can use. Use to check if it works and is in the correct format. Close objects should be black and distant ones white. If it looks different it may need configuration - Use ReShade's DisplayDepth shader to help find and set the right "global preprocessor definitions" to fix the depth buffer. If you get no depth image, set Depth of Field, Ambient Occlusion and Detect Menus to off, as they won't work.		

**Debug: show depth and edges** - Shows depth buffer and highlights edges - it helps you check if depth buffer is correctly aligned with the image. Some games (e.g. Journey) do weird things that mean it's offset and tweaking ReShade's depth buffer settings might be required. It's as if you can see the Matrix.

The rest of the debug options only apply if Fake Global Illumination is enabled (_with Fake GI_ version of Glamayre).

**Debug: show GI area colour** - Shows the colour of the light from the wider area affecting to each pixel.

**Debug: show GI bounce colour** - Shows the colour of local (short range) bounced light effect.

**Debug: show GI contrast background colour** - A blurred version of the image. Adaptive contrast enhancement works by increasing the difference of each pixel from the same point in this blurred image.

**show GI contrast diff** - Shows the difference how much Adaptive contrast is lightening or darkening each pixel, relative to grey.

**Debug: show GI big AO** - Shows the large scale ambient occlusion effect alone on a grey background.	

**Debug: show GI area depth** - Shows the blurred depth buffer which is used to calculate big AO

**Debug: Splitscreen OFF/ON** - Shows original image unprocessed on left half of screen, and after Glamayre effect on the right.

Advanced Tuning and Configuration
------------------------

You probably don't want to adjust these, unless your game has visible artefacts with the defaults.

**Reduce AO in bright areas** - Do not shade very light areas. Helps prevent unwanted shadows in bright transparent effects like smoke and fire, but also reduces them in solid white objects. Increase if you see shadows in white smoke, decrease for more shade on light objects. Doesn't help with dark smoke.

**AO max distance** - The ambient occlusion effect fades until it is zero at this distance. Helps avoid avoid artefacts if the game uses fog or haze. If you see deep shadows in the clouds then reduce this. If the game has long, clear views then increase it.

**AO radius** - Ambient Occlusion area size, as percent of screen. Bigger means larger areas of shade, but too big and you lose detail in the shade around small objects. Bigger can be slower too. 	
		
**AO shape modifier** - Ambient occlusion - weight against shading flat areas. Increase if you get deep shade in almost flat areas. Decrease if you get no-shade in concave areas areas that are shallow, but deep enough that they should be occluded. 
	
**AO max depth diff** - Ambient occlusion biggest depth difference to allow, as percent of depth. Prevents nearby objects casting shade on distant objects. Decrease if you get dark halos around objects. Increase if holes that should be shaded are not.

**FXAA bias** - Don't anti-alias edges with very small differences than this - this is to make sure subtle details can be sharpened and do not disappear. Decrease for smoother edges but at the cost of detail, increase to only sharpen high-contrast edges. This FXAA algorithm is designed for speed and doesn't look as far along the edges as others - for best quality you might want turn it off and use a different shader, such as SMAA.

**Tone mapping compensation** (available for non-HDR output only) - In the real world we can see a much wider range of brightness than a standard screen can produce. Games use tone mapping to reduce the dynamic range, especially in bright areas, to fit into display limits. To calculate lighting effects like Fake GI accurately on SDR images, we want to undo tone mapping first, then reapply it afterwards. Optimal value depends on tone mapping method the game uses. You won't find that info published anywhere for most games. Our compensation is based on Reinhard tone mapping, but hopefully will be close enough if the game uses another curve like ACES. At 5 it's pretty close to ACES in bright areas but never steeper. In HDR modes this is not required.";

**HDR FP16 color is in nits** (available for HDR output only) - Set to true if game output is in nits (100 is white); I hear Epic games may use this. False if it's in scRGB (1 is white)";

**FAST_AO_POINTS** (preprocessor definition - bottom of GUI). Number of depth sample points in Performance mode. This is your speed vs quality knob; higher is better but slower. Minimum is 2, Maximum 16. 

Tips
----

- Feel free to tweak the strength settings, to taste.
- Check if game provides depth buffer! If not turn of depth of field, ambient occlusion and detect menus for better performance (they won't affect the image if left on by mistake).
- If depth is always available during gameplay then enabling Detect menus and videos is recommended to make non-gamplay parts clearer. 
- If the game uses lots of dithering (i.e. ░▒▓ patterns), sharpen may exagerate it, so use less sharpenning. (e.g. Witcher 2's lighting & shadows.)		
- If you don't like an effect then reduce it or turn it off. Disabling effects improves performance, except sharpening, which is basically free if FXAA or depth of field is on.	
- If the game uses lots of semi-transparent effects like smoke or fog, and you get incorrect shadows/silluettes then you may need to tweak AO max distance. Alternatively, you could use the game's own slower SSAO option if it has one. This is a limitation of ReShade and similar tools - ambient occlusion should be done before transparent objects, but ReShade can only work with the output of the game and apply it after.
- You can mix and match with in-game options or other ReShade shaders, though you lose some the performance benefits of a combined shader. Make sure you don't have two effects of the same type enabled.
- Don't set FAST_AO_POINTS higher than 12 - the algorithm is designed for few points and won't use the extra points wisely.
- Experiment!
	* What strength settings looks best may depend on the game, your monitor, and its settings (your TV's "game mode" may have some built-in sharpening for example).
	* Depth of field, AO Shine, and Fake Glboal Illumination are really a matter of personal taste. 
	* Don't be afraid to try lower FAST_AO_POINTS (minimum: 2) and turn off bounce lighting if you want really fast AO. Even very low quality AO can make the image look better (but keep strength <= 0.5).
	* Be careful with the advanced ambient occlusion settings; what looks good in one scene may be too much in another. Try to test changes in different areas of the game with different fog and light levels. 
- If using fake GI but with game's builtin Ambient Occlusion instead of Glamayre's, and the game has options the pick a stronger one as, as Fake GI can reduce the effect of Ambient Occlusion if applied afterwards.
		
Benchmark
---------

TODO: redo this for current version.

- Game: Witcher 3 
- Scene: [Beauclair looking at the water feature opposite the bank](/Benchmark%20Location.png) 
- Settings: 1080p, Graphics settings low
- Hardware: Razer Blade Stealth 13 Late 2019 Laptop with NVIDIA GeForce GTX 1650 with Max-Q design
- Shader version: 1.0 (didn't include fake global illumination effect)

**Baseline**

	FPS	Settings
	86	No post-processing

**Fast_FXAA_sharpen_DOF_and_AO v1.0 results (previous name for Glamarye Fast Effects)**

	FPS	Settings
	82	v1.0 defaults (Fast FXAA + sharpen + Fast AO + bounce + DOF)
	84	Fast FXAA only
	84	Fast FXAA + sharpen
	83	Fast AO only
	82	Fast AO only, FAST_AO_POINTS 12
	83	Fast AO + bounce
	81	Fast AO + bounce, FAST_AO_POINTS 12
	80	v1.0 all max, FAST_AO_POINTS 12
	
**Note**: Full benchmark with v3.0 not done yet. Fake Global Illumination wasn't in 1.0 and the default FAST_AO_POINTS was slightly lower (6). V2 is 1-2 FPS slower in its default settings, but if configured like 1.0 is faster.

**Witcher 3 builtin post-processing**

	FPS	Settings
	83	Anti-Aliasing
	82	Anti-Aliasing, sharpening
	79	SSAO
	74	Anti-Aliasing, sharpening, SSAO
	72	HBAO+
	68	Anti-Aliasing, sharpening, HBAO+

**Comparison to other Reshade shaders**

SMAA and FXAA are anti-aliasing. MXAO and SSDO and ambient occlusion.

	FPS	Shader and settings
	81	SMAA
	82	FXAA
	75	MXAO very low (4 samples)
	71	MXAO default (16 samples)
	69	MXAO default plus MXAO_ENABLE_IL on
	68	PPFX SSDO
	67	FXAA + MXAO (default quality)
	64	FXAA + PPFX SSDO

Similar results (relatively) are seen in other locations and graphic settings and resolutions.
	
Tech details
------------
	
Combining FXAA, sharpening and depth of field in one shader works better than separate ones because the algorithms work together. Each pixel is sharpened or softened only once, and where FXAA detects strong edges they're not sharpened. With seperate shaders sometimes sharpening can undo some of the good work of FXAA. More importantly, it's much faster because we only read the pixels only once.
	
GPUs are so fast that memory is the performance bottleneck. While developing I found that number of texture reads was the biggest factor in performance. Interestingly, it's the same if you're reading one texel, or the bilinear interpolation of 4 adjacent ones (interpolation is implemented in hardware such that it is basically free). Each pass has noticable cost too. Therefore everything is combined in one pass, with the algorithms designed to use as few reads as possible. Fast FXAA makes 7 reads per pixel. Sharpen uses 5 reads, but 5 already read by FXAA so if both are enabled it's basically free. Depth of field also re-uses the same 5 pixels, but adds a read from the depth buffer. Ambient occlusion adds 3-9 more depth buffer reads (depending on quality level set). 
	
FXAA starts with the centre pixel, plus 4 samples each half a pixel away diagonally; each of the 4 samples is the average of four pixels. Based on their shape it then samples two more points 3.5 pixels away horizontally or vertically. We look at the diamond created ◊ and look at the change along each side of the diamond. If the change is bigger on one pair of parallel edges and small on the other then we have an edge. The size of difference determines the score, and then we blend between the centre pixel and a smoothed using the score as the ratio. 

The smooth option is the four nearby samples minus the current pixel. Effectively this convolution matrix:

	1 2 1
	2 0 2  / 12;
	1 2 1
	
Sharpening increases the difference between the centre pixel and it's neighbors. We want to sharpen small details in textures but not sharpen object edges, creating annoying lines. To achieve this it calculates two sharp options: It uses the two close points in the diamond FXAA uses, and calculates the difference to the current pixel for each - if both are positive or both negative then if adds them together and sharpens the texture; if the signs don't match then we have an edge and it doesn't sharpen. It darkens pixels more than it brightens them; this looks more realistic - the amount of brightening is automatically adjusted based on the light, so in dark areas pixels can become lighter, but it bright areas they cannot. FXAA is calculated before but applied after sharpening. If FXAA decides to smooth a pixel the maximum amount then sharpening is cancelled out completely.
	
Depth of field is subtle; this implementation isn't a fancy cinematic focus effect. Good to enable if using sharpening, as it takes the edge of the background and helps emphasise the foreground. If DOF blur is set to zero, then it just reduces the strength of sharpening, so sharpening gradually disappears in the distance. If DOF blur is higher, it also blurs pixels, increasing blur with distance - at 1 pixels at maximum depth as set to the smooth value. The total change in each pixel is limited to 50% to reduce problems at near-to-far edges when blur is high.
		
Ambient occlusion adds shade to concave areas of the scene. It's a screen space approximation of the amount of ambient light reaching every pixel. It uses the depth buffer generated by the rasterisation process. Without ambient occlusion everything looks flat. However, ambient occlusion should be subtle and not be overdone. Have a look around in the real world - the bright white objects with deep shading you see in research papers just aren't realistic. If you're seeing black shade on bright objects, or if you can't see details in dark scenes then it's too much. However, exagerating it just a little bit compared to the real-world is good - it's another depth clue for your brain and makes the flat image on the flat screen look more 3D.  
	
Fast Ambient occlusion is pretty simple, but has a couple of tricks that make it look good with few samples. Unlike well known techniques like SSAO and HBAO it doesn't try to adapt to the local normal vector of the pixel - it picks sample points in a simple circle around the pixel. Samples that are in closer to the camera than the current pixel add shade, ones further away don't. At least half the samples must be closer for any shade to be cast (so pixels on flat surfaces don't get shaded, as they'll be half in-front at most). It has 4 tricks to improve on simply counting how many samples are closer.

1. Any sample significantly closer is discarded and replaced with an estimated sample based on the opposite point. This prevents nearby objects casting unrealistic shadows and far away ones. Any sample more than significantly further away is clamped to a maximum. AO is a local effect - we want to measure shade from close objects and surface contours; distant objects should not affect it.
2. Our 2-10 samples are equally spaced in a circle. We approximate a circle by doing linear interpolation between adjacent points. Textbook algorithms do random sampling; with few sample points that is noisy and requires a lot of blur; also it's less cache efficient.
3. The average difference between adjacent points is calculated. This variance value is used to add fuzziness to the linear interpolation in step 2 - we assume points on the line randomlyh vary in depth by this amount. This makes shade smoother so you don't get solid bands of equal shade. 
4. Pixels are split into two groups in a checkerboard pattern (▀▄▀▄▀▄). Alternatve pixels use a circle of samples half of the radius. With small pixels, the eye sees a half-shaded checkerboard as grey, so this is almost as good taking twice as many samples per pixel. More complex dithering patterns were tested but don't look good (░░).

Amazingly, this gives quite decent results even with very few points in the circle.

There are two optional variations that change the Fast Ambient Occlusion algorithm:

1. Shine. Normally AO is used only to make pixels darker. With the AO Shine setting (which is set quite low by default), we allow AO amount to be negative. This brightens convex areas (corners and bumps pointing at the camera.) Not super realistic but it really helps emphasise the shapes. This is basically free - instead of setting negative AO to zero we multiply it by ao_shine_strength.
2. Bounce lighting. This is good where two surfaces of different colour meet. However, most of the time this has little effect so it's not worth sampling many nearby points. We use same wide area brightness from the Fake GI algorithm to estimate the ambient light and therefore the unlit colour of the pixel, and therefore how much light it will reflect. We blur the image to get the average light nearby. We multiply the unlit pixel colour with the nearby light to get the light bounced. The value is multiplied by our AO value too, which is a measure of shape and makes sure only concave areas get bounced light added.

Fake Global Illumination without depth enabled is a quite simple 2D approximation of global illumination. Being 2D it's not very realistic but is fast. First we downsample and blur the main image to get the overall colour of light in each area. The blurred and original pixel's brightness are used together to estimate the current pixel's true surface colour; is likely a light surface in shadow, or a dark surface in the light? We reduce the saturation of the blurred colour (to prevent oversaturated colour in the output.) The pixel colour is multiplied by the blurred area light and blended with the pixel. We clamp the maximum brightness change to prevent darkenning or washing out details. Overall the image appears less flat - even if the illumination isn't always realistic, the subtle variations in shade help make the image seem more real.

For the rest of the effects we actually use two levels of blur - the big one, and a smaller, less smooth one which is simply a 2.5 MIP level read of the first step of our blur. 

Adaptive Contrast enhancement uses our the average of our two blurred images as a centre value and moves each pixel value away from it. 

If depth is enabled then we also include a depth channel in the blurred images. Also, where depth==1 (sky) we brighten and completely desaturate the colour image - this makes sky and rooftops look better. If depth is enabled and Fake GI offset set then we use ddx & ddy to read the local depth buffer surface slope and move the point we sample the big blur in the direction away from the camera.

Big AO (large scale ambient occlusion) simply uses the ratio between the current pixel's depth and the big blurred depth value. If the local depth is more than twice the distance it actually reduces the amount of AO to avoid overshading distant areas seen through small gaps or windows. We clamp it to only darken - we don't do AO shine at this scale.

Fake GI local AO simply compares the pixel's depth to the smaller blurred depth image. If it's further by a minimum amount then we add a small amount (max .1) to the AO value fast AO uses. This flat amount isn't smooth but is small enough that you can't see the edges. It's a different shape to fast AO so subtly enhances the overall shape and shade of AO (and local bounce light). This is basically free performance-wise.

Fake GI local bounce uses the colour of the smaller blur, sharpens it relative to the current pixel. It then multiplies that light with an estimate of the current pixel's true surface colour, similar to the main large area GI. However, change is applied in proportion to the AO value calculated by fast AO and Fake GI local AO. The effect is stronger indirect bounced light only in concave areas.

HDR, SDR, and non-linear colour
-------------------------------

For both blending and lighting calculations and we want linear light values. ReShade doesn't give you that - game output is normally non-linear to take best advantage of the limited bits. 16-bit HDR is linear, which is nice. 10 bit HDR uses a special curve call Perceptual Quantizer (PQ) - we have to do the reverse of the PQ operation, do our thing, then reapply PQ. 8-bit SDR (standard dynamic range) uses the sRGB curve - ReShade can take care of that for us. 

Unforuntately, for SDR there's more... In the real world we can see a much wider range of brightness than a standard screen can produce. Before applying the sRGB curves, games apply a tone mapping curve to reduce the dynamic range, especially in bright areas. We don't know what tone mapping algorithm each game uses. Our equation to reverse it is assumes the game uses extended Reinhard tone mapping, because it's simple. With luck it will be close enough to whatever the game uses so we make the lighting look better and not worse. With Cwhite 5 it's actually pretty close to the popular ACES tonemapping curve for bright values but never steeper - so it should work okay on games using that or similar filmic curves. The slightly more conservative default of 3 was chosen as higher values are just too much for games like Deus Ex: Human Revolution. For performance and to avoid causing FXAA issues, this is applied only in the Fake GI parts of the code.

In HDR mode the situation is more complicated. We don't do tone mapping compensation in HDR mode because it's hard to know how much to apply. However, it's probably not needed as in HDR modes there is much less compression of highs anyway due to the higher maximum brightness. Games are supposed to let the display do the tone-mapping, or adapt tone mapping based on the display's capabilities. But if games make it user configured or TVs are trying to do "Intelligent" tone mapping then it will be suboptimal. Both games and TVs should follow HGIG guidelines (https://www.hgig.org/doc/ForBetterHDRGaming.pdf). However, my LG C1 didn't, even in game mode. However, finding and manually selecting HGIG mode in it's menu improved things. 

Ideas for future improvement
----------------------------

- Fog detect
- Stop improving this a start playing the games again!

History
-------

(*) Feature (+) Improvement	(x) Bugfix (-) Information (!) Compatibility

5.0 (+) Faster AO. (+) Fake GI: better contrast, better colour, if depth is available. (*) Fake GI: large scale AO, enhanced local AO and bounce. (*) HDR mode with automatic detection of format. Automatically uses sRGB curve, PQ curve or linear depending on whether input is 8, 10 or 16 bit. (*) Tone mapping compensation - in SDR mode this gives us better Fake GI. (+) Fix banding artefacts on high sharp values.

4.4_beta (*) Experimental HDR support

4.3 (+) More Fake GI tweaks. It should look better and not have any serious artefacts in difficult scenes. Amount applied is limited to avoid damaging details and it is actually simpler now - gi.w is gone (potentially free for some future use.)

4.2.1 (+) In response to feedback about the effect not being strong enough I have increased the maximum Fake GI strength and contrast.

4.2 (+) Improved quality of fake global illumination, and clearer settings for it. Tweaked defaults.

4.1.1 (x) Fixed typo that caused failure on older versions of ReShade (though current version 4.9.1 was okay)

4.1 (x) Fixed bug affecting AO quality for some FAST_AO_POINTS. Improved variance calculation for AO. Fixed compiler warnings.

4.0 (+) Allow stronger sharpening. Optimized Ambient Occlusion to use fewer instructions and registers, which should fix compilation issues on some D3D9 Games. Faster and better quality Fake Global illumination; also more tweakable. Make bounce lighting faster and smoother by using using some blurred values we calculate anyway for Fake GI.

3.2 (x) Make quality setting Preprocessor only as someone reported compatility issues with Prince of Persia  - looks like too many registers so need to simplify. Change AO to use float4x4 to sav intructions and registers.

3.1 (+) Option to Reduce AO in bright areas. Helps prevent unwanted shadows in bright transparent effects like smoke and fire.

3.0 (+) More tweaks to Fake GI - improving performance and smoothness. Improved FXAA quality (fixed rare divide by zero and fixed subtle issue where Fake GI combined badly with FXAA). Improved sharpen quality (better clamp limits). Simplified main settings. Added dropdown to select from two AO quality levels. Bounce tweaked and moved bounce strength to advanced settings (it is now equal to ao_strength by default - having them different is usually worse.)

2.1 (+) Smoother blur for Fake Global Illumination light, which fixes artefacts (thank you Alex Tuderan). Tweaked defaults. Minor tweaks elsewhere. Smoother where GI meets sky detect.

2.0 (*) Fake Global Illumination! Even better than the real thing (if speed is your main concern!)

1.2.3 (x) Regression fix: AO shade colour when not using bounce. Actually tweaked this whole section so it works like bounce lighting but using the current pixel instead of reading nearby ones, and simplified the code in places too. 

1.2.2 (+) bounce_lighting performance improvement!

1.2.1 (x) Bugfix: didn't compile in OpenGL games.

1.2 (+) Better AO. Smoother shading transition at the inner circle of depth sample points - less artefacts at high strength. Tweaked defaults - The shading improvements enabled me go back to default FAST_AO_POINTS=6 for better performance. Allow slightly deeper shade at max.

1.1 (+) Improved sharpening. Tweaked bounce lightling strength. Tweaked defaults. Simplified settings. Quality is now only set in pre-processor - to avoid problems.

1.0 (-) Initial public release

Thank you:

Alex Tuduran for the previous blur algorithm, suggestions and inspiration for the brightness part of Fake GI algorithm.

macron, AlucardDH, NikkMann, Mirt81, distino, vetrogor, illuzio, geisalt for feedback and bug reports.

ReShade devs for ReShade.

Glamarye?
----------

In the Andrzej Sapkowski's Witcher novels, [Glamayre](https://witcher.fandom.com/wiki/Glamour) is magical make-up. Like Sapkowski's sourceresses, The Witcher 3 is very beautiful already, but still likes a bit of Glamayre.

	
*/


/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

namespace Glamarye_Fast_Effects 
{


// This is your quality/speed trade-off. Miniumum 2, maximum 16. 4 and 8 are good options as they have special optimized code.
//This was a GUI slider, but it caused problems with DirectX 9 games failing to compile it. Have to use pre-processor.
#ifndef FAST_AO_POINTS
	#define FAST_AO_POINTS 6
#endif

uniform bool fxaa_enabled <
    ui_category = "Enabled Effects";
    ui_label = "Fast FXAA";
    ui_tooltip = "Fullscreen approximate anti-aliasing. Fixes jagged edges. \n\nRecommendation: use with sharpen too, otherwise it can blur details slightly. ";
    ui_type = "radio";
> = true;

uniform bool sharp_enabled <
    ui_category = "Enabled Effects";
    ui_label = "Intelligent Sharpen";
    ui_tooltip = "Sharpens image, but working with FXAA and depth of field instead of fighting them. It darkens pixels more than it brightens them; this looks more realistic. ";
    ui_type = "radio";
> = true;


uniform bool ao_enabled <
    ui_category = "Enabled Effects";
    ui_label = "Fast Ambient Occlusion (AO) (requires depth buffer)";
    ui_tooltip = "Ambient occlusion shades places that are surrounded by points closer to the camera. It's an approximation of the reduced ambient light reaching occluded areas and concave shapes (e.g. under grass and in corners.)\n\nFor quality adjustment, set preprocessor definition FAST_AO_POINTS. Higher is better quality but slower. Minimum is 2; don't go above 12 - algorithm isn't designed to take advantage of more points.";
    ui_type = "radio";
> = true;


uniform bool dof_enabled <
    ui_category = "Enabled Effects";
    ui_label = "Subtle Depth of field (DOF) (requires depth buffer)";
    ui_tooltip = "Softens distant objects subtly, as if slightly out of focus. ";
    ui_type = "radio";
> = true;

uniform bool depth_detect <
    ui_category = "Enabled Effects";
    ui_label = "Detect menus & videos (requires depth buffer)";
    ui_tooltip = "Skip all processing if depth value is 0 (per pixel). Sometimes menus use depth 1 - in that case use Detect Sky option instead. Full-screen videos and 2D menus do not need anti-aliasing nor sharpenning, and may lose worse with them.\n\nOnly enable if depth buffer always available in gameplay!";
    ui_type = "radio";
> = false;

uniform bool sky_detect <
    ui_category = "Enabled Effects";
    ui_label = "Detect sky (requires depth buffer)";
    ui_tooltip = "Skip all processing if depth value is 1 (per pixel). Background sky images might not need anti-aliasing nor sharpenning, and may look worse with them.\n\nOnly enable if depth buffer always available in gameplay!";
    ui_type = "radio";
> = false;


uniform int debug_mode <
    ui_category = "Output mode";
	ui_type = "combo";
    ui_label = "Output mode";
    ui_items = "Normal\0"
	           "Debug: show FXAA edges\0"
			   "Debug: show AO shade & bounce\0"
	           "Debug: show depth buffer\0"
			   "Debug: show depth and edges\0"
			   "Debug: show Fake GI area light\0"
			   ;
	ui_tooltip = "Handy when tuning ambient occlusion settings.";
> = 0;

/*
Removed debug modes. Were used in development but aren't really useful to users.
				"Debug: show GI bounce colour\0"	
			   "Debug: show GI contrast background colour\0"	
			   "Debug: show GI contrast diff\0"	
			   "Debug: show GI big AO\0"	
			   "Debug: show GI area depth\0"	
			   "Debug: Apply only to right half of screen\0"										
			   
*/


//////////////////////////////////////

uniform float sharp_strength < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Effects Intensity";
	ui_min = 0; ui_max = 2; ui_step = .05;
	ui_tooltip = "For high values I suggest depth of field too. Values > 1 only recommended if you can't see individual pixels (i.e. high resolutions on small or far away screens.)";
	ui_label = "Sharpen strength";
> = 0.5;

uniform float ao_strength < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Effects Intensity";
	ui_min = 0.0; ui_max = 1.0; ui_step = .05;
	ui_tooltip = "Ambient Occlusion. Higher mean deeper shade in concave areas.\n\nTip: if increasing AO strength don't set AO Quality to Performance, or you might notice some imperfections. ";
	ui_label = "AO strength";
> = 0.6;


uniform float ao_shine_strength < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Effects Intensity";
	ui_min = 0.0; ui_max = 1; ui_step = .05;
    ui_label = "AO shine";
    ui_tooltip = "Normally AO just adds shade; with this it also brightens convex shapes. \n\nMaybe not realistic, but it prevents the image overall becoming too dark, makes it more vivid, and makes some corners clearer. ";
> = 0.6;

uniform float dof_strength < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Effects Intensity";
	ui_min = 0; ui_max = 1; ui_step = .05;
	ui_tooltip = "Depth of field. Applies subtle smoothing to distant objects. If zero it just cancels out sharpening on far objects. It's a small effect (1 pixel radius).";
	ui_label = "DOF blur";
> = 0.3;

////////////////////////////////////////////////

uniform float gi_strength < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Fake Global Illumination (with_Fake_GI version only)";
	ui_min = 0.0; ui_max = 1.0; ui_step = .05;
    ui_label = "Fake GI lighting strength";
    ui_tooltip = "Fake Global Illumination wide-area effect. Every pixel gets some light added from the surrounding area of the image.";
> = 0.6;

uniform float gi_saturation < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Fake Global Illumination (with_Fake_GI version only)";
	ui_min = 0.0; ui_max = 1.0; ui_step = .05;
    ui_label = "Fake GI saturation";
    ui_tooltip = "Fake Global Illumination can exaggerate colours in the image too much. Decrease this to reduce the colour saturation of the added light. Increase for more vibrant colours. ";
> = 0.6;

uniform float gi_contrast < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Fake Global Illumination (with_Fake_GI version only)";
	ui_min = 0; ui_max = 1; ui_step = 0.01;
	ui_tooltip = "Increases contrast relative to average light in surrounding area. \n\nFake Global Illumination can reduce overall contrast; this setting compensates for that and actually improves contrast and clarity compared to the original. \n\nRecommendation: set to roughly half of GI lighting strength.";
	ui_label = "Adaptive contrast enhancement";
> = 0.3;

uniform bool gi_use_depth <
	ui_category = "Fake Global Illumination (with_Fake_GI version only)";	
    ui_label = "Enable Fake GI effects that require depth (below)";    
	ui_tooltip = "If you don't have depth buffer data, or if you don't want the full effect then 2D mode may be faster. \n\nWith depth enabled, it adds big AO, improved local AO with local bounce light, and better direction for lighting.";
> = true;

uniform float gi_ao_strength < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Fake Global Illumination (with_Fake_GI version only)";
	ui_min = 0; ui_max = 1; ui_step = .05;
	ui_tooltip = "Large scale ambient occlusion. Higher = darker shadows. \n\nA big area effect providing subtle shading of enclosed spaces, which would recieve less ambient light. \n\nIt is a fast but very approximate. It is subtle and smooth so it's imperfections are not obvious nor annoying. \n\nUse in combination with normal ambient occlusion, not instead of it.";
	ui_label = "Fake GI big AO strength (requires depth)";
> = .5;

uniform float gi_local_ao_strength < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Fake Global Illumination (with_Fake_GI version only)";
	ui_min = 0; ui_max = 1; ui_step = .05;
	ui_tooltip = "Fake GI provides additional ambient occlusion, subtly enhancing Fast Ambient Occlusion and bounce lighting, at very little cost. \n\nThis Higher = darker shadows. \n\nThis would have visible artefacts at high strength; therefore maximum shade added is very small. Use in combination with normal ambient occlusion, not instead of it.";
	ui_label = "Fake GI local AO strength (requires depth)";
> = .75;

uniform float bounce_multiplier < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Fake Global Illumination (with_Fake_GI version only)";
	ui_min = 0.0; ui_max = 2.0; ui_step = .05;
    ui_label = "Fake GI local bounce strength (requires depth)";
    ui_tooltip = "It uses local depth and colour information to approximate short-range bounced light. \n\nIt only affects areas made darker by ambient occlusion. A bright red pillar next to a white wall will make the wall a bit red, but how red?";
> = 1;


uniform float gi_shape < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Fake Global Illumination (with_Fake_GI version only)";
	ui_min = 0; ui_max = .2; ui_step = .01;
	ui_tooltip = "Fake global illumination uses a very blurred version of the image to collect approximate light from a wide area around each pixel. \n\nIf depth is available, it adjusts the offset based on the angle of the local surface. This makes it better pick up colour from facing surfaces, but if set too big it may miss nearby surfaces in favour of further ones. \n\nThe value is the maximum offset, as a fraction of screen size.";
	ui_label = "Fake GI offset";
> = .1;

////////////////////////////////////////////////////////

uniform float reduce_ao_in_light_areas < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Advanced Tuning and Configuration";
    ui_label = "Reduce AO in bright areas";
	ui_min = 0.0; ui_max = 8; ui_step = 0.1;
    ui_tooltip = "Do not shade very light areas. Helps prevent unwanted shadows in bright transparent effects like smoke and fire, but also reduces them in solid white objects. Increase if you see shadows in white smoke, decrease for more shade on light objects. Doesn't help with dark smoke.";    
> = 1;

uniform float ao_fog_fix < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Advanced Tuning and Configuration";
	ui_category_closed=true;
	ui_min = 0.0; ui_max = 2; ui_step = .05;
    ui_label = "AO max distance";
    ui_tooltip = "The ambient occlusion effect fades until it is zero at this distance. Helps avoid avoid artefacts if the game uses fog or haze. If you see deep shadows in the clouds then reduce this. If the game has long, clear views then increase it.";
> = .5;

uniform float ao_radius < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Advanced Tuning and Configuration";
	ui_min = 0.0; ui_max = 2; ui_step = 0.01;
	ui_tooltip = "Ambient Occlusion area size, as percent of screen. Bigger means larger areas of shade, but too big and you lose detail in the shade around small objects. Bigger can be slower too. ";
	ui_label = "AO radius";
> = 1;


uniform float ao_shape_modifier < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Advanced Tuning and Configuration";
	ui_min = 1; ui_max = 4000; ui_step = 1;
	ui_tooltip = "Ambient occlusion - weight against shading flat areas. Increase if you get deep shade in almost flat areas. Decrease if you get no-shade in concave areas areas that are shallow, but deep enough that they should be occluded. ";
	ui_label = "AO shape modifier";
> = 1000;

uniform float ao_max_depth_diff < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Advanced Tuning and Configuration";
	ui_min = 0; ui_max = 2; ui_step = 0.001;
	ui_tooltip = "Ambient occlusion biggest depth difference to allow, as percent of depth. Prevents nearby objects casting shade on distant objects. Decrease if you get dark halos around objects. Increase if holes that should be shaded are not.";
	ui_label = "AO max depth diff";
> = 0.5;

uniform float fxaa_bias < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Advanced Tuning and Configuration";
	ui_min = 0; ui_max = 0.1; ui_step = 0.001;
	ui_tooltip = "Don't anti-alias edges with very small differences than this - this is to make sure subtle details can be sharpened and do not disappear. Decrease for smoother edges but at the cost of detail, increase to only sharpen high-contrast edges. ";
	ui_label = "FXAA bias";
> = 0.025;

#if BUFFER_COLOR_BIT_DEPTH == 8
uniform float tone_map < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Advanced Tuning and Configuration";
	ui_min = 1; ui_max = 9; ui_step = .1;
	ui_tooltip = "In the real world we can see a much wider range of brightness than a standard screen can produce. \n\nGames use tone mapping to reduce the dynamic range, especially in bright areas, to fit into display limits. \n\nTo calculate lighting effects like Fake GI accurately on SDR images, we want to undo tone mapping first, then reapply it afterwards. \n\nOptimal value depends on tone mapping method the game uses. You won't find that info published anywhere for most games. \n\nOur compensation is based on Reinhard tonemapping, but hopefully will be close enough if the game uses another curve like ACES. At 5 it's pretty close to ACES in bright areas but never steeper. \n\nApplies for Fake GI in SDR mode only.";
	ui_label = "Tone mapping compensation";
> = 3;
#endif



#if BUFFER_COLOR_BIT_DEPTH == 16
uniform bool hdr_nits < 
	ui_category = "Advanced Tuning and Configuration";	
	ui_tooltip = "True if game output is in nits (100 is SDR white); I hear Epic games may use this. False if it's in scRGB (1 is SDR white)";
	ui_label = "HDR FP16 color is in nits.";
> = false;
#endif

uniform bool abtest <
    ui_category = "Advanced Tuning and Configuration";
    ui_label = "A/B test";
    ui_tooltip = "Ignore this. Used by developer when testing and comparing algorithm changes.";
    ui_type = "radio";
> = false;

//////////////////////////////////////////////////////////////////////

//Tone map compensation to make top end closer to linear.
float3 undoTonemap(float3 c) {
#if BUFFER_COLOR_BIT_DEPTH > 8
	return c;
#else
	return c/(1.0-(1.0-rcp(tone_map))*c);
#endif
}

float3 reapplyTonemap(float3 c) {
#if BUFFER_COLOR_BIT_DEPTH > 8
	return c;
#else
	return c/((1-rcp(tone_map))*c+1.0);
#endif
}

//Colour space conversion. We scale HDR options so SDR range is about 0-1.
float3 toLinear(float3 c) {
	float3 r = c; 
	
#if BUFFER_COLOR_BIT_DEPTH == 10
		//HDR10 we need to convert between PQ and linear. https://en.wikipedia.org/wiki/Perceptual_quantizer
		const float m1 = 1305.0/8192.0;
		const float m2 = 2523.0/32.0;
		const float c1 = 107.0/128.0;
		const float c2 = 2413.0/128.0;
		const float c3 = 2392.0/128.0;
		//Unneccessary max commands are to prevent compiler warnings, which might scare users.
		float3 powc = pow(max(c,0),1.0/m2);
		r = pow(max( max(powc-c1, 0) / ( c2 - c3*powc ), 0) , 1.0/m1);		
		
		//We scale by 20 instead of 10,000 - this is to keep approx brightness similar to SDR (affects debug modes and smoke_fix)
		r*=20;
#endif
#if BUFFER_COLOR_BIT_DEPTH == 16
	if(hdr_nits) r *= 0.01;	
#endif

	return r;
}

float3 toOutputFormat(float3 c) {
	float3 r = c; 
	
#if BUFFER_COLOR_BIT_DEPTH == 10
		//HDR10 we need to convert between PQ and linear. https://en.wikipedia.org/wiki/Perceptual_quantizer
		const float m1 = 1305.0/8192.0;
		const float m2 = 2523.0/32.0;
		const float c1 = 107.0/128.0;
		const float c2 = 2413.0/128.0;
		const float c3 = 2392.0/128.0;	
		c = c*0.05; //We scaled by 20 instead of 10,000, so here divide by 20. - this is to keep approx brightness similar to SDR (affects debug modes and smoke_fix)
		
		//Unneccessary max commands are to prevent compiler warnings, which might scare users.		
		float3 powc = pow(max(c,0),m1);
		r = pow(max( ( c1 + c2*powc ) / ( 1 + c3*powc ), 0 ), m2);		
#endif
	
#if BUFFER_COLOR_BIT_DEPTH == 16
	if(hdr_nits) r *= 100;	//Max SDR Nits equivelent should be 80, but it seems a thing for games to multiply by 1.5 in HDR mode, which would make it 120. Lets go halves - it doesn't have to be precise just in the ballpark area.
#endif
	return r;
}
sampler2D samplerColor
{
	// The texture to be used for sampling.
	Texture = ReShade::BackBufferTex;
#if BUFFER_COLOR_BIT_DEPTH > 8
	SRGBTexture = false;
#else
	SRGBTexture = true;
#endif
};


float4 getBackBufferLinear(float2 texcoord) {	 	

	float4 c = tex2D( samplerColor, texcoord);	
	c.rgb = toLinear(c.rgb);
	return c;
}

sampler2D samplerDepth
{
	// The texture to be used for sampling.
	Texture = ReShade::DepthBufferTex;

	// The method used for resolving texture coordinates which are out of bounds.
	// Available values: CLAMP, MIRROR, WRAP or REPEAT, BORDER
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;

	// The magnification, minification and mipmap filtering types.
	// Available values: POINT, LINEAR
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
};


// This is copy of reshade's getLinearizedDepth but using POINT sampling (LINEAR interpolation can cause artefacts - thin ghost of edge one radius away.)
float pointDepth(float2 texcoord)
{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		texcoord.y = 1.0 - texcoord.y;
#endif
		texcoord.x /= RESHADE_DEPTH_INPUT_X_SCALE;
		texcoord.y /= RESHADE_DEPTH_INPUT_Y_SCALE;
#if RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
		texcoord.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
#else // Do not check RESHADE_DEPTH_INPUT_X_OFFSET, since it may be a decimal number, which the preprocessor cannot handle
		texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET / 2.000000001;
#endif
#if RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
		texcoord.y += RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
#else
		texcoord.y += RESHADE_DEPTH_INPUT_Y_OFFSET / 2.000000001;
#endif
		float depth = (float)tex2D(samplerDepth, texcoord);
		return depth;
}


float fixDepth(float depth) {		
		depth *= RESHADE_DEPTH_MULTIPLIER;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		return depth;
}

float4 fixDepth4(float4 depth) {		
		depth *= RESHADE_DEPTH_MULTIPLIER;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		return depth;
}



#ifndef FAKE_GI_WIDTH
	#define FAKE_GI_WIDTH 192
#endif
#ifndef FAKE_GI_HEIGHT
	#define FAKE_GI_HEIGHT 108
#endif

texture GITexture {
    Width = FAKE_GI_WIDTH*2;
    Height = FAKE_GI_HEIGHT*2 ;
    Format = RGBA16F;
	MipLevels=4;
};

sampler GITextureSampler {
    Texture = GITexture;
};


// The blur for Fake GI used to be based on "FGFX::FCSB[16X] - Fast Cascaded Separable Blur" by Alex Tuderan, but I have since replaced the code with my own blur algorithm, which can do a big blur in fewer passes. Still, credit to Alex for ideas - if you're interested in his blur algorithm see: https://github.com/AlexTuduran/FGFX/blob/main/Shaders/FGFXFastCascadedSeparableBlur16X.fx

texture HBlurTex {
    Width = FAKE_GI_WIDTH ;
    Height = FAKE_GI_HEIGHT ;
    Format = RGBA16F;
};

texture VBlurTex {
    Width = FAKE_GI_WIDTH ;
    Height = FAKE_GI_HEIGHT ;
    Format = RGBA16F;
	
};

sampler HBlurSampler {
    Texture = HBlurTex;
};

sampler VBlurSampler {
    Texture = VBlurTex;
};


float4 startGI_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : COLOR
{
	float4 c=0;
	
	c = getBackBufferLinear(texcoord);

	c.rgb=undoTonemap(c.rgb);

	
	//If sky detect is on... we don't want to make tops of buildings blue (or red in sunset) - make sky greyscale
	if(gi_use_depth) {
		float depth = fixDepth(pointDepth(texcoord));					
		if(depth>=1) c.rgb=length(c.rgb); //This is actually a little brighter than the sky - but that works well.
		c.w=depth;
	}
	return c;
}


float4 bigBlur2(sampler s, in float4 pos, in float2 texcoord, in float4 steps  ) {
	
	float2 pixelsize = 1/float2(FAKE_GI_WIDTH,FAKE_GI_HEIGHT);
	float4 color = tex2D(s, texcoord - pixelsize*steps.xy) + tex2D(s, texcoord - pixelsize*steps.zw);
	color       += tex2D(s, texcoord + pixelsize*steps.zw) + tex2D(s, texcoord + pixelsize*steps.xy);
	color *=.25;
	
	return color;
}


float4 bigBlur1_PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float4 result = bigBlur2(GITextureSampler, pos, texcoord, float4(10.5,1.5,3.5,0.5) );
	return result;
}

float4 bigBlur2_PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float4 result = bigBlur2(HBlurSampler, pos, texcoord, float4(-1.5,10.5, -0.5,3.5) );
	return result;
}

float4 bigBlur3_PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float4 result = bigBlur2(VBlurSampler, pos, texcoord, float4(7.5,7.5,2.5,2.5) );
	return result;
}

float4 bigBlur4_PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float4 result = bigBlur2(HBlurSampler, pos, texcoord, float4(-7.5,7.5,-2.5,2.5) );
	return result;
}


//This macro allows us to use a float4x4 like an array of up to 16 floats. Saves registers and enables some efficienies compared to array of floats.
#define AO_MATRIX(a) (ao_point[(a)/4][(a)%4])

	
float3 Glamarye_Fast_Effects_PS(float4 vpos , float2 texcoord : TexCoord, bool gi_path) 
{		
	//centre (original pixel)
	float3 c = getBackBufferLinear(texcoord).rgb;	
		
	//centre pixel depth
	float depth=0;
	
	if(ao_enabled || dof_enabled || debug_mode || depth_detect || sky_detect || gi_use_depth) {
		depth = fixDepth(pointDepth(texcoord));			
	}
	
	// multiplier to convert rgb to perceived brightness	
	static const float3 luma = float3(0.2126, 0.7152, 0.0722);
	
	float3 smoothed = c; //set to c just in case we're not running the next section.


  //skip all processing if in menu or video
  if(!(depth_detect && depth==0) && !(sky_detect && depth == 1) ) { 
	
	float ratio=0;		
	
	if(fxaa_enabled || sharp_enabled || dof_enabled) {
	
		//Average of the four nearest pixels to each diagonal.
		float3 ne = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*float2(.5,.5)).rgb;
		float3 sw = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*float2(-.5,-.5)).rgb;
		float3 se = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*float2(.5,-.5)).rgb;
		float3 nw = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*float2(-.5,.5)).rgb;
				
		// Average of surrounding pixels, both smoothing edges (FXAA) 
		smoothed = (ne+nw)+(se+sw);	
		smoothed = clamp( (smoothed-c)/3, c/2.0, (smoothed/3.0) );	
		
		//Do we have horizontal or vertical line?
		float dy = dot(luma,abs((ne+nw)-(se+sw)));
		float dx = dot(luma,abs((ne+se)-(nw+sw)));
		bool horiz =  dy > dx;
			
		//We will proceed as if line is east to west. If it's north to south then rotate everything by 90 degrees.
		//First we get and approximation of the line of 3 pixels above and below c.
		float3 n2=horiz ? ne+nw : ne+se;
		float3 s2=horiz ? se+sw : nw+sw;
		n2-=c;
		s2-=c;
		
		
		
		//Calculate FXAA before sharpening
		if(fxaa_enabled) {	
			//Get two more pixels further away on the possible line.
			const float dist = 3.5;
			float2 wwpos = horiz ? float2(-dist, 0) : float2(0, +dist) ;
			float2 eepos = horiz ? float2(+dist, 0) : float2(0, -dist) ;
						
			float3 ww = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*wwpos).rgb;	
			float3 ee = getBackBufferLinear( texcoord + BUFFER_PIXEL_SIZE*eepos).rgb;
									
			// We are looking for a step ███▄▄▄▄▄___ which should be smoothed to look like a slope. 
			// We have a diamond of 4 values. We look for the strength of each diagonal. If one is significantly bigger than the other we have a step!
			//       n2
			//ww            ee
			//       s2
							
			float3 d1 = abs((ww-n2)-(ee-s2));
			float3 d2 = abs((ee-n2)-(ww-s2));
						  
				
			// We compare the biggest diff to the total. The bigger the difference the stronger the step shape.
			// Add small constants to avoid blurring where not needed and to avoid divide by zero. 
				
			float3 total_diff = (d1+d2) + .00004;					
			float3 max_diff = max(d1,d2) + .00001 - fxaa_bias*sqrt(smoothed);
							
			//score between 0 and 1
			float score = dot(luma,(max_diff/total_diff)) ;
								
			//ratio of sharp to smoothed
			//If score > 0.5 then smooth. Anything less goes to zero,
			ratio = max( 2*score-1, 0);				
		}
		
		if(sharp_enabled) {
			//sharpen... 
			//float3 sharp_diff = 2*c - n2 - s2;
			float3 sharp_diff = 2*c - .5*(n2 + s2) - clamp(c, min(n2,s2), max(n2,s2)) ;
			
			sharp_diff = ( abs(c-n2)<0.01*sqrt(c)&&abs(c-s2)<0.01*sqrt(c) ) ? 0 : sharp_diff;			
							
			//If pixel will get brighter, reduce strength. Looks better. Don't brighten at all in bright areas, but allow dark areas to get a bit lighter. 			
			sharp_diff = min(sharp_diff, sharp_diff *.5);
							
			// If DOF enabled, we adjust turn down sharpen based on depth.			
			if(dof_enabled) {
				sharp_diff *= 1-depth;
			}
						
			// if sharpenning is disabled, apply a little bit where FXAA happens to compensate for the blur it tends to add.
			// or keep it simple for now...
			//float sharp_ratio = sharp_strength ;			
			//if(!sharp_enabled)  sharp_ratio = ratio/2;
			
			//apply sharpen, but limit max change. 
			c = lerp(c,clamp(c+sharp_diff, c*0.75,c*1.25), sharp_strength ) ;			
			
		}
	  		
		//Now apply FXAA after sharpening		
		c = lerp(c, smoothed, ratio);	
		
		//Now apply DOF blur, based on depth. Limit the change % to minimize artefacts on near/far edges.
		if(dof_enabled) { 			
			c=lerp(c, clamp(smoothed,c*.66,c*1.5), dof_strength*depth);			
		}		  
	}
	
	float ao = 0;
		
	//prevent AO affecting areas that are white - saturated light areas. These are probably clouds or explosions and shouldn't be shaded.
	float smoke_fix=max(0,(1-reduce_ao_in_light_areas*length(c)));
	
	const float shape = ao_shape_modifier*1.1920928955078125e-07F; 		
	
	//If bounce lighting isn't enabled we actually pretend it is using c*smoothed to get better colour in bright areas (otherwise shade can be too deep or too grey.)
	float3 bounce=smoothed*normalize(c);
		
	float4 gi=0;
	if(gi_path) {
		//tone map fix helps with brighter areas.
		c=undoTonemap(c);
		smoothed=undoTonemap(smoothed);
		bounce=smoothed*normalize(c);
		
		float4 bounce_area = tex2Dlod(GITextureSampler, float4(texcoord.x,texcoord.y, 0, 2.5));		
		if(gi_use_depth) {
			//local area enhanced AO
			float abs_diff = abs(depth-bounce_area.w);
			if( abs_diff>shape*2) ao += gi_local_ao_strength*.1*sign(depth-bounce_area.w);
		}
	
		float2 gi_adjust_vector=0;
		
		if(gi_use_depth) {
			// We want to sample GI colour a little bit in the direction of the normal
			float4 local_slope = float4(ddx(depth), ddy(depth), 0.1*BUFFER_PIXEL_SIZE);
			
			gi_adjust_vector = normalize(local_slope).xy*gi_shape;
			
		}
		gi = tex2D(VBlurSampler, texcoord+gi_adjust_vector);		
		
		//Area brightness	
		//why not use dot(luma,gi.rgb) to get luminance? I tried and min+max works better.
		float gi_bright = max(gi.r,max(gi.g,gi.b)) + min(gi.r,min(gi.g,gi.b));
				
		if(gi_use_depth) { // calculate local bounce.
							
			//Estimate amount of white light hitting area
			float light = gi_bright+.005;			
										
			// Estimate base unlit colour of c
			float3 unlit_c2 = c/light;
										
			//We take our bounce light and multiply it by base unlit colour of c to get amount reflected from c.			
			bounce=lerp(bounce, unlit_c2*max(0,2*bounce_area.rgb-c), bounce_multiplier);	
		}
		
	
		// Fake Global Illumination - 2D, no depth. Works better than you might expect!
	
		//Local brightness
		float smooth_bright = max(smoothed.r,max(smoothed.g,smoothed.b)) + min(smoothed.r,min(smoothed.g,smoothed.b));
		
		
		//estimate ambient light hitting pixel as blend between local and area brighness.
		float ambient=lerp(gi_bright,smooth_bright,.5);
				
		//Estimate of actual colour of c, before direct lighting landed on it.
		float3 unlit_c = c/ambient;		
		
		//Reduce saturation of gi - otherwise colours like red can become far to strong.
		float3 desaturated_gi = lerp((float3)length(gi.rgb)/sqrt(2),gi.rgb, length(gi.rgb*gi_saturation)/length(c*(1-gi_saturation)+gi.rgb*gi_saturation));
		
		//Now calcule amount of light bouncing off current pixel. multiplier comes from experimentation to balance overall colour
		float3 gi_bounce = unlit_c * 2 * desaturated_gi;	
				
		float gi_ratio = 1;
		if(gi_use_depth || sky_detect) gi_ratio -= depth*depth;
				
		float contrast = max(sqrt(2*length(c)/length(bounce_area.rgb+gi.rgb)),.75);
		
		float gi_length = clamp(length(min((gi.rgb+c+c-smoothed)/2,gi_bounce) ), length(c), 1.5*length(c));
		
		c = lerp(c, (normalize(gi_bounce) * gi_length) , gi_strength*gi_ratio);
		
		c = c*lerp(1, contrast, gi_contrast);		
	}
	
	//Fast screen-space ambient occlusion. It does a good job of shading concave corners facing the camera, even with few samples.
	//depth check is to minimize performance impact areas beyond our max distance, or on games that don't give us depth, if AO left on by mistake.	
	if( ao_enabled && depth>0 && depth<ao_fog_fix ) {
		
		// Checkerboard pattern of 1s and 0s ▀▄▀▄▀▄. Single layer of dither works nicely to allow us to use 2 radii without doubling the samples per pixel. More complex dither patterns are noticable and annoying.
		uint square =  (uint(vpos.x+vpos.y)) % 2;
		
		uint i; //loop counter
		
		// Get circle of depth samples.	
		float2 the_vector;
	
		const uint points = clamp(FAST_AO_POINTS,2, 16);
		float4x4 ao_point ;
		ao_point[0]=0;
		ao_point[1]=0;
		ao_point[2]=0;
		ao_point[3]=0;
		
		//This is the angle between the same point on adjacent pixels, or half the angle between adjacently points on this pixel.		
		const float angle = radians(180)/points;		
		
		
		//This seems weird, but it improves performance more than reducing points by 1! Negligible impact on image (unless you set a very small radius).
		//Reason: GPUs process pixels in groups of 4. By making each group share a centre we make some of depth samples the same between opposites. By reading fewer distinct points overall we improve cache performance. 
		texcoord = (floor((vpos.xy)/2)*2+0.5)*BUFFER_PIXEL_SIZE;
		
		
		float the_vector_len=ao_radius * (1-depth*.8);	
		
		[unroll]		
		for(i = 0; i< points; i++) {							
			// distance of points is either ao_radius or ao_radius*.4 (distance depending on position in checkerboard.)
			// We want (i*2+square)*angle, but this is a trick to help the optimizer generate constants instead of trig functions.
			// Also, note, for points < 5 we reduce larger radius a bit - with few points we need more precision near centre.	
			
			float2 outer_circle = (min(.002*points,.01)) /normalize(BUFFER_SCREEN_SIZE)*float2( sin((i*2+.5)*angle), cos((i*2+.5)*angle) );
			float2 inner_circle =                   .004 /normalize(BUFFER_SCREEN_SIZE)*float2( sin((i*2-.5)*angle), cos((i*2-.5)*angle) );
				
			the_vector = the_vector_len * (!square ? inner_circle : outer_circle);
			
			//Get the depth at each point - must use POINT sampling, not LINEAR to avoid ghosting artefacts near object edges.			
			AO_MATRIX(i) = pointDepth( texcoord+the_vector);
		}
		
		
		
		float max_depth = depth+0.01*ao_max_depth_diff;
		float min_depth_sq = sqrt(depth)-0.01*ao_max_depth_diff;
		min_depth_sq *=  min_depth_sq;
		
		float4x4 adj_point;
		adj_point[0]=0;
		adj_point[1]=0;
		adj_point[2]=0;
		adj_point[3]=0;
		
		[unroll]
		for(i = 0 ; i<(points+3)/4; i++) {
			ao_point[i] = fixDepth4(ao_point[i]);
			ao_point[i] = (ao_point[i] < min_depth_sq) ? -depth : min(ao_point[i], max_depth);
		}
			
		float4x4 opposite;
		if(FAST_AO_POINTS==8) {
			opposite[0] = ao_point[1];
			opposite[1] = ao_point[0];
		}		
		else if(FAST_AO_POINTS==4) {
			opposite[0] = ao_point[0].barg;			
		}
		else {
			[unroll]
			for(i = 0; i<points; i++) {
				//If AO_MATRIX(i) is much closer than depth then it's a different object and we don't let it cast shadow - instead predict value based on opposite point(s) (so they cancel out).
				opposite[i/4][i%4] = AO_MATRIX((i+points/2)%points);
				if(points%2) opposite[i/4][i%4] = (opposite[i/4][i%4] + AO_MATRIX((1+i+points/2)%points) ) /2;			
			}
		}
		[unroll]
		for(i = 0 ; i<(points+3)/4; i++) {
			ao_point[i] = (ao_point[i] >= 0) ? ao_point[i] : depth*2-abs(opposite[i]);			
		}
		
		
		if(FAST_AO_POINTS==8) {
			adj_point[0].yzw = ao_point[0].xyz;			
			adj_point[1].yzw = ao_point[1].xyz;
			adj_point[0].x = ao_point[1].w;			
			adj_point[1].x = ao_point[0].w;
		}
		else if(FAST_AO_POINTS==4) {
			adj_point[0] = ao_point[0].wxyz;			
		} else {
			adj_point[i-1]=ao_point[i-1];  //For not 4 nor 8 initialize to the same we don't mess up the variance.
			[unroll]
			for(i = 0; i<points; i++) {
				adj_point[i/4][i%4] = AO_MATRIX((i+1)%points);
			}
		}	
								
		//Now estimate the local variation - sum of differences between adjacent points.
			
		//This uses fewer instruction but causes a compiler warning. I'm going with the clearer loop below.
		//float variance = dot(mul((ao_point[i]-adj_point[i])*(ao_point[i]-adj_point[i]),float4(1,1,1,1)),float4(1,1,1,1)/(2*points));
		
		float4 variance = 0; 
		
		for(i = 0 ; i<(points+3)/4; i++) {
			variance += (ao_point[i]-adj_point[i])*(ao_point[i]-adj_point[i]);						
		}		
		
		variance = sqrt(dot(variance, float4(1,1,1,1)/(2*points)));
		
		// Minimum difference in depth - this is to prevent shading areas that are only slighly concave.		
		variance += shape;
		
		float4 ao4=0;
		
		[unroll]
		for(i = 0 ; i<(points)/4; i++) {
					
			float4 near=min(ao_point[i],adj_point[i]); 
			float4 far=max(ao_point[i],adj_point[i]); 
			
			//This is the magic that makes shaded areas smoothed instead of band of equal shade. If both points are in front, but one is only slightly in front (relative to variance) then 
			near -= variance;
			far  += variance;
				
			//Linear interpolation - 
			float4 crossing = (depth-near)/(far-near);
				
			//If depth is between near and far, crossing is between 0 and 1. If not, clamp it. Then adjust it to be between -1 and +1.
			crossing = 2*clamp(crossing,0,1)-1;
				
			ao4 += crossing;
		}
		if(points%4) {
			float4 near=min(ao_point[i],adj_point[i]); 
			float4 far=max(ao_point[i],adj_point[i]); 
			
				
			//This is the magic that makes shaded areas smoothed instead of band of equal shade. If both points are in front, but one is only slightly in front (relative to variance) then 
			near -= variance;
			far  += variance;
				
			//Linear interpolation - 
			float4 crossing = (depth-near)/(far-near);
				
			//If depth is between near and far, crossing is between 0 and 1. If not, clamp it. Then adjust it to be between -1 and +1.
			crossing = 2*clamp(crossing,0,1)-1;
			
			if(points%4==3) crossing.w=0;
			else if(points%4==2) crossing.zw=0;
			else if(points%4==1) crossing.yzw=0;
				
			ao4 += crossing;
		}
		
		//Because of our checkerboard pattern it can be too dark in the inner_circle and create a noticable step. This softens the inner circle (which will be darker anyway because outer_circle is probably dark too.)
		if(!square || points==2) ao4 *=(2.0/3.0);
		
		ao += dot(ao4, float4(1,1,1,1)/points);	
	}
	
	//debug Show ambient occlusion mode
	if(debug_mode==2 ) c=.25;
	
	//Weaken the AO effect if depth is a long way away. This is to avoid artefacts when there is fog/haze/darkness in the distance.	
	float fog_fix_multiplier = clamp((1-depth/ao_fog_fix)*2,0,1 );	
	
	if(gi_path && gi_use_depth && depth) {
			float depth_ratio = ((gi.w)/(depth));			
			depth_ratio=clamp(depth_ratio,1-depth_ratio,1); //reduce effect if ratio < .5 (i.e pixel is more than twice the area depth.)
			
			c = lerp(c, c*depth_ratio, gi_ao_strength*fog_fix_multiplier*smoke_fix); 						
	}
	
	ao = ao*fog_fix_multiplier;	
	
	//If ao is negative it's an exposed area to be brightened (or set to 0 if shine is off).
	if (ao<0) {
		ao*=ao_shine_strength*.5;			
		ao*=smoke_fix;
		
		c=c*(1-ao);
	}
	else if(ao>0) {
		bounce = bounce*ao_strength*min(ao,.5);
	
		ao *= ao_strength*1.8; // multiply to compensate for the bounce value we're adding
		
		bounce = min(c*ao,bounce); // Make sure bounce doesn't make pixel brighter than original.
		
		ao*=smoke_fix;
		
		//apply AO and clamp the pixel to avoid going completely black or white. 
		c = clamp( c*(1-ao) + bounce,  0.25*c, c  );
	}
	
	if(gi_path) {
		c=reapplyTonemap(c);
		
		//Show GI light
		if(debug_mode==5) c=gi.rgb;	
		
		//These were used in development are aren't really useful for users. KISS
		//if(debug_mode==6) c=bounce;
		//if(debug_mode==7) c=(bounce_area.rgb+gi.rgb)/2;
		//if(debug_mode==8) c= contrast*.2;
		//if(debug_mode==9) c=depth_ratio*.25;
		//if(debug_mode==10) c=gi.w;		
	}
	
	// Debug mode: make the smoothed option more highlighted in green.		
					
	if(debug_mode==1)	c = lerp(c.ggg, float3(0,1,0), ratio*ratio);	
	if(debug_mode==4)	c = lerp(depth, float3(0,1,0), ratio*ratio);	
	
  }
  
  
  
  //Show depth buffer mode
  if(debug_mode == 3) c = depth ; 
    
  c.rgb = toOutputFormat(c);
  
  return c;
}

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}



float3 Glamarye_Fast_Effects_all_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return  Glamarye_Fast_Effects_PS(vpos,  texcoord, true);
}

float3 Glamarye_Fast_Effects_without_Fake_GI_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return  Glamarye_Fast_Effects_PS(vpos,  texcoord, false);
}



technique Glamarye_Fast_Effects_with_Fake_GI <
	ui_tooltip = "Designed for speed, it combines multiple effects in one shader. Higher quality effects exist, but not this fast. \nThe aim is to look good enough without destoying your framerate. If you turn off your game's built-in post-processing options and use these instead you may even get a higher framerate!\n"
				 "\nBasic effects:\n"
				 "1. FXAA. Fixes jagged edges. \n"
				 "2. Intelligent Sharpening. \n"				 
				 "3. Ambient occlusion. Shades areas that receive less ambient light. It can optionally brighten exposed shapes too, making the image more vivid (AO shine setting).\n"				 
				 "4. Subtle Depth of Field. Softens distant objects.\n"
				 "5. Detect Menus and Videos. Disables effects when not in-game.\n"
				 "6. Detect Sky. Disable effects for background images behind the 3D world\n"
				 "\nFake Global Illumination effects:\n"
				 " (these attempts to look like fancy GI shaders but using very simple approximations. Not as realistic, but very fast.)\n"
				 "1. Indirect lighting. Pixels take colour from the surrounding area (depth optional!)\n"
				 "2. Adaptive contrast enhancement. Enhances clarity.\n"
				 "3. Large scale ambient occlusion. Big area but very soft.\n"
				 "4. Local bounce light. Enhances ambient occlusion, adding colour to it.\n";

	>
{	
	pass makeGI
	{
		VertexShader = PostProcessVS;
		PixelShader = startGI_PS;
		RenderTarget = GITexture;		
	}	

	pass  {
        VertexShader = PostProcessVS;
        PixelShader  = bigBlur1_PS;
        RenderTarget = HBlurTex;
    }
	
    pass  {
        VertexShader = PostProcessVS;
        PixelShader  = bigBlur2_PS;
        RenderTarget = VBlurTex;
    }
	
	pass  {
        VertexShader = PostProcessVS;
        PixelShader  = bigBlur3_PS;
        RenderTarget = HBlurTex;
    }
	
    pass  {
        VertexShader = PostProcessVS;
        PixelShader  = bigBlur4_PS;
        RenderTarget = VBlurTex;
    }
		
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Glamarye_Fast_Effects_all_PS;
				
		// SDR or HDR mode?
#if BUFFER_COLOR_BIT_DEPTH > 8
			SRGBWriteEnable = false;
#else
			SRGBWriteEnable = true;
#endif
	}	

	
}

technique Glamarye_Fast_Effects_without_Fake_GI <
	ui_tooltip = "Designed for speed, it combines multiple effects in one shader. Higher quality effects exist, but not this fast. \nThe aim is to look good enough without destoying your framerate. If you turn off your game's built-in post-processing options and use these instead you may even get a higher framerate!\n"
				 "\nBasic effects:\n"
				 "1. FXAA. Fixes jagged edges. \n"
				 "2. Intelligent Sharpening. \n"				 
				 "3. Ambient Occlusion. Shades areas that receive less ambient light. It can optionally brighten exposed shapes too, making the image more vivid (AO shine setting).\n"				 
				 "4. Subtle Depth of Field. Softens distant objects.\n"
				 "5. Detect Menus and Videos. Disables effects when not in-game.\n"
				 "6. Detect Sky. Disable effects for background images behind the 3D world\n."
				 "This version does not include the Fake GI effects, therefore is faster than the full version.\n";
	>
{	
	pass Glamayre
	{
		VertexShader = PostProcessVS;
		PixelShader = Glamarye_Fast_Effects_without_Fake_GI_PS;
				
		// SDR or HDR mode?
#if BUFFER_COLOR_BIT_DEPTH > 8
			SRGBWriteEnable = false;
#else
			SRGBWriteEnable = true;
#endif
	}		
	
}




//END OF NAMESPACE
}
