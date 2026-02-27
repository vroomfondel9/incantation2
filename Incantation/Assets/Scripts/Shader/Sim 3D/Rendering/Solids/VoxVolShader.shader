Shader "Shader Graphs/VoxVolShaderNoDepth"
{
    Properties
    {
        [NoScaleOffset]_ColorTexture("ColorTexture", 3D) = "white" {}
        _GridDimensions("GridDimensions", Vector) = (0, 0, 0, 0)
        [NoScaleOffset]_HitTexture("HitTexture", 3D) = "white" {}
        _VoxelVolumeOffset("VoxelVolumeOffset", Float) = 0
        _VoxelVolumeID("VoxelVolumeID", Float) = 0
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
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
            "DisableBatching"="False"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalLitSubTarget"
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
        AlphaToMask On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma multi_compile _ _FORWARD_PLUS
        #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
        #pragma shader_feature_local _ _EDITOR_MODE
        
        #if defined(_EDITOR_MODE)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif
        
        
        // Defines
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD2
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_NORMAL_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_TANGENT_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_SHADOW_COORD
        #endif
        
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        #define _FOG_FRAGMENT 1
        #define _ALPHATEST_ON 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv1 : TEXCOORD1;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv2 : TEXCOORD2;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentWS;
            #endif
            #if defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 staticLightmapUV;
            #endif
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 dynamicLightmapUV;
            #endif
            #endif
            #if !defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 sh;
            #endif
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 fogFactorAndVertexLight;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 shadowCoord;
            #endif
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 TangentSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceBiTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 staticLightmapUV : INTERP0;
            #endif
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 dynamicLightmapUV : INTERP1;
            #endif
            #endif
            #if !defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 sh : INTERP2;
            #endif
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 shadowCoord : INTERP3;
            #endif
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentWS : INTERP4;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 fogFactorAndVertexLight : INTERP5;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS : INTERP6;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalWS : INTERP7;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.sh;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.shadowCoord;
            #endif
            output.tangentWS.xyzw = input.tangentWS;
            output.fogFactorAndVertexLight.xyzw = input.fogFactorAndVertexLight;
            output.positionWS.xyz = input.positionWS;
            output.normalWS.xyz = input.normalWS;
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
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.sh;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.shadowCoord;
            #endif
            output.tangentWS = input.tangentWS.xyzw;
            output.fogFactorAndVertexLight = input.fogFactorAndVertexLight.xyzw;
            output.positionWS = input.positionWS.xyz;
            output.normalWS = input.normalWS.xyz;
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
        #endif
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float3 _GridDimensions;
        float _VoxelVolumeOffset;
        float _VoxelVolumeID;
        CBUFFER_END
        
        #if defined(DOTS_INSTANCING_ON)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float3, _GridDimensions)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeOffset)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeID)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type, var)
        #elif defined(UNITY_INSTANCING_ENABLED)
        // Unity instancing definitions
        UNITY_INSTANCING_BUFFER_START(SGPerInstanceData)
            UNITY_DEFINE_INSTANCED_PROP(float3, _GridDimensions)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeID)
        UNITY_INSTANCING_BUFFER_END(SGPerInstanceData)
        // Unity instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_INSTANCED_PROP(SGPerInstanceData, var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif
        
        // Object and Global properties
        TEXTURE3D(_ColorTexture);
        SAMPLER(sampler_ColorTexture);
        TEXTURE3D(_HitTexture);
        SAMPLER(sampler_HitTexture);
        float _DebugVisualizationMode;
        
        // Graph Includes
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/AmanatidesAndWooRayMarching.hlsl"
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/SampleVoxelColors.hlsl"
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void CalculateDepth_float(float3 WorldPos, out float DepthValue){
            float4 clipPos = TransformWorldToHClip(WorldPos);
            
            DepthValue = clipPos.z / clipPos.w;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
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
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
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
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D = UnityBuildTexture3DStruct(_ColorTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float = _DebugVisualizationMode;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D = UnityBuildTexture3DStruct(_HitTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3;
            _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3 = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3;
            Unity_Subtract_float3(IN.ObjectSpacePosition, _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3, _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3;
            Unity_Normalize_float3(_Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1d4284113834aad934275b87db1f016_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3;
            RayMarch_float(_Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D, IN.ObjectSpacePosition, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3, _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3, _Property_c1d4284113834aad934275b87db1f016_Out_0_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3;
            _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3 = TransformObjectToWorld(_RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float;
            CalculateDepth_float(_Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3;
            ColorSample_float(_Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D, _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3, _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float, _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float, IN.ObjectSpacePosition, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3;
            {
                // Converting Direction from Object to Tangent via world space
                float3 world;
                world = TransformObjectToWorldDir(_ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3.xyz, false);
                {
                    float3x3 tangentTransform = float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal);
                    _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3 = TransformWorldToTangentDir(world, tangentTransform, true);
                }
            }
            #endif
            surface.BaseColor = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            surface.NormalTS = _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = float(0);
            surface.Smoothness = float(0.5);
            surface.Occlusion = float(1);
            surface.Alpha = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            surface.AlphaClipThreshold = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceNormal =                          input.normalOS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceTangent =                         input.tangentOS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition =                        input.positionOS;
        #endif
        
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float3 unnormalizedNormalWS = input.normalWS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // use bitangent on the fly like in hdrp
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceBiTangent = renormFactor * bitang;
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition = TransformWorldToObject(input.positionWS);
        #endif
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
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
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "PBRForwardPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
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
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
        #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma shader_feature_local _ _EDITOR_MODE
        
        #if defined(_EDITOR_MODE)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif
        
        
        // Defines
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD2
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_NORMAL_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_TANGENT_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_SHADOW_COORD
        #endif
        
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_GBUFFER
        #define _FOG_FRAGMENT 1
        #define _ALPHATEST_ON 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv1 : TEXCOORD1;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv2 : TEXCOORD2;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentWS;
            #endif
            #if defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 staticLightmapUV;
            #endif
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 dynamicLightmapUV;
            #endif
            #endif
            #if !defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 sh;
            #endif
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 fogFactorAndVertexLight;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 shadowCoord;
            #endif
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 TangentSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceBiTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 staticLightmapUV : INTERP0;
            #endif
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 dynamicLightmapUV : INTERP1;
            #endif
            #endif
            #if !defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 sh : INTERP2;
            #endif
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 shadowCoord : INTERP3;
            #endif
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentWS : INTERP4;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 fogFactorAndVertexLight : INTERP5;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS : INTERP6;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalWS : INTERP7;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.sh;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.shadowCoord;
            #endif
            output.tangentWS.xyzw = input.tangentWS;
            output.fogFactorAndVertexLight.xyzw = input.fogFactorAndVertexLight;
            output.positionWS.xyz = input.positionWS;
            output.normalWS.xyz = input.normalWS;
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
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.sh;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.shadowCoord;
            #endif
            output.tangentWS = input.tangentWS.xyzw;
            output.fogFactorAndVertexLight = input.fogFactorAndVertexLight.xyzw;
            output.positionWS = input.positionWS.xyz;
            output.normalWS = input.normalWS.xyz;
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
        #endif
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float3 _GridDimensions;
        float _VoxelVolumeOffset;
        float _VoxelVolumeID;
        CBUFFER_END
        
        #if defined(DOTS_INSTANCING_ON)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float3, _GridDimensions)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeOffset)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeID)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type, var)
        #elif defined(UNITY_INSTANCING_ENABLED)
        // Unity instancing definitions
        UNITY_INSTANCING_BUFFER_START(SGPerInstanceData)
            UNITY_DEFINE_INSTANCED_PROP(float3, _GridDimensions)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeID)
        UNITY_INSTANCING_BUFFER_END(SGPerInstanceData)
        // Unity instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_INSTANCED_PROP(SGPerInstanceData, var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif
        
        // Object and Global properties
        TEXTURE3D(_ColorTexture);
        SAMPLER(sampler_ColorTexture);
        TEXTURE3D(_HitTexture);
        SAMPLER(sampler_HitTexture);
        float _DebugVisualizationMode;
        
        // Graph Includes
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/AmanatidesAndWooRayMarching.hlsl"
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/SampleVoxelColors.hlsl"
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void CalculateDepth_float(float3 WorldPos, out float DepthValue){
            float4 clipPos = TransformWorldToHClip(WorldPos);
            
            DepthValue = clipPos.z / clipPos.w;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
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
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
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
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D = UnityBuildTexture3DStruct(_ColorTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float = _DebugVisualizationMode;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D = UnityBuildTexture3DStruct(_HitTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3;
            _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3 = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3;
            Unity_Subtract_float3(IN.ObjectSpacePosition, _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3, _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3;
            Unity_Normalize_float3(_Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1d4284113834aad934275b87db1f016_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3;
            RayMarch_float(_Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D, IN.ObjectSpacePosition, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3, _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3, _Property_c1d4284113834aad934275b87db1f016_Out_0_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3;
            _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3 = TransformObjectToWorld(_RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float;
            CalculateDepth_float(_Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3;
            ColorSample_float(_Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D, _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3, _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float, _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float, IN.ObjectSpacePosition, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3;
            {
                // Converting Direction from Object to Tangent via world space
                float3 world;
                world = TransformObjectToWorldDir(_ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3.xyz, false);
                {
                    float3x3 tangentTransform = float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal);
                    _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3 = TransformWorldToTangentDir(world, tangentTransform, true);
                }
            }
            #endif
            surface.BaseColor = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            surface.NormalTS = _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3;
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = float(0);
            surface.Smoothness = float(0.5);
            surface.Occlusion = float(1);
            surface.Alpha = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            surface.AlphaClipThreshold = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceNormal =                          input.normalOS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceTangent =                         input.tangentOS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition =                        input.positionOS;
        #endif
        
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float3 unnormalizedNormalWS = input.normalWS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // use bitangent on the fly like in hdrp
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceBiTangent = renormFactor * bitang;
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition = TransformWorldToObject(input.positionWS);
        #endif
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
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
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
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
        ZTest LEqual
        ZWrite On
        ColorMask R
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        // PassKeywords: <None>
        #pragma shader_feature_local _ _EDITOR_MODE
        
        #if defined(_EDITOR_MODE)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif
        
        
        // Defines
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif
        
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define _ALPHATEST_ON 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS : INTERP0;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.positionWS.xyz = input.positionWS;
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
            output.positionWS = input.positionWS.xyz;
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
        #endif
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float3 _GridDimensions;
        float _VoxelVolumeOffset;
        float _VoxelVolumeID;
        CBUFFER_END
        
        #if defined(DOTS_INSTANCING_ON)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float3, _GridDimensions)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeOffset)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeID)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type, var)
        #elif defined(UNITY_INSTANCING_ENABLED)
        // Unity instancing definitions
        UNITY_INSTANCING_BUFFER_START(SGPerInstanceData)
            UNITY_DEFINE_INSTANCED_PROP(float3, _GridDimensions)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeID)
        UNITY_INSTANCING_BUFFER_END(SGPerInstanceData)
        // Unity instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_INSTANCED_PROP(SGPerInstanceData, var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif
        
        // Object and Global properties
        TEXTURE3D(_ColorTexture);
        SAMPLER(sampler_ColorTexture);
        TEXTURE3D(_HitTexture);
        SAMPLER(sampler_HitTexture);
        float _DebugVisualizationMode;
        
        // Graph Includes
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/AmanatidesAndWooRayMarching.hlsl"
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/SampleVoxelColors.hlsl"
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void CalculateDepth_float(float3 WorldPos, out float DepthValue){
            float4 clipPos = TransformWorldToHClip(WorldPos);
            
            DepthValue = clipPos.z / clipPos.w;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
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
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D = UnityBuildTexture3DStruct(_ColorTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float = _DebugVisualizationMode;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D = UnityBuildTexture3DStruct(_HitTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3;
            _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3 = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3;
            Unity_Subtract_float3(IN.ObjectSpacePosition, _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3, _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3;
            Unity_Normalize_float3(_Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1d4284113834aad934275b87db1f016_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3;
            RayMarch_float(_Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D, IN.ObjectSpacePosition, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3, _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3, _Property_c1d4284113834aad934275b87db1f016_Out_0_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3;
            _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3 = TransformObjectToWorld(_RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float;
            CalculateDepth_float(_Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3;
            ColorSample_float(_Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D, _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3, _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float, _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float, IN.ObjectSpacePosition, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3);
            #endif
            surface.Alpha = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            surface.AlphaClipThreshold = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceNormal =                          input.normalOS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceTangent =                         input.tangentOS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition =                        input.positionOS;
        #endif
        
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition = TransformWorldToObject(input.positionWS);
        #endif
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
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
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
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
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        // PassKeywords: <None>
        #pragma shader_feature_local _ _EDITOR_MODE
        
        #if defined(_EDITOR_MODE)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif
        
        
        // Defines
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_NORMAL_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_TANGENT_WS
        #endif
        
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALS
        #define _ALPHATEST_ON 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv1 : TEXCOORD1;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentWS;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 TangentSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceBiTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentWS : INTERP0;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS : INTERP1;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalWS : INTERP2;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.tangentWS.xyzw = input.tangentWS;
            output.positionWS.xyz = input.positionWS;
            output.normalWS.xyz = input.normalWS;
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
            output.tangentWS = input.tangentWS.xyzw;
            output.positionWS = input.positionWS.xyz;
            output.normalWS = input.normalWS.xyz;
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
        #endif
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float3 _GridDimensions;
        float _VoxelVolumeOffset;
        float _VoxelVolumeID;
        CBUFFER_END
        
        #if defined(DOTS_INSTANCING_ON)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float3, _GridDimensions)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeOffset)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeID)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type, var)
        #elif defined(UNITY_INSTANCING_ENABLED)
        // Unity instancing definitions
        UNITY_INSTANCING_BUFFER_START(SGPerInstanceData)
            UNITY_DEFINE_INSTANCED_PROP(float3, _GridDimensions)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeID)
        UNITY_INSTANCING_BUFFER_END(SGPerInstanceData)
        // Unity instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_INSTANCED_PROP(SGPerInstanceData, var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif
        
        // Object and Global properties
        TEXTURE3D(_ColorTexture);
        SAMPLER(sampler_ColorTexture);
        TEXTURE3D(_HitTexture);
        SAMPLER(sampler_HitTexture);
        float _DebugVisualizationMode;
        
        // Graph Includes
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/AmanatidesAndWooRayMarching.hlsl"
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/SampleVoxelColors.hlsl"
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void CalculateDepth_float(float3 WorldPos, out float DepthValue){
            float4 clipPos = TransformWorldToHClip(WorldPos);
            
            DepthValue = clipPos.z / clipPos.w;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
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
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D = UnityBuildTexture3DStruct(_ColorTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float = _DebugVisualizationMode;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D = UnityBuildTexture3DStruct(_HitTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3;
            _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3 = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3;
            Unity_Subtract_float3(IN.ObjectSpacePosition, _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3, _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3;
            Unity_Normalize_float3(_Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1d4284113834aad934275b87db1f016_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3;
            RayMarch_float(_Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D, IN.ObjectSpacePosition, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3, _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3, _Property_c1d4284113834aad934275b87db1f016_Out_0_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3;
            _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3 = TransformObjectToWorld(_RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float;
            CalculateDepth_float(_Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3;
            ColorSample_float(_Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D, _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3, _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float, _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float, IN.ObjectSpacePosition, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3;
            {
                // Converting Direction from Object to Tangent via world space
                float3 world;
                world = TransformObjectToWorldDir(_ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3.xyz, false);
                {
                    float3x3 tangentTransform = float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal);
                    _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3 = TransformWorldToTangentDir(world, tangentTransform, true);
                }
            }
            #endif
            surface.NormalTS = _Transform_530350f0ad83424f9713cfe51bf4b50c_Out_1_Vector3;
            surface.Alpha = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            surface.AlphaClipThreshold = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceNormal =                          input.normalOS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceTangent =                         input.tangentOS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition =                        input.positionOS;
        #endif
        
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float3 unnormalizedNormalWS = input.normalWS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // use bitangent on the fly like in hdrp
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0)* GetOddNegativeScale();
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.WorldSpaceBiTangent = renormFactor * bitang;
        #endif
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition = TransformWorldToObject(input.positionWS);
        #endif
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
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
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
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
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma shader_feature _ EDITOR_VISUALIZATION
        #pragma shader_feature_local _ _EDITOR_MODE
        
        #if defined(_EDITOR_MODE)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif
        
        
        // Defines
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD0
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD2
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_TEXCOORD0
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_TEXCOORD1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_TEXCOORD2
        #endif
        
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        #define _FOG_FRAGMENT 1
        #define _ALPHATEST_ON 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv0 : TEXCOORD0;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv1 : TEXCOORD1;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv2 : TEXCOORD2;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 texCoord0;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 texCoord1;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 texCoord2;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 texCoord0 : INTERP0;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 texCoord1 : INTERP1;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 texCoord2 : INTERP2;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS : INTERP3;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            output.texCoord1.xyzw = input.texCoord1;
            output.texCoord2.xyzw = input.texCoord2;
            output.positionWS.xyz = input.positionWS;
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
            output.texCoord0 = input.texCoord0.xyzw;
            output.texCoord1 = input.texCoord1.xyzw;
            output.texCoord2 = input.texCoord2.xyzw;
            output.positionWS = input.positionWS.xyz;
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
        #endif
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float3 _GridDimensions;
        float _VoxelVolumeOffset;
        float _VoxelVolumeID;
        CBUFFER_END
        
        #if defined(DOTS_INSTANCING_ON)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float3, _GridDimensions)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeOffset)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeID)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type, var)
        #elif defined(UNITY_INSTANCING_ENABLED)
        // Unity instancing definitions
        UNITY_INSTANCING_BUFFER_START(SGPerInstanceData)
            UNITY_DEFINE_INSTANCED_PROP(float3, _GridDimensions)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeID)
        UNITY_INSTANCING_BUFFER_END(SGPerInstanceData)
        // Unity instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_INSTANCED_PROP(SGPerInstanceData, var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif
        
        // Object and Global properties
        TEXTURE3D(_ColorTexture);
        SAMPLER(sampler_ColorTexture);
        TEXTURE3D(_HitTexture);
        SAMPLER(sampler_HitTexture);
        float _DebugVisualizationMode;
        
        // Graph Includes
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/AmanatidesAndWooRayMarching.hlsl"
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/SampleVoxelColors.hlsl"
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void CalculateDepth_float(float3 WorldPos, out float DepthValue){
            float4 clipPos = TransformWorldToHClip(WorldPos);
            
            DepthValue = clipPos.z / clipPos.w;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
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
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
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
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D = UnityBuildTexture3DStruct(_ColorTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float = _DebugVisualizationMode;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D = UnityBuildTexture3DStruct(_HitTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3;
            _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3 = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3;
            Unity_Subtract_float3(IN.ObjectSpacePosition, _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3, _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3;
            Unity_Normalize_float3(_Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1d4284113834aad934275b87db1f016_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3;
            RayMarch_float(_Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D, IN.ObjectSpacePosition, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3, _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3, _Property_c1d4284113834aad934275b87db1f016_Out_0_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3;
            _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3 = TransformObjectToWorld(_RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float;
            CalculateDepth_float(_Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3;
            ColorSample_float(_Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D, _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3, _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float, _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float, IN.ObjectSpacePosition, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3);
            #endif
            surface.BaseColor = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            surface.Emission = float3(0, 0, 0);
            surface.Alpha = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            surface.AlphaClipThreshold = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceNormal =                          input.normalOS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceTangent =                         input.tangentOS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition =                        input.positionOS;
        #endif
        
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition = TransformWorldToObject(input.positionWS);
        #endif
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
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
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
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
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        // PassKeywords: <None>
        #pragma shader_feature_local _ _EDITOR_MODE
        
        #if defined(_EDITOR_MODE)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif
        
        
        // Defines
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif
        
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define _ALPHATEST_ON 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS : INTERP0;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.positionWS.xyz = input.positionWS;
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
            output.positionWS = input.positionWS.xyz;
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
        #endif
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float3 _GridDimensions;
        float _VoxelVolumeOffset;
        float _VoxelVolumeID;
        CBUFFER_END
        
        #if defined(DOTS_INSTANCING_ON)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float3, _GridDimensions)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeOffset)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeID)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type, var)
        #elif defined(UNITY_INSTANCING_ENABLED)
        // Unity instancing definitions
        UNITY_INSTANCING_BUFFER_START(SGPerInstanceData)
            UNITY_DEFINE_INSTANCED_PROP(float3, _GridDimensions)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeID)
        UNITY_INSTANCING_BUFFER_END(SGPerInstanceData)
        // Unity instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_INSTANCED_PROP(SGPerInstanceData, var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif
        
        // Object and Global properties
        TEXTURE3D(_ColorTexture);
        SAMPLER(sampler_ColorTexture);
        TEXTURE3D(_HitTexture);
        SAMPLER(sampler_HitTexture);
        float _DebugVisualizationMode;
        
        // Graph Includes
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/AmanatidesAndWooRayMarching.hlsl"
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/SampleVoxelColors.hlsl"
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void CalculateDepth_float(float3 WorldPos, out float DepthValue){
            float4 clipPos = TransformWorldToHClip(WorldPos);
            
            DepthValue = clipPos.z / clipPos.w;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
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
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D = UnityBuildTexture3DStruct(_ColorTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float = _DebugVisualizationMode;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D = UnityBuildTexture3DStruct(_HitTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3;
            _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3 = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3;
            Unity_Subtract_float3(IN.ObjectSpacePosition, _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3, _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3;
            Unity_Normalize_float3(_Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1d4284113834aad934275b87db1f016_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3;
            RayMarch_float(_Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D, IN.ObjectSpacePosition, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3, _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3, _Property_c1d4284113834aad934275b87db1f016_Out_0_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3;
            _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3 = TransformObjectToWorld(_RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float;
            CalculateDepth_float(_Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3;
            ColorSample_float(_Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D, _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3, _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float, _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float, IN.ObjectSpacePosition, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3);
            #endif
            surface.Alpha = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            surface.AlphaClipThreshold = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceNormal =                          input.normalOS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceTangent =                         input.tangentOS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition =                        input.positionOS;
        #endif
        
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition = TransformWorldToObject(input.positionWS);
        #endif
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
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
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull Back
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        // PassKeywords: <None>
        #pragma shader_feature_local _ _EDITOR_MODE
        
        #if defined(_EDITOR_MODE)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif
        
        
        // Defines
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif
        
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define _ALPHATEST_ON 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS : INTERP0;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.positionWS.xyz = input.positionWS;
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
            output.positionWS = input.positionWS.xyz;
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
        #endif
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float3 _GridDimensions;
        float _VoxelVolumeOffset;
        float _VoxelVolumeID;
        CBUFFER_END
        
        #if defined(DOTS_INSTANCING_ON)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float3, _GridDimensions)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeOffset)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeID)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type, var)
        #elif defined(UNITY_INSTANCING_ENABLED)
        // Unity instancing definitions
        UNITY_INSTANCING_BUFFER_START(SGPerInstanceData)
            UNITY_DEFINE_INSTANCED_PROP(float3, _GridDimensions)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeID)
        UNITY_INSTANCING_BUFFER_END(SGPerInstanceData)
        // Unity instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_INSTANCED_PROP(SGPerInstanceData, var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif
        
        // Object and Global properties
        TEXTURE3D(_ColorTexture);
        SAMPLER(sampler_ColorTexture);
        TEXTURE3D(_HitTexture);
        SAMPLER(sampler_HitTexture);
        float _DebugVisualizationMode;
        
        // Graph Includes
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/AmanatidesAndWooRayMarching.hlsl"
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/SampleVoxelColors.hlsl"
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void CalculateDepth_float(float3 WorldPos, out float DepthValue){
            float4 clipPos = TransformWorldToHClip(WorldPos);
            
            DepthValue = clipPos.z / clipPos.w;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
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
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D = UnityBuildTexture3DStruct(_ColorTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float = _DebugVisualizationMode;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D = UnityBuildTexture3DStruct(_HitTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3;
            _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3 = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3;
            Unity_Subtract_float3(IN.ObjectSpacePosition, _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3, _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3;
            Unity_Normalize_float3(_Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1d4284113834aad934275b87db1f016_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3;
            RayMarch_float(_Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D, IN.ObjectSpacePosition, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3, _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3, _Property_c1d4284113834aad934275b87db1f016_Out_0_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3;
            _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3 = TransformObjectToWorld(_RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float;
            CalculateDepth_float(_Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3;
            ColorSample_float(_Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D, _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3, _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float, _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float, IN.ObjectSpacePosition, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3);
            #endif
            surface.Alpha = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            surface.AlphaClipThreshold = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceNormal =                          input.normalOS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceTangent =                         input.tangentOS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition =                        input.positionOS;
        #endif
        
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition = TransformWorldToObject(input.positionWS);
        #endif
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
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
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "Universal 2D"
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
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        // PassKeywords: <None>
        #pragma shader_feature_local _ _EDITOR_MODE
        
        #if defined(_EDITOR_MODE)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif
        
        
        // Defines
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif
        
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_2D
        #define _ALPHATEST_ON 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS : INTERP0;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.positionWS.xyz = input.positionWS;
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
            output.positionWS = input.positionWS.xyz;
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
        #endif
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float3 _GridDimensions;
        float _VoxelVolumeOffset;
        float _VoxelVolumeID;
        CBUFFER_END
        
        #if defined(DOTS_INSTANCING_ON)
        // DOTS instancing definitions
        UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float3, _GridDimensions)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeOffset)
            UNITY_DOTS_INSTANCED_PROP_OVERRIDE_SUPPORTED(float, _VoxelVolumeID)
        UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
        // DOTS instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type, var)
        #elif defined(UNITY_INSTANCING_ENABLED)
        // Unity instancing definitions
        UNITY_INSTANCING_BUFFER_START(SGPerInstanceData)
            UNITY_DEFINE_INSTANCED_PROP(float3, _GridDimensions)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _VoxelVolumeID)
        UNITY_INSTANCING_BUFFER_END(SGPerInstanceData)
        // Unity instancing usage macros
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) UNITY_ACCESS_INSTANCED_PROP(SGPerInstanceData, var)
        #else
        #define UNITY_ACCESS_HYBRID_INSTANCED_PROP(var, type) var
        #endif
        
        // Object and Global properties
        TEXTURE3D(_ColorTexture);
        SAMPLER(sampler_ColorTexture);
        TEXTURE3D(_HitTexture);
        SAMPLER(sampler_HitTexture);
        float _DebugVisualizationMode;
        
        // Graph Includes
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/AmanatidesAndWooRayMarching.hlsl"
        #include "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/SampleVoxelColors.hlsl"
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A - B;
        }
        
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }
        
        void CalculateDepth_float(float3 WorldPos, out float DepthValue){
            float4 clipPos = TransformWorldToHClip(WorldPos);
            
            DepthValue = clipPos.z / clipPos.w;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
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
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
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
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D = UnityBuildTexture3DStruct(_ColorTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float = _DebugVisualizationMode;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            UnityTexture3D _Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D = UnityBuildTexture3DStruct(_HitTexture);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3;
            _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3 = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3;
            Unity_Subtract_float3(IN.ObjectSpacePosition, _Transform_bda1fa3367bb46a98e915ce3466413a8_Out_1_Vector3, _Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3;
            Unity_Normalize_float3(_Subtract_19a79dc5a7bb4cf1ad28edf977cf69ad_Out_2_Vector3, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3 = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_GridDimensions, float3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _Property_c1d4284113834aad934275b87db1f016_Out_0_Float = UNITY_ACCESS_HYBRID_INSTANCED_PROP(_VoxelVolumeOffset, float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float;
            float _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float;
            float3 _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3;
            RayMarch_float(_Property_edd0109cf6e343169b6506ca080157da_Out_0_Texture3D, IN.ObjectSpacePosition, _Normalize_86c390669ae146108e1d97a3cedb27f9_Out_1_Vector3, _Property_3c81ef39695847f4961b2e444d7e66d6_Out_0_Vector3, _Property_c1d4284113834aad934275b87db1f016_Out_0_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3;
            _Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3 = TransformObjectToWorld(_RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelSurfaceStrikeLocObj_8_Vector3.xyz);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float;
            CalculateDepth_float(_Transform_5583fc4bd1bb424781c368e490f9362e_Out_1_Vector3, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float);
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            float _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            float3 _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3;
            ColorSample_float(_Property_06bb097371af41259d80159681d32a0a_Out_0_Texture3D, _Property_cd276a4b141e4d98a1a126c23ca03a78_Out_0_Vector3, _Property_527e141c13da4f159c675e5613f45a78_Out_0_Float, _Property_c1ae4596922c4a4e95e6246d2141f458_Out_0_Float, IN.ObjectSpacePosition, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Hit_2_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_UV_3_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_Voxel_7_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue1_9_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_VoxelValue2_13_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_NormalsObj_6_Vector3, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchIterations_11_Float, _RayMarchCustomFunction_b411f2944ad64b33af5790d16c63bb97_RaymarchSamples_12_Float, _CalculateDepthCustomFunction_89a9fbc79e6948f9a0e3c0730343a8e3_DepthValue_1_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float, _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_NormsObj_15_Vector3);
            #endif
            surface.BaseColor = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_RGB_2_Vector3;
            surface.Alpha = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Alpha_10_Float;
            surface.AlphaClipThreshold = _ColorSampleCustomFunction_329d1da73b19492f89c2fd8bc7a008da_Dpth_16_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceNormal =                          input.normalOS;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpaceTangent =                         input.tangentOS.xyz;
        #endif
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition =                        input.positionOS;
        #endif
        
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        output.ObjectSpacePosition = TransformWorldToObject(input.positionWS);
        #endif
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
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
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraphLitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    FallBack "Hidden/Shader Graph/FallbackError"
}