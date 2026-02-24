Shader "VoxelBBShaderNoDepth"
{
    Properties
    {
        [NoScaleOffset]_TextureArray("TextureArray", 2DArray) = "" {}
        Vector2_f6956137ee8a40f1bc6783d404e8989e("TextureSize", Vector) = (0, 0, 0, 0)
        OffsetIntoTexture("OffsetIntoTexture", Vector) = (0, 0, 0, 0)
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="AlphaTest"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_Negate_float3(float3 In, out float3 Out)
        {
            Out = -1 * In;
        }

        struct Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19
        {
        };

        void SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(float3 Vector3_d024f26289ca42a39062d46db2963a97, Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 IN, out float3 normals_1)
        {
            float3 _Property_c04090baa4cc4e7ba9d38380ef014573_Out_0 = Vector3_d024f26289ca42a39062d46db2963a97;
            float3 _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1;
            Unity_OneMinus_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1);
            float3 _Negate_c0cfdc838d42442eada873f60a84485f_Out_1;
            Unity_Negate_float3(_OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1);
            float3 _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
            Unity_Add_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1, _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2);
            normals_1 = _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalOS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559;
            float3 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.BaseColor = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            surface.NormalOS = _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 1;
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
        #pragma multi_compile _ _GBUFFER_NORMALS_OCT
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_GBUFFER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_Negate_float3(float3 In, out float3 Out)
        {
            Out = -1 * In;
        }

        struct Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19
        {
        };

        void SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(float3 Vector3_d024f26289ca42a39062d46db2963a97, Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 IN, out float3 normals_1)
        {
            float3 _Property_c04090baa4cc4e7ba9d38380ef014573_Out_0 = Vector3_d024f26289ca42a39062d46db2963a97;
            float3 _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1;
            Unity_OneMinus_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1);
            float3 _Negate_c0cfdc838d42442eada873f60a84485f_Out_1;
            Unity_Negate_float3(_OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1);
            float3 _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
            Unity_Add_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1, _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2);
            normals_1 = _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalOS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559;
            float3 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.BaseColor = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            surface.NormalOS = _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 1;
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        void Unity_Negate_float3(float3 In, out float3 Out)
        {
            Out = -1 * In;
        }

        struct Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19
        {
        };

        void SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(float3 Vector3_d024f26289ca42a39062d46db2963a97, Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 IN, out float3 normals_1)
        {
            float3 _Property_c04090baa4cc4e7ba9d38380ef014573_Out_0 = Vector3_d024f26289ca42a39062d46db2963a97;
            float3 _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1;
            Unity_OneMinus_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1);
            float3 _Negate_c0cfdc838d42442eada873f60a84485f_Out_1;
            Unity_Negate_float3(_OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1);
            float3 _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
            Unity_Add_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1, _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2);
            normals_1 = _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalOS;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559;
            float3 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.NormalOS = _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.BaseColor = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            surface.Emission = float3(0, 0, 0);
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.BaseColor = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="AlphaTest"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_Negate_float3(float3 In, out float3 Out)
        {
            Out = -1 * In;
        }

        struct Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19
        {
        };

        void SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(float3 Vector3_d024f26289ca42a39062d46db2963a97, Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 IN, out float3 normals_1)
        {
            float3 _Property_c04090baa4cc4e7ba9d38380ef014573_Out_0 = Vector3_d024f26289ca42a39062d46db2963a97;
            float3 _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1;
            Unity_OneMinus_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1);
            float3 _Negate_c0cfdc838d42442eada873f60a84485f_Out_1;
            Unity_Negate_float3(_OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1);
            float3 _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
            Unity_Add_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1, _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2);
            normals_1 = _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalOS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559;
            float3 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.BaseColor = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            surface.NormalOS = _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = 0;
            surface.Smoothness = 0;
            surface.Occlusion = 1;
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        void Unity_Negate_float3(float3 In, out float3 Out)
        {
            Out = -1 * In;
        }

        struct Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19
        {
        };

        void SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(float3 Vector3_d024f26289ca42a39062d46db2963a97, Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 IN, out float3 normals_1)
        {
            float3 _Property_c04090baa4cc4e7ba9d38380ef014573_Out_0 = Vector3_d024f26289ca42a39062d46db2963a97;
            float3 _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1;
            Unity_OneMinus_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1);
            float3 _Negate_c0cfdc838d42442eada873f60a84485f_Out_1;
            Unity_Negate_float3(_OneMinus_1785f496b55c49ff985ee4aa6cdc7f4f_Out_1, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1);
            float3 _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
            Unity_Add_float3(_Property_c04090baa4cc4e7ba9d38380ef014573_Out_0, _Negate_c0cfdc838d42442eada873f60a84485f_Out_1, _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2);
            normals_1 = _Add_762adfe4862b45e98f2823a3c2264ef5_Out_2;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalOS;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelNormals_4f825609711a86e4fbecd20604f78f19 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559;
            float3 _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            SG_VoxelNormals_4f825609711a86e4fbecd20604f78f19(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559, _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.NormalOS = _VoxelNormals_3484a4b81b214d8ca11290dd5f7e2559_normals_1;
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.BaseColor = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            surface.Emission = float3(0, 0, 0);
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _AlphaClip 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_OS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float2 Vector2_f6956137ee8a40f1bc6783d404e8989e;
        // Hybrid instanced properties
        float4 OffsetIntoTexture;
        CBUFFER_END
        #if defined(UNITY_DOTS_INSTANCING_ENABLED)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP(float4, OffsetIntoTexture)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(type, Metadata_##var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif

        // Object and Global properties
        SAMPLER(SamplerState_Point_Clamp);
        TEXTURE2D_ARRAY(_TextureArray);
        SAMPLER(sampler_TextureArray);

            // Graph Functions
            
        void Unity_Branch_float3(float Predicate, float3 True, float3 False, out float3 Out)
        {
            Out = Predicate ? True : False;
        }

        struct Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47
        {
        };

        void SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 IN, out float3 Position_1, out float3 Direction_2, out float Orthographic_3, out float Near_Plane_4, out float Far_Plane_5, out float Z_Buffer_Sign_6, out float Width_7, out float Height_8)
        {
            float Boolean_f72c4d5ec1444214829df5da359ed69d = 0;
            float3 _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0 = float3(-10, -0.5, -10);
            float3 _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_863858795a1f4ce1bf3ce5b2534c8626_Out_0, _WorldSpaceCameraPos, _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3);
            float3 _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0 = float3(0.5, 0, 0.5);
            float3 _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Unity_Branch_float3(Boolean_f72c4d5ec1444214829df5da359ed69d, _Vector3_638458c3100a43bd9898b1d35c74404a_Out_0, -1 * mul((float3x3)UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz), _Branch_53e4f3c2c514483481568a068ed5775e_Out_3);
            Position_1 = _Branch_2a3a9225325d45c6a6a1a3b9419064d7_Out_3;
            Direction_2 = _Branch_53e4f3c2c514483481568a068ed5775e_Out_3;
            Orthographic_3 = unity_OrthoParams.w;
            Near_Plane_4 = _ProjectionParams.y;
            Far_Plane_5 = _ProjectionParams.z;
            Z_Buffer_Sign_6 = _ProjectionParams.x;
            Width_7 = unity_OrthoParams.x;
            Height_8 = unity_OrthoParams.y;
        }

        void Unity_Comparison_Equal_float(float A, float B, out float Out)
        {
            Out = A == B ? 1 : 0;
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_CrossProduct_float(float3 A, float3 B, out float3 Out)
        {
            Out = cross(A, B);
        }

        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }

        struct Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6
        {
            float4 ScreenPosition;
        };

        void SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 IN, out float3 projectedCamera_1)
        {
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_cd13d0b2f65642369968d94962270ed8;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1;
            float3 _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7;
            float _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_cd13d0b2f65642369968d94962270ed8, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Position_1, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, _MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _MockableCamera_cd13d0b2f65642369968d94962270ed8_FarPlane_5, _MockableCamera_cd13d0b2f65642369968d94962270ed8_ZBufferSign_6, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Width_7, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Height_8);
            float _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2;
            Unity_Comparison_Equal_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Orthographic_3, 1, _Comparison_b3047aa8356549129d72f0eb8189179f_Out_2);
            float3 _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, (_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4.xxx), _Multiply_0ac2c0520fa94eeab54830303f853487_Out_2);
            float3 _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2;
            Unity_Multiply_float(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, float3(2, 2, 2), _Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2);
            float3 _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, float3 (0, -1, 0), _CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2);
            float3 _Normalize_0112293435e1417384320ceacb3350ea_Out_1;
            Unity_Normalize_float3(_CrossProduct_d4a5c46c156841e4951dd2dcd758c6b5_Out_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1);
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1 = UNITY_MATRIX_P[0];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2 = UNITY_MATRIX_P[1];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M2_3 = UNITY_MATRIX_P[2];
            float4 _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M3_4 = UNITY_MATRIX_P[3];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[0];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[1];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[2];
            float _Split_3594bf8c0a164dfcb2dcb4763b116fca_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M0_1[3];
            float _Divide_abed627e1e0443b3918b2636bdfde107_Out_2;
            Unity_Divide_float(1, _Split_3594bf8c0a164dfcb2dcb4763b116fca_R_1, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2);
            float _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_abed627e1e0443b3918b2636bdfde107_Out_2, _Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2);
            float4 _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w * 2 - 1, 0, 0);
            float _Split_1d840c30ee754f828b069a2998fc5e17_R_1 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[0];
            float _Split_1d840c30ee754f828b069a2998fc5e17_G_2 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[1];
            float _Split_1d840c30ee754f828b069a2998fc5e17_B_3 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[2];
            float _Split_1d840c30ee754f828b069a2998fc5e17_A_4 = _ScreenPosition_bf45633423f94c26916d8faa21b49a75_Out_0[3];
            float _Multiply_eb59943a22014fb79d434815500c2df7_Out_2;
            Unity_Multiply_float(_Multiply_449f2c1ca4e9477cb12b82ed91e67480_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_R_1, _Multiply_eb59943a22014fb79d434815500c2df7_Out_2);
            float3 _Multiply_40914a9f39bf4469938c644685a8c287_Out_2;
            Unity_Multiply_float(_Normalize_0112293435e1417384320ceacb3350ea_Out_1, (_Multiply_eb59943a22014fb79d434815500c2df7_Out_2.xxx), _Multiply_40914a9f39bf4469938c644685a8c287_Out_2);
            float3 _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2;
            Unity_CrossProduct_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_0112293435e1417384320ceacb3350ea_Out_1, _CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2);
            float _Split_aad73ac1a5c243188a4aa9a969bed685_R_1 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[0];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_G_2 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[1];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_B_3 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[2];
            float _Split_aad73ac1a5c243188a4aa9a969bed685_A_4 = _MatrixSplit_6f7bf08759524c7993c7710d408b2e6c_M1_2[3];
            float _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2;
            Unity_Divide_float(-1, _Split_aad73ac1a5c243188a4aa9a969bed685_G_2, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2);
            float _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2;
            Unity_Multiply_float(_MockableCamera_cd13d0b2f65642369968d94962270ed8_NearPlane_4, _Divide_564b2d56b6c844c0b78f730f04b4098a_Out_2, _Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2);
            float _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2;
            Unity_Multiply_float(_Multiply_f86f848c5e6c41c3a29bd3e8598c2b90_Out_2, _Split_1d840c30ee754f828b069a2998fc5e17_G_2, _Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2);
            float3 _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2;
            Unity_Multiply_float(_CrossProduct_2cb1155a4bde47a783be91bab0c4bcc8_Out_2, (_Multiply_b20ea16f25be42b0b5d92cbb9befd639_Out_2.xxx), _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2);
            float3 _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2;
            Unity_Add_float3(_Multiply_40914a9f39bf4469938c644685a8c287_Out_2, _Multiply_5f9cc0bd844c4341849c89c25966adc3_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2);
            float3 _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2;
            Unity_Subtract_float3(_Multiply_0ac2c0520fa94eeab54830303f853487_Out_2, _Add_4cc296fee3ec4531bee36b2460b03e9f_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2);
            float3 _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2;
            Unity_Subtract_float3(_Multiply_7c02c570576c417aa6cccf0f0a3d9cb6_Out_2, _Subtract_ab3967bbf7044b89998bd37adfc0d2eb_Out_2, _Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2);
            float3 _Normalize_df7448a4621748b9a65866f9af37649c_Out_1;
            Unity_Normalize_float3(_Subtract_182f3cbcb8fe48a3a5444df392192ffd_Out_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1);
            float3 _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
            Unity_Branch_float3(_Comparison_b3047aa8356549129d72f0eb8189179f_Out_2, _MockableCamera_cd13d0b2f65642369968d94962270ed8_Direction_2, _Normalize_df7448a4621748b9a65866f9af37649c_Out_1, _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3);
            projectedCamera_1 = _Branch_0de6e8cc43394e60b2034b09a6141d3c_Out_3;
        }

        void Unity_Maximum_float(float A, float B, out float Out)
        {
            Out = max(A, B);
        }

        void Unity_Sign_float3(float3 In, out float3 Out)
        {
            Out = sign(In);
        }

        void Unity_Maximum_float3(float3 A, float3 B, out float3 Out)
        {
            Out = max(A, B);
        }

        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_Round_float3(float3 In, out float3 Out)
        {
            Out = round(In);
        }

        void Unity_Clamp_float3(float3 In, float3 Min, float3 Max, out float3 Out)
        {
            Out = clamp(In, Min, Max);
        }

        void Unity_Fraction_float3(float3 In, out float3 Out)
        {
            Out = frac(In);
        }

        void Unity_Divide_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A / B;
        }

        void Unity_OneMinus_float3(float3 In, out float3 Out)
        {
            Out = 1 - In;
        }

        void Unity_Absolute_float3(float3 In, out float3 Out)
        {
            Out = abs(In);
        }

        void Unity_Reciprocal_Fast_float3(float3 In, out float3 Out)
        {
            Out = rcp(In);
        }

        void Unity_Floor_float3(float3 In, out float3 Out)
        {
            Out = floor(In);
        }

        void incrementallyCastThroughVolume_float(float3 boundaryLimits, float3 tMaxInit, UnityTexture2DArray textureArray, UnitySamplerState samplerState, float3 uvScaleOffset, float3 uvScaleMult, float3 surfaceVoxelIndex, float3 step, float3 tDelta, float3 size, out float notFound, out float3 foundVoxelIndex, out float4 foundVoxelValue, out float tFrontFace, out float3 frontFaceHit, out float tBackFace, out float3 backFaceHit, out float withinMaxIterations, out float3 directionTravelled){
            //#define DEBUG_ENABLED  0
            #define ITERATION_LIMIT 1

            // Initialize output parameters
            foundVoxelIndex = surfaceVoxelIndex;
            directionTravelled = float3(0.0f, 0.0f, 0.0f);
            withinMaxIterations = true;
            notFound = true;

            //initialize loop variables
            float3 tMax = tMaxInit;
            float3 tMaxLast = float3(0.0f, 0.0f, 0.0f);
            float3 distanceVector;
            float3 stepVector;
            float distanceOutsideBoundary;
            float isInsideBoundaryAndNotFound = 1.0f;
            float stepSign;
            float3 lastComparisonFactors = tMax - tDelta;
            float3 comparisonFactors = float3((lastComparisonFactors.x > lastComparisonFactors.y) && (lastComparisonFactors.x > lastComparisonFactors.z), 
            			(lastComparisonFactors.y > lastComparisonFactors.x) && (lastComparisonFactors.y > lastComparisonFactors.z), 
            				(lastComparisonFactors.z > lastComparisonFactors.x) && (lastComparisonFactors.z > lastComparisonFactors.y));
            float3 uv;

            #ifdef ITERATION_LIMIT
               float maxIterations = 3 * sqrt(size.x*size.x + size.y*size.y + size.z*size.z);
            #endif

            // Iterative looping
            #if defined(ITERATION_LIMIT)
                while ((isInsideBoundaryAndNotFound == 1.0f) && (maxIterations >= 0))
            #else
               while ((isInsideBoundaryAndNotFound == 1.0f))
            #endif
            {
            		 // Resample
                     uv = foundVoxelIndex * uvScaleMult + uvScaleOffset;
                     foundVoxelValue = textureArray.SampleLevel(samplerState, uv, 0);         
                     notFound = (foundVoxelValue.a==0.0f);
            		 
            		 lastComparisonFactors = comparisonFactors;
            		 comparisonFactors = float3((tMax.x < tMax.y) && (tMax.x < tMax.z), 
            			(tMax.y < tMax.x) && (tMax.y < tMax.z), 
            				(tMax.z < tMax.x) && (tMax.z < tMax.y));
            		 
            #ifdef DEBUG_ENABLED
               directionTravelled += comparisonFactors * notFound; 
            #endif

            		stepVector = step * comparisonFactors;
            		stepSign = stepVector.x + stepVector.y + stepVector.z;
            		foundVoxelIndex += stepVector * notFound; 
            		distanceVector = ((boundaryLimits - foundVoxelIndex) * comparisonFactors);
            		distanceOutsideBoundary = distanceVector.x + distanceVector.y + distanceVector.z;
            		distanceOutsideBoundary /= stepSign;
            		isInsideBoundaryAndNotFound = (distanceOutsideBoundary > 0.0f) && notFound;
            		
                    tMaxLast = tMax * isInsideBoundaryAndNotFound + tMaxLast * (1.0f - isInsideBoundaryAndNotFound);
            		tMax += tDelta * comparisonFactors * isInsideBoundaryAndNotFound; 

            #ifdef ITERATION_LIMIT
               maxIterations -= 1.0f * isInsideBoundaryAndNotFound;
            #endif
            }

            #ifdef ITERATION_LIMIT
               withinMaxIterations = (maxIterations >= 0.0f);
            #endif

            //Compute final strike values
            tFrontFace = min(min(tMaxLast.x, tMaxLast.y), tMaxLast.z);
            tBackFace = min(min(tMax.x, tMax.y), tMax.z);

            frontFaceHit = lastComparisonFactors * step * -1.0f;
            backFaceHit = comparisonFactors * step * -1.0f;
        }

        void Unity_Not_float(float In, out float Out)
        {
            Out = !In;
        }

        struct Bindings_VoxelLookup_dd463f492da7287478accc0626db5481
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
        };

        void SG_VoxelLookup_dd463f492da7287478accc0626db5481(UnityTexture2DArray _VoxelTexture, float2 Vector2_d704ca12588b42e3b8607357942ae0c7, float3 Vector3_4866f15a872b466cb3e9a478932bc84e, float3 _projectedCamera, Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 IN, out float voxelFound_0, out float3 voxelIndex_1, out float4 voxelValue_2, out float3 frontFaceOffset_3, out float3 frontFaceHit_5, out float3 backFaceOffset_4, out float3 backFaceHit_6)
        {
            float3 _Property_1326fb1cfb594efab348bb6f927f6815_Out_0 = _projectedCamera;
            float3 _Transform_37c3927cca13495c93152e1ccb4cef53_Out_1 = TransformWorldToObjectDir(_Property_1326fb1cfb594efab348bb6f927f6815_Out_0.xyz);
            float _Split_4d2f1dd11e804988a1683b506a938d12_R_1 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[0];
            float _Split_4d2f1dd11e804988a1683b506a938d12_G_2 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[1];
            float _Split_4d2f1dd11e804988a1683b506a938d12_B_3 = float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z)))[2];
            float _Split_4d2f1dd11e804988a1683b506a938d12_A_4 = 0;
            float _Maximum_149e915851734833802c9a1168e85b93_Out_2;
            Unity_Maximum_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_149e915851734833802c9a1168e85b93_Out_2);
            float _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2;
            Unity_Maximum_float(_Maximum_149e915851734833802c9a1168e85b93_Out_2, _Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2);
            float _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_R_1, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2);
            float _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_G_2, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2);
            float _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2;
            Unity_Divide_float(_Split_4d2f1dd11e804988a1683b506a938d12_B_3, _Maximum_aa30ea7e0df04587b1cc6a2492a9bc26_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0 = float3(_Divide_6d8848adf41b4aa78aaaa9c7128ce0c8_Out_2, _Divide_e2e2c37784664b48b83fb6d5e79168ba_Out_2, _Divide_3f99ecabc84143dbabc45753967ff5fc_Out_2);
            float3 _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2;
            Unity_Multiply_float(_Transform_37c3927cca13495c93152e1ccb4cef53_Out_1, _Vector3_14a88c36d01243deb6aa438cd6a22197_Out_0, _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2);
            float3 _Sign_4033362cfa8d432e931466ea11601ae4_Out_1;
            Unity_Sign_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1);
            float3 _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2;
            Unity_Multiply_float(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2);
            float3 _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2;
            Unity_Maximum_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(0, 0, 0), _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2);
            float3 _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3;
            Unity_Lerp_float3(float3(-1, -1, -1), _Multiply_d1f21cbf15a44a848e4888eae46c658c_Out_2, _Maximum_1f132e4a95b14e8a94b01945a6263a14_Out_2, _Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3);
            float3 _Round_34a2430fed1941d8bc972c07d36e4538_Out_1;
            Unity_Round_float3(_Lerp_098a86140cac4e1ab0d268ab5c48e18a_Out_3, _Round_34a2430fed1941d8bc972c07d36e4538_Out_1);
            float3 _Property_196942e9dbe9434b8f02479728e1ee72_Out_0 = Vector3_4866f15a872b466cb3e9a478932bc84e;
            float3 _Add_22319accaba34be08967043cd82b8895_Out_2;
            Unity_Add_float3(_Round_34a2430fed1941d8bc972c07d36e4538_Out_1, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_22319accaba34be08967043cd82b8895_Out_2);
            float3 _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, float3(0.50001, 0.50001, 0.50001), _Add_e26df0c78eaf4c4d8948ca511b933540_Out_2);
            float3 _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2;
            Unity_Multiply_float(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Multiply_c6c2cacef619427c959b171758f5eba4_Out_2);
            float3 _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2;
            Unity_Subtract_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2);
            float3 _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1;
            Unity_Sign_float3(_Subtract_dd0b0b65e560423890daa0e740d5808b_Out_2, _Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1);
            float3 _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3;
            Unity_Clamp_float3(_Sign_19dfc773f5b04a5097ba47dd66ccdafa_Out_1, float3(0, 0, 0), float3(1, 1, 1), _Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3);
            float3 _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1;
            Unity_Fraction_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1);
            float3 _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2;
            Unity_Add_float3(_Clamp_86401ff2adde4e47a7eb5f0edb9b8521_Out_3, _Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2);
            float3 _Add_1a75f8832b3b496ca6783078e4871612_Out_2;
            Unity_Add_float3(float3(-1, -1, -1), _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Add_1a75f8832b3b496ca6783078e4871612_Out_2);
            float3 _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2;
            Unity_Divide_float3(_Add_1a75f8832b3b496ca6783078e4871612_Out_2, float3(-2, -2, -2), _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2);
            float3 _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2;
            Unity_Multiply_float(_Add_e1a6f23c06cf45b0aab2b6e80e43e23c_Out_2, _Divide_49f2bb8da6b148f8b020f08450dbb7a0_Out_2, _Multiply_7d882d83465a43fd8600d76538ee0751_Out_2);
            float3 _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1;
            Unity_OneMinus_float3(_Fraction_aa074dd4bf894a8bb701fb87d6bf3f34_Out_1, _OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1);
            float3 _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2;
            Unity_Add_float3(_Sign_4033362cfa8d432e931466ea11601ae4_Out_1, float3(1, 1, 1), _Add_acb2be4501e74f7aa117cdd902f6d878_Out_2);
            float3 _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2;
            Unity_Divide_float3(_Add_acb2be4501e74f7aa117cdd902f6d878_Out_2, float3(2, 2, 2), _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2);
            float3 _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2;
            Unity_Multiply_float(_OneMinus_a57f482c957545ed8c1e9a65008f4b74_Out_1, _Divide_15fc21ff975d4c93b1c23b27b0377b31_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2);
            float3 _Add_8a817c465e634d56a37cb0b466f86489_Out_2;
            Unity_Add_float3(_Multiply_7d882d83465a43fd8600d76538ee0751_Out_2, _Multiply_be216be505d74865ae6766a1dfd74e92_Out_2, _Add_8a817c465e634d56a37cb0b466f86489_Out_2);
            float3 _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1;
            Unity_Absolute_float3(_Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1);
            float3 _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1;
            Unity_Reciprocal_Fast_float3(_Absolute_06d7890610264fe2ab336b0c32cb30bb_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1);
            float3 _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2;
            Unity_Multiply_float(_Add_8a817c465e634d56a37cb0b466f86489_Out_2, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2);
            UnityTexture2DArray _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0 = _VoxelTexture;
            float2 _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0 = Vector2_d704ca12588b42e3b8607357942ae0c7;
            float _Split_3881656dbd21441f83f58d415bbe02f6_R_1 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[0];
            float _Split_3881656dbd21441f83f58d415bbe02f6_G_2 = _Property_72e235be079748ae98a9a3cf4e265cf0_Out_0[1];
            float _Split_3881656dbd21441f83f58d415bbe02f6_B_3 = 0;
            float _Split_3881656dbd21441f83f58d415bbe02f6_A_4 = 0;
            float3 _Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0 = float3(_Split_3881656dbd21441f83f58d415bbe02f6_R_1, _Split_3881656dbd21441f83f58d415bbe02f6_G_2, 1);
            float3 _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1;
            Unity_Reciprocal_Fast_float3(_Vector3_c90d907a029140bcbe6ea23f38a81741_Out_0, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1);
            float3 _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2;
            Unity_Multiply_float(float3(0.5, 0.5, 0), _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2);
            float3 _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1;
            Unity_OneMinus_float3(_Add_e26df0c78eaf4c4d8948ca511b933540_Out_2, _OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1);
            float3 _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1;
            Unity_Floor_float3(_OneMinus_23d5e0ab7f31432e9a8976153f252459_Out_1, _Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1);
            float3 _Add_5090012ea90d42d4982476f91fa8518a_Out_2;
            Unity_Add_float3(_Multiply_c6c2cacef619427c959b171758f5eba4_Out_2, _Property_196942e9dbe9434b8f02479728e1ee72_Out_0, _Add_5090012ea90d42d4982476f91fa8518a_Out_2);
            float3 _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2;
            Unity_Add_float3(_Floor_5351e17f3c6b49a1a5d55ea1fbfe10dc_Out_1, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2);
            float3 _Floor_36db977f05184748a67ce67f18ec9f67_Out_1;
            Unity_Floor_float3(_Add_26d6e3fd7bc645fab995681cde2c6f13_Out_2, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1);
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            float4 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
            float _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11;
            float3 _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10;
            incrementallyCastThroughVolume_float(_Add_22319accaba34be08967043cd82b8895_Out_2, _Multiply_c19d612c9dd34cd9973617a63b2e333b_Out_2, _Property_90a444b35a6b4d77a72a4a27eaee6b9e_Out_0, UnityBuildSamplerStateStruct(SamplerState_Point_Clamp), _Multiply_1fa966dd867e49cd99c400d0c82b8797_Out_2, _Reciprocal_a3fe320f0e084a158204b90ff105f16d_Out_1, _Floor_36db977f05184748a67ce67f18ec9f67_Out_1, _Sign_4033362cfa8d432e931466ea11601ae4_Out_1, _Reciprocal_4dac93609956475e902443fdd5f8602f_Out_1, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_withinMaxIterations_11, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_directionTravelled_10);
            float _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            Unity_Not_float(_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_notFound_6, _Not_af4e40e5339a4c76aa227f56060c8828_Out_1);
            float3 _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tFrontFace_16.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2);
            float3 _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2;
            Unity_Add_float3(_Multiply_6d398c25f8e44d0691567e1d75981c71_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2);
            float3 _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            Unity_Subtract_float3(_Add_ad2f2cb787d64ff8a1e3528a2797da49_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2);
            float3 _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2;
            Unity_Multiply_float((_incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_tBackFace_17.xxx), _Multiply_40a5076426ea413fac65bbc6a2a2e161_Out_2, _Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2);
            float3 _Add_d68089146e9d43f2894b70149ee74fb0_Out_2;
            Unity_Add_float3(_Multiply_f61f44af7ccf491aa073df779311b9e5_Out_2, _Add_5090012ea90d42d4982476f91fa8518a_Out_2, _Add_d68089146e9d43f2894b70149ee74fb0_Out_2);
            float3 _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            Unity_Subtract_float3(_Add_d68089146e9d43f2894b70149ee74fb0_Out_2, _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15, _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2);
            voxelFound_0 = _Not_af4e40e5339a4c76aa227f56060c8828_Out_1;
            voxelIndex_1 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelIndex_15;
            voxelValue_2 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_foundVoxelValue_5;
            frontFaceOffset_3 = _Subtract_38c3ed8c836e40d0a83dff3e18f39747_Out_2;
            frontFaceHit_5 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_frontFaceHit_18;
            backFaceOffset_4 = _Subtract_fd3bf64d6d404e868567d74f205c70cf_Out_2;
            backFaceHit_6 = _incrementallyCastThroughVolumeCustomFunction_dfab75c889fb425b8eae65f0ef130d2c_backFaceHit_19;
        }

        struct Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11
        {
        };

        void SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(float Boolean_4f2153de8c9340529370c4e2210fee0e, float3 Vector3_a981a89477884848a4c78596967bf96f, float4 Vector4_39270f335ab44a12895f66edb145ec95, Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 IN, out float3 colors_1, out float alpha_2)
        {
            float4 _Property_ea086ff68bd44586a198b510cba456f5_Out_0 = Vector4_39270f335ab44a12895f66edb145ec95;
            float _Split_c55d2e40421b4fde913b05d2079ad346_R_1 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[0];
            float _Split_c55d2e40421b4fde913b05d2079ad346_G_2 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[1];
            float _Split_c55d2e40421b4fde913b05d2079ad346_B_3 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[2];
            float _Split_c55d2e40421b4fde913b05d2079ad346_A_4 = _Property_ea086ff68bd44586a198b510cba456f5_Out_0[3];
            float3 _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0 = float3(_Split_c55d2e40421b4fde913b05d2079ad346_R_1, _Split_c55d2e40421b4fde913b05d2079ad346_G_2, _Split_c55d2e40421b4fde913b05d2079ad346_B_3);
            colors_1 = _Vector3_aca285f539ac4ee08dbcf1943d390e04_Out_0;
            alpha_2 = _Split_c55d2e40421b4fde913b05d2079ad346_A_4;
        }

        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }

        struct Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpaceBiTangent;
        };

        void SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(float Boolean_0b28fd56b33449a6b28a4821ca9f6fcd, float3 Vector3_5b1e1b2881c444f78474a2869f35979b, float3 Vector3_48ee3e169a6c402aa500b04d63d5cbbc, float3 Vector3_51151a15053840dbbafecaa81fea8bac, Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda IN, out float Linear01Depth_1)
        {
            float3 _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2;
            Unity_Divide_float3(float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), float3(-2, -2, -2), _Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2);
            float3 _Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0 = Vector3_5b1e1b2881c444f78474a2869f35979b;
            float3 _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0 = Vector3_51151a15053840dbbafecaa81fea8bac;
            float3 _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2;
            Unity_Subtract_float3(_Property_a6f779c4bdcf4d02a6118d3200352ad5_Out_0, _Property_c15a75625110408ba3b67a2eab8a89ca_Out_0, _Subtract_904b053c0ff147f7a649752cd6739f01_Out_2);
            float3 _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0 = Vector3_48ee3e169a6c402aa500b04d63d5cbbc;
            float3 _Add_95ecb60f35e34089bef2b93272a343f6_Out_2;
            Unity_Add_float3(_Subtract_904b053c0ff147f7a649752cd6739f01_Out_2, _Property_c0f5e9eb88b04061bb89153b8e838a55_Out_0, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2);
            float3 _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2;
            Unity_Add_float3(_Divide_e834e3f9a11f46049eb3a2f7a81e3d64_Out_2, _Add_95ecb60f35e34089bef2b93272a343f6_Out_2, _Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2);
            float3 _Divide_34044f15758a46049f40760cc4ef8b19_Out_2;
            Unity_Divide_float3(_Add_c97d7075c3974b90b8922e6ed0bcd08a_Out_2, float3(length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x)),
                                     length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y)),
                                     length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z))), _Divide_34044f15758a46049f40760cc4ef8b19_Out_2);
            float3 _Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1 = TransformObjectToWorld(_Divide_34044f15758a46049f40760cc4ef8b19_Out_2.xyz);
            Bindings_MockableCamera_8c05f324002ebc047a87e66f2037ce47 _MockableCamera_95d311941d5640108c6a0b20fb966916;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1;
            float3 _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7;
            float _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8;
            SG_MockableCamera_8c05f324002ebc047a87e66f2037ce47(_MockableCamera_95d311941d5640108c6a0b20fb966916, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Orthographic_3, _MockableCamera_95d311941d5640108c6a0b20fb966916_NearPlane_4, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _MockableCamera_95d311941d5640108c6a0b20fb966916_ZBufferSign_6, _MockableCamera_95d311941d5640108c6a0b20fb966916_Width_7, _MockableCamera_95d311941d5640108c6a0b20fb966916_Height_8);
            float3 _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2;
            Unity_Subtract_float3(_Transform_5e85f3cd29dd4d008bef823ec57630ca_Out_1, _MockableCamera_95d311941d5640108c6a0b20fb966916_Position_1, _Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2);
            float _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2;
            Unity_DotProduct_float3(_Subtract_6677d1c415b44b7587e6c9366cea4a72_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_Direction_2, _DotProduct_e94ccd323af44ade86068a08223dead8_Out_2);
            float _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
            Unity_Divide_float(_DotProduct_e94ccd323af44ade86068a08223dead8_Out_2, _MockableCamera_95d311941d5640108c6a0b20fb966916_FarPlane_5, _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2);
            Linear01Depth_1 = _Divide_8a12993407b9436ebb4b13e7138226d5_Out_2;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float AlphaClipThreshold;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2DArray _Property_10b0dc37c12240239a378d7edeee0481_Out_0 = UnityBuildTexture2DArrayStruct(_TextureArray);
            float2 _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0 = Vector2_f6956137ee8a40f1bc6783d404e8989e;
            float4 _Property_381e631596634a5484f699729fe00f16_Out_0 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(OffsetIntoTexture, float4);
            Bindings_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f;
            _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f.ScreenPosition = IN.ScreenPosition;
            float3 _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1;
            SG_VoxelPerspectiveProjector_c086253114841744bbbea10226d79ff6(_VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f, _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1);
            Bindings_VoxelLookup_dd463f492da7287478accc0626db5481 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceNormal = IN.WorldSpaceNormal;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceTangent = IN.WorldSpaceTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
            _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5.ObjectSpacePosition = IN.ObjectSpacePosition;
            float _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1;
            float4 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4;
            float3 _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6;
            SG_VoxelLookup_dd463f492da7287478accc0626db5481(_Property_10b0dc37c12240239a378d7edeee0481_Out_0, _Property_9d1cf37726ba45f3a742ae20b6ca97cc_Out_0, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelPerspectiveProjector_7f65e1100237448a917fdb36c590053f_projectedCamera_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceHit_5, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceOffset_4, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_backFaceHit_6);
            Bindings_VoxelColors_5972a8e4bce2f8949995815f42300c11 _VoxelColors_bab5367a3ebb439d81148b97326b19e2;
            float3 _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            float _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            SG_VoxelColors_5972a8e4bce2f8949995815f42300c11(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelValue_2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1, _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2);
            Bindings_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceNormal = IN.ObjectSpaceNormal;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceTangent = IN.ObjectSpaceTangent;
            _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c.ObjectSpaceBiTangent = IN.ObjectSpaceBiTangent;
            float _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            SG_VoxelDepth_98ba4d5d0ca7f254db499efb312b9cda(_VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelFound_0, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_voxelIndex_1, _VoxelLookup_c1bf6601a6e9471bafa777b27456a7f5_frontFaceOffset_3, (_Property_381e631596634a5484f699729fe00f16_Out_0.xyz), _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c, _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1);
            surface.BaseColor = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_colors_1;
            surface.Alpha = _VoxelColors_bab5367a3ebb439d81148b97326b19e2_alpha_2;
            surface.AlphaClipThreshold = _VoxelDepth_d0a658acdc4e481bbc7c69d35b7fa76c_Linear01Depth_1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpacePosition =          input.positionWS;
            output.ObjectSpacePosition =         TransformWorldToObject(input.positionWS);
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    CustomEditor "ShaderGraph.PBRMasterGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}