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
		[Toggle(USE_SPHERE)] _UseSphere("Use MMDSphere?", Int) = 1
		[NoScaleOffset] _SphereTex ("MMDSphere", CUBE) = "" {}
		[KeywordEnum(None, Front, Back)] _Cull("Culling", Int) = 2
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="AlphaTest" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha, Zero Zero
			Cull [_Cull]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature USE_SPHERE

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
				float3 normal : NORMAL;
				#if USE_SPHERE
				float3 sphereCoord : TEXCOORD1;
				#endif
			};

			float4 _Color;
			float _Ambient;
			float4 _LightDir;
			float4 _ShadeColor;
			float _ShadeEdge;

			sampler2D _Tex;
			samplerCUBE _SphereTex;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				o.normal = UnityObjectToWorldNormal(v.normal);
				#if USE_SPHERE
				o.sphereCoord = reflect(float3(0,0,-1), mul((float3x3)UNITY_MATRIX_V, o.normal));
				#endif
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				float3 lightDir = normalize(_LightDir.xyz) * -1.0;
				float shadow = (1.0 - dot(lightDir,i.normal)) * 0.5;
				// sample the texture
				float4 col = _Color * tex2D(_Tex, i.uv);
				shadow = clamp(_ShadeEdge * (-_Ambient + shadow), 0, _ShadeColor.a);
				col.rgb = (1.0 - shadow) * col.rgb + shadow * _ShadeColor.rgb;
				#if USE_SPHERE
				col.rgb += texCUBE(_SphereTex, i.sphereCoord).rgb;
				#endif
				return float4(clamp(col.rgb, 0.0, 1.0), col.a);
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
				o.vertex.xy += offset * _OutlineWidth;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				return _OutlineColor;
			}
			ENDCG
		}
	}
}
