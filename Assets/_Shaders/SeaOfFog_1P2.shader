// mkelsey - SeaOfFog_1P2 - UPDATE: Moved from vert-frag to surf for easier lighting.
// Standard surface shader that manipulates a plane to visually imitate volumetric properties.

Shader "Custom/SeaOfFog_1P2"
{
    Properties
    {
        [Header(Texture Control)]
        _MainTex("Main Texture", 2D) = "white" {}
        _SecondTex("Secondary Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _ScrollX("Secondary Scroll X", Range(-0.1, 0.1)) = 0.05
        _ScrollY("Secondary Scroll Y", Range(-0.1, 0.1)) = 0.05

        [Space(5)]
        [Header(Wave Control)]
        _Amplitude("Amplitude", Range(0.0, 0.5)) = 0.05
        _Frequency("Frequency", Range(6.0, 10.0)) = 8.0
        _Direction("Direction", Vector) = (1.0, 0.0, 0.0, 1.0)

        [Space(5)]
        [Header(Intersection Control)]
        _FadeLength("Fade Length", Range(0.0, 10.0)) = 1.0
    }

        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "ForceNoShadowCasting" = "True" }

            CGPROGRAM
            #pragma target 3.0
            #pragma surface surf Standard alpha:fade vertex:vert

            struct Input
            {
                float2 uv_MainTex;
                float4 screenPos;
                float3 worldPos;
            };

            sampler2D _CameraDepthTexture;
            sampler2D _MainTex, _SecondTex;
            fixed4 _Color, _Direction;
            fixed _ScrollX, _ScrollY; 
            float _Amplitude, _Frequency, _FadeLength;

            void vert(inout appdata_full v)
            {
                float4 dir = normalize(_Direction);
                float baseWaveLength = 2 * UNITY_PI;
                float waveLength = baseWaveLength / _Frequency;
                float displacment = waveLength * (dot(dir, v.vertex.xyz) - _Time.y);
                float wavePeak = _Amplitude / waveLength;

                v.vertex.x += dir.z * cos(displacment);
                v.vertex.y = wavePeak * sin(displacment);
                v.vertex.z += dir.y * cos(displacment);
            }

            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                o.Albedo = _Color;

                float2 scrollingUV = IN.uv_MainTex;
                scrollingUV += float2(_ScrollX * _Direction.x, _ScrollY * _Direction.z) * _Time.y;

                fixed4 mainTex = tex2D(_MainTex, IN.uv_MainTex);
                fixed4 secondTex = tex2D(_SecondTex, scrollingUV);

                // Surface Intersection
                float sceneDepth = 0.0;
                if (IN.screenPos.w != 0.0)// Avoid UNITY_PROJ_COORD (a) NaN
                    sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
                float surfDepth = -mul(UNITY_MATRIX_V, float4(IN.worldPos.xyz, 1)).z;
                float diff = sceneDepth - surfDepth;
                float intersect = saturate(diff / _FadeLength);

                o.Alpha = (_Color.a * lerp(mainTex, secondTex, 0.5)) * intersect;
            }
            ENDCG
        }
Fallback "Diffuse"
}
