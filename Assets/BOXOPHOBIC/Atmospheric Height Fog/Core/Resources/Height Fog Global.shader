// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Hidden/BOXOPHOBIC/Atmospherics/Height Fog Global"
{
	Properties
	{
		[HideInInspector]_HeightFogGlobal("_HeightFogGlobal", Float) = 1
		[HideInInspector]_IsHeightFogShader("_IsHeightFogShader", Float) = 1
		[HideInInspector]_IsStandardPipeline("_IsStandardPipeline", Float) = 1
		[HideInInspector]_TransparentQueue("_TransparentQueue", Int) = 3000
		[BBanner(Height Fog, Global)]_TITLE("< TITLE >", Float) = 1
	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Overlay" "Queue"="Overlay" }
		LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		ColorMask RGBA
		ZWrite Off
		ZTest Always
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" "PreviewType"="Skybox" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityStandardBRDF.cginc"
			#pragma multi_compile AHF_DIRECTIONALMODE_OFF AHF_DIRECTIONALMODE_ON
			#pragma multi_compile AHF_NOISEMODE_OFF AHF_NOISEMODE_PROCEDURAL3D


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
			};

			//This is a late directive
			
			uniform half _IsHeightFogShader;
			uniform half _HeightFogGlobal;
			uniform half _IsStandardPipeline;
			uniform half _TITLE;
			uniform int _TransparentQueue;
			uniform half4 AHF_FogColor;
			uniform half4 AHF_DirectionalColor;
			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
			uniform float4 _CameraDepthTexture_TexelSize;
			uniform half AHF_DirectionalIntensity;
			uniform half AHF_DirectionalModeBlend;
			uniform half AHF_FogDistanceStart;
			uniform half AHF_FogDistanceEnd;
			uniform half AHF_FogHeightEnd;
			uniform half AHF_FogHeightStart;
			uniform half AHF_NoiseScale;
			uniform half3 AHF_NoiseSpeed;
			uniform half AHF_NoiseDistanceEnd;
			uniform half AHF_NoiseIntensity;
			uniform half AHF_NoiseModeBlend;
			uniform half AHF_SkyboxFogHeight;
			uniform half AHF_SkyboxFogFill;
			uniform half AHF_FogIntensity;
			float2 UnStereo( float2 UV )
			{
				#if UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex];
				UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
				#endif
				return UV;
			}
			
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			
			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord = screenPos;
				float3 ase_worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.ase_texcoord1.xyz = ase_worldPos;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.w = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				float3 temp_output_2_0_g753 = (AHF_FogColor).rgb;
				float3 gammaToLinear3_g753 = GammaToLinearSpace( temp_output_2_0_g753 );
				#ifdef UNITY_COLORSPACE_GAMMA
				float3 staticSwitch1_g753 = temp_output_2_0_g753;
				#else
				float3 staticSwitch1_g753 = gammaToLinear3_g753;
				#endif
				float3 temp_output_893_0 = staticSwitch1_g753;
				float3 temp_output_2_0_g752 = (AHF_DirectionalColor).rgb;
				float3 gammaToLinear3_g752 = GammaToLinearSpace( temp_output_2_0_g752 );
				#ifdef UNITY_COLORSPACE_GAMMA
				float3 staticSwitch1_g752 = temp_output_2_0_g752;
				#else
				float3 staticSwitch1_g752 = gammaToLinear3_g752;
				#endif
				float4 screenPos = i.ase_texcoord;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 UV38_g726 = ase_screenPosNorm.xy;
				float2 localUnStereo38_g726 = UnStereo( UV38_g726 );
				float2 break6_g726 = localUnStereo38_g726;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float clampDepth3_g725 = SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_grabScreenPosNorm.xy );
				float ifLocalVar7_g725 = 0;
				UNITY_BRANCH 
				if( _ProjectionParams.x > 0.0 )
				ifLocalVar7_g725 = ( 1.0 - clampDepth3_g725 );
				else if( _ProjectionParams.x < 0.0 )
				ifLocalVar7_g725 = clampDepth3_g725;
				#ifdef UNITY_REVERSED_Z
				float staticSwitch9_g725 = ifLocalVar7_g725;
				#else
				float staticSwitch9_g725 = ( 1.0 - ifLocalVar7_g725 );
				#endif
				float RawDepth209 = staticSwitch9_g725;
				float temp_output_41_0_g726 = RawDepth209;
				#ifdef UNITY_REVERSED_Z
				float staticSwitch5_g726 = ( 1.0 - temp_output_41_0_g726 );
				#else
				float staticSwitch5_g726 = temp_output_41_0_g726;
				#endif
				float3 appendResult11_g726 = (float3(break6_g726.x , break6_g726.y , staticSwitch5_g726));
				float4 appendResult16_g726 = (float4((appendResult11_g726*2.0 + -1.0) , 1.0));
				float4 break18_g726 = mul( unity_CameraInvProjection, appendResult16_g726 );
				float3 appendResult19_g726 = (float3(break18_g726.x , break18_g726.y , break18_g726.z));
				float4 appendResult27_g726 = (float4(( ( appendResult19_g726 / break18_g726.w ) * half3(1,1,-1) ) , 1.0));
				float4 break30_g726 = mul( unity_CameraToWorld, appendResult27_g726 );
				float3 appendResult31_g726 = (float3(break30_g726.x , break30_g726.y , break30_g726.z));
				float3 WorldPosition144 = appendResult31_g726;
				float3 normalizeResult5_g748 = normalize( ( WorldPosition144 - _WorldSpaceCameraPos ) );
				float3 ase_worldPos = i.ase_texcoord1.xyz;
				float3 worldSpaceLightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(ase_worldPos));
				float dotResult6_g748 = dot( normalizeResult5_g748 , worldSpaceLightDir );
				float temp_output_7_0_g749 = -1.0;
				half DirectionalMask134 = ( ( ( dotResult6_g748 - temp_output_7_0_g749 ) / ( 1.0 - temp_output_7_0_g749 ) ) * AHF_DirectionalIntensity * AHF_DirectionalModeBlend );
				float3 lerpResult135 = lerp( temp_output_893_0 , staticSwitch1_g752 , DirectionalMask134);
				#if defined(AHF_DIRECTIONALMODE_OFF)
				float3 staticSwitch241 = temp_output_893_0;
				#elif defined(AHF_DIRECTIONALMODE_ON)
				float3 staticSwitch241 = lerpResult135;
				#else
				float3 staticSwitch241 = temp_output_893_0;
				#endif
				float temp_output_7_0_g736 = AHF_FogDistanceStart;
				half FogDistanceMask186 = saturate( ( ( distance( WorldPosition144 , _WorldSpaceCameraPos ) - temp_output_7_0_g736 ) / ( AHF_FogDistanceEnd - temp_output_7_0_g736 ) ) );
				float temp_output_7_0_g734 = AHF_FogHeightEnd;
				half FogHeightMask193 = saturate( ( ( (WorldPosition144).y - temp_output_7_0_g734 ) / ( AHF_FogHeightStart - temp_output_7_0_g734 ) ) );
				float temp_output_115_0 = ( FogDistanceMask186 * FogHeightMask193 );
				float simplePerlin3D15_g737 = snoise( ( ( WorldPosition144 * ( 1.0 / AHF_NoiseScale ) ) + ( -AHF_NoiseSpeed * _Time.y ) ) );
				float temp_output_7_0_g740 = -1.0;
				float temp_output_7_0_g731 = AHF_NoiseDistanceEnd;
				half NoiseDistanceMask353 = saturate( ( ( distance( WorldPosition144 , _WorldSpaceCameraPos ) - temp_output_7_0_g731 ) / ( 0.0 - temp_output_7_0_g731 ) ) );
				float lerpResult20_g737 = lerp( 1.0 , ( ( simplePerlin3D15_g737 - temp_output_7_0_g740 ) / ( 1.0 - temp_output_7_0_g740 ) ) , ( NoiseDistanceMask353 * AHF_NoiseIntensity * AHF_NoiseModeBlend ));
				half NoiseSimplex3D234 = lerpResult20_g737;
				#if defined(AHF_NOISEMODE_OFF)
				float staticSwitch242 = temp_output_115_0;
				#elif defined(AHF_NOISEMODE_PROCEDURAL3D)
				float staticSwitch242 = ( temp_output_115_0 * NoiseSimplex3D234 );
				#else
				float staticSwitch242 = temp_output_115_0;
				#endif
				float3 normalizeResult8_g744 = normalize( WorldPosition144 );
				float temp_output_7_0_g746 = AHF_SkyboxFogHeight;
				float lerpResult17_g744 = lerp( saturate( ( ( abs( (normalizeResult8_g744).y ) - temp_output_7_0_g746 ) / ( 0.0 - temp_output_7_0_g746 ) ) ) , 1.0 , AHF_SkyboxFogFill);
				half SkyboxFogHeightMask197 = lerpResult17_g744;
				float temp_output_6_0_g743 = RawDepth209;
				#ifdef UNITY_REVERSED_Z
				float staticSwitch11_g743 = temp_output_6_0_g743;
				#else
				float staticSwitch11_g743 = ( 1.0 - temp_output_6_0_g743 );
				#endif
				half SkyboxMask83 = ( 1.0 - ceil( staticSwitch11_g743 ) );
				float lerpResult85 = lerp( staticSwitch242 , SkyboxFogHeightMask197 , SkyboxMask83);
				float4 appendResult384 = (float4(staticSwitch241 , ( lerpResult85 * AHF_FogIntensity )));
				
				
				finalColor = appendResult384;
				return finalColor;
			}
			ENDCG
		}
	}
	
	
	
}
/*ASEBEGIN
Version=17101
0;30;720;273;2250.81;3748.13;1;True;False
Node;AmplifyShaderEditor.FunctionNode;915;-3328,-2688;Inherit;False;Get Depth;-1;;725;94fe910b0bea40c44a4ef451e42f5dcc;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;209;-2496,-2688;Float;False;RawDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;325;-3328,-1920;Inherit;False;209;RawDepth;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;911;-3072,-1920;Inherit;False;Get World Position From Depth;-1;;726;291af7f0f34d2754094ada4911a047c7;0;1;41;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;144;-2496,-1920;Float;False;WorldPosition;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;626;-3328,0;Inherit;False;144;WorldPosition;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;909;-3072,0;Inherit;False;Fog Noise Distance;-1;;730;b49331aa561bee84c8546167a63b6b58;0;1;18;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;189;-3328,-768;Inherit;False;144;WorldPosition;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;573;-3328,-1152;Inherit;False;144;WorldPosition;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;353;-2528,0;Half;False;NoiseDistanceMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;904;-3072,-768;Inherit;False;Fog Height;-1;;733;61a3ca69e0854664d87b5233acc9cbae;0;1;8;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;910;-3328,464;Inherit;False;353;NoiseDistanceMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;217;-3328,384;Inherit;False;144;WorldPosition;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;903;-3072,-1152;Inherit;False;Fog Distance;-1;;735;a5f090963b8f9394a984ee752ce42488;0;1;13;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;193;-2512,-768;Half;False;FogHeightMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;908;-3008,384;Inherit;False;Fog Noise;-1;;737;fe51dc291bbca2147aa47de2202288d1;0;2;22;FLOAT3;0,0,0;False;23;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;186;-2512,-1152;Half;False;FogDistanceMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;194;-3328,-3504;Inherit;False;193;FogHeightMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;177;-3328,-2304;Inherit;False;209;RawDepth;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;234;-2512,384;Half;False;NoiseSimplex3D;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;188;-3328,-3584;Inherit;False;186;FogDistanceMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;191;-3328,-384;Inherit;False;144;WorldPosition;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;179;-3328,-1536;Inherit;False;144;WorldPosition;1;0;OBJECT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;900;-3072,-2304;Inherit;False;Get Skybox Mask From Depth;-1;;743;e5ec8c46f59f8d945ae6dea4b02558d2;0;1;6;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;-3072,-3584;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;102;-3328,-3904;Half;False;Global;AHF_DirectionalColor;AHF_DirectionalColor;12;0;Create;False;0;0;False;0;1,0.6300203,0.1617647,0;0.5471698,0.5471698,0.5471698,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;137;-3328,-4096;Half;False;Global;AHF_FogColor;AHF_FogColor;4;0;Create;False;0;0;False;0;0.4411765,0.722515,1,0;0.9987262,0.9987262,0.9987262,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;905;-3072,-384;Inherit;False;Fog Skybox Height;-1;;744;6d26cce249abb074ab51f8986da282cb;0;1;19;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;902;-3072,-1536;Inherit;False;Fog Directional;-1;;748;b76195d9ca3254b49ac2428d15088cd6;0;1;15;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;250;-3328,-3424;Inherit;False;234;NoiseSimplex3D;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;197;-2560,-384;Half;False;SkyboxFogHeightMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;276;-2880,-3456;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;134;-2512,-1536;Half;False;DirectionalMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;862;-3072,-4096;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;83;-2496,-2304;Half;False;SkyboxMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;863;-3072,-3904;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;242;-2688,-3584;Float;False;Property;AHF_NoiseMode;AHF_NoiseMode;14;0;Create;False;0;0;False;0;1;0;0;False;;KeywordEnum;2;Off;Procedural3D;Create;False;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;198;-2432,-3456;Inherit;False;197;SkyboxFogHeightMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;136;-3328,-3712;Inherit;False;134;DirectionalMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;886;-2432,-3328;Inherit;False;83;SkyboxMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;894;-2880,-3904;Inherit;False;Handle Color Space;-1;;752;f6f44b689bae74d47a0885dbe3018c48;0;1;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;893;-2880,-4096;Inherit;False;Handle Color Space;-1;;753;f6f44b689bae74d47a0885dbe3018c48;0;1;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;135;-2368,-3968;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;278;-1912,-3457;Half;False;Global;AHF_FogIntensity;AHF_FogIntensity;3;1;[HideInInspector];Create;False;0;0;False;0;0.04;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;85;-2048,-3584;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;277;-1600,-3584;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;241;-2176,-4096;Float;False;Property;AHF_DirectionalMode;AHF_DirectionalMode;11;0;Create;False;0;0;False;0;1;0;0;False;;KeywordEnum;2;Off;On;Create;False;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.IntNode;891;-2624,-4736;Float;False;Property;_TransparentQueue;_TransparentQueue;3;1;[HideInInspector];Create;False;0;0;True;0;3000;0;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;892;-3328,-4864;Half;False;Property;_TITLE;< TITLE >;4;0;Create;True;0;0;True;1;BBanner(Height Fog, Global);1;1;1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;384;-1408,-4096;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;913;-2864,-4736;Half;False;Property;_IsStandardPipeline;_IsStandardPipeline;2;1;[HideInInspector];Create;False;0;0;True;0;1;1;1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;879;-3328,-4736;Half;False;Property;_HeightFogGlobal;_HeightFogGlobal;0;1;[HideInInspector];Create;False;0;0;True;0;1;1;1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;885;-3104,-4736;Half;False;Property;_IsHeightFogShader;_IsHeightFogShader;1;1;[HideInInspector];Create;False;0;0;True;0;1;1;1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;383;-1152,-4096;Float;False;True;2;;0;1;Hidden/BOXOPHOBIC/Atmospherics/Height Fog Global;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;5;False;-1;10;False;-1;True;0;False;-1;0;False;-1;True;False;True;2;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;594;True;7;False;595;True;False;0;False;500;1000;False;500;True;2;RenderType=Overlay=RenderType;Queue=Overlay=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;2;LightMode=ForwardBase;PreviewType=Skybox;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;0
Node;AmplifyShaderEditor.CommentaryNode;190;-3328,-1280;Inherit;False;1024.136;100;Fog Distance;0;;0,0.5882353,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;180;-3328,-1664;Inherit;False;1021.744;100;Directional Light Support;0;;1,0.634,0.1617647,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;178;-3328,-2432;Inherit;False;1024.071;103;Skybox Mask;0;;0.8308824,0.1405169,0.1405169,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;235;-3328,256;Inherit;False;1029.327;100;Noise;0;;0.7529412,1,0.7529412,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;199;-3328,-512;Inherit;False;1029.083;100;Skybox Fog Height;0;;0,0.5882354,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;174;-3328,-2048;Inherit;False;1024.042;100;World Position from Depth;0;;0,1,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;354;-3328,-128;Inherit;False;1025.267;100;Noise Distance Mask;0;;0.7529412,1,0.7529412,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;215;-3328,-2816;Inherit;False;1022.231;100;Depth Texture;0;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;880;-3328,-4992;Inherit;False;919.8825;100;Drawers;0;;1,0.475862,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;612;-3328,-4224;Inherit;False;2360.925;100;Final Pass;0;;0.497,1,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;196;-3328,-896;Inherit;False;1026.06;100;Fog Height;0;;0,0.5882353,1,1;0;0
WireConnection;209;0;915;0
WireConnection;911;41;325;0
WireConnection;144;0;911;0
WireConnection;909;18;626;0
WireConnection;353;0;909;0
WireConnection;904;8;189;0
WireConnection;903;13;573;0
WireConnection;193;0;904;0
WireConnection;908;22;217;0
WireConnection;908;23;910;0
WireConnection;186;0;903;0
WireConnection;234;0;908;0
WireConnection;900;6;177;0
WireConnection;115;0;188;0
WireConnection;115;1;194;0
WireConnection;905;19;191;0
WireConnection;902;15;179;0
WireConnection;197;0;905;0
WireConnection;276;0;115;0
WireConnection;276;1;250;0
WireConnection;134;0;902;0
WireConnection;862;0;137;0
WireConnection;83;0;900;0
WireConnection;863;0;102;0
WireConnection;242;1;115;0
WireConnection;242;0;276;0
WireConnection;894;2;863;0
WireConnection;893;2;862;0
WireConnection;135;0;893;0
WireConnection;135;1;894;0
WireConnection;135;2;136;0
WireConnection;85;0;242;0
WireConnection;85;1;198;0
WireConnection;85;2;886;0
WireConnection;277;0;85;0
WireConnection;277;1;278;0
WireConnection;241;1;893;0
WireConnection;241;0;135;0
WireConnection;384;0;241;0
WireConnection;384;3;277;0
WireConnection;383;0;384;0
ASEEND*/
//CHKSM=1E423FC31BDA627BC2F563649CFCDC50F2EB4799