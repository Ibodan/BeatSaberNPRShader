Shader "BeatSaberNPR/AlphaOutline"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		[NoScaleOffset] _Tex ("Texture", 2D) = "white" {}
		_ShadeColor ("Shade Color", Color) = (0.4, 0.4, 0.4, 1)
		_Ambient ("Shade Offset", Range (0, 1)) = 1
		_ShadeEdge ("Shade Edge", Range (1, 10)) = 1
		_LightDir ("Light Direction", Vector) = (0,-1,-1,1)
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_OutlineWidth ("Outline Width", float) = 0.00000003
		[KeywordEnum(NO, ADD, MULTIPLY)] _UseSphere("Use MMDSphere?", Int) = 0
		[NoScaleOffset] _SphereTex ("MMDSphere", CUBE) = "" {}
		[Toggle(USE_EMISSION)] _UseEmission("Use Emission?", Int) = 0
		[NoScaleOffset] _EmissionMask ("Emission Mask", 2D) = "white" {}
		_EmissionColor ("Emission Color", Color) = (0,0,0,1)
		[KeywordEnum(None, Front, Back)] _Cull("Culling", Int) = 2
		[KeywordEnum(Zero, One)] _DstAlpha("Blooms Visibile Through", Int) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="AlphaTest" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha, Zero [_DstAlpha]
			Cull [_Cull]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _USESPHERE_NO
			#pragma shader_feature _USESPHERE_ADD
			#pragma shader_feature _USESPHERE_MULTIPLY
			#pragma shader_feature USE_EMISSION

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float shadow : TEXCOORD1;
				#if _USESPHERE_ADD || _USESPHERE_MULTIPLY
				float3 sphereCoord : TEXCOORD2;
				#endif
			};

			float4 _Color;
			float _Ambient;
			float4 _LightDir;
			float4 _ShadeColor;
			float _ShadeEdge;

			sampler2D _Tex;
			#if _USESPHERE_ADD || _USESPHERE_MULTIPLY
			samplerCUBE _SphereTex;
			#endif
			#if USE_EMISSION
			sampler2D _EmissionMask;
			float4 _EmissionColor;
			#endif

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				float3 wnormal = UnityObjectToWorldNormal(v.normal);
				#if _USESPHERE_ADD || _USESPHERE_MULTIPLY
				o.sphereCoord = reflect(float3(0,0,-1), mul((float3x3)UNITY_MATRIX_V, wnormal));
				#endif
				float3 lightDir = -normalize(_LightDir.xyz);
				o.shadow = (1.0 - dot(lightDir, wnormal)) * 0.5;
				o.shadow = _ShadeEdge * (-_Ambient + o.shadow);
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				float shadow = clamp(i.shadow, 0, _ShadeColor.a);
				// sample the texture
				float4 col = _Color * tex2D(_Tex, i.uv);
				col.rgb = (1.0 - shadow) * col.rgb + shadow * _ShadeColor.rgb;
				#if _USESPHERE_ADD
				col.rgb += texCUBE(_SphereTex, i.sphereCoord).rgb;
				#elif _USESPHERE_MULTIPLY
				col.rgb *= texCUBE(_SphereTex, i.sphereCoord).rgb;
				#endif
				#if USE_EMISSION
				float4 emission = tex2D(_EmissionMask, i.uv).rgbr * _EmissionColor;
				col.rgb += emission.rgb;
				#endif
				return saturate(col);
			}
			ENDCG
		}
		Pass 
		{
			Blend SrcAlpha OneMinusSrcAlpha, Zero Zero
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
			};

			float4 _OutlineColor;
			float _OutlineWidth;

			v2f vert (appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 offset = TransformViewToProjection(norm.xy);
				o.vertex.xy += offset * _OutlineWidth * (1.0 - (UnityObjectToViewPos(v.vertex).z));
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				return _OutlineColor;
			}
			ENDCG
		}
	}
}
