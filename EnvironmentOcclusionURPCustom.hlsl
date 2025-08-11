/*
 * Custom URP Environment Occlusion with Distance-Based Logic
 * Include this instead of "Packages/com.meta.xr.sdk.core/Shaders/EnvironmentDepth/URP/EnvironmentOcclusionURP.hlsl"
 */

#ifndef META_DEPTH_ENVIRONMENT_OCCLUSION_URP_CUSTOM_INCLUDED
#define META_DEPTH_ENVIRONMENT_OCCLUSION_URP_CUSTOM_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// Redefining macro to avoid shader warnings.
#ifdef PREFER_HALF
#undef  PREFER_HALF
#endif
#define PREFER_HALF 0

#define SHADER_HINT_NICE_QUALITY 1

TEXTURE2D_X_FLOAT(_EnvironmentDepthTexture);

SAMPLER(sampler_EnvironmentDepthTexture);
float4 _EnvironmentDepthTexture_TexelSize;

TEXTURE2D_ARRAY_FLOAT(_PreprocessedEnvironmentDepthTexture);
SAMPLER(sampler_PreprocessedEnvironmentDepthTexture);
float4 _PreprocessedEnvironmentDepthTexture_TexelSize;

float SampleEnvironmentDepth(const float2 reprojectedUV) {
  return SAMPLE_TEXTURE2D_X(_EnvironmentDepthTexture, sampler_EnvironmentDepthTexture, reprojectedUV).r;
}

#define META_DEPTH_CONVERT_OBJECT_TO_WORLD(objectPos) TransformObjectToWorld(objectPos).xyz

float DepthConvertDepthToLinear(float zspace) {
  return LinearEyeDepth(zspace, _ZBufferParams);
}

float4 SamplePreprocessedDepth(float2 uv, float slice) {
  return _PreprocessedEnvironmentDepthTexture.Sample(sampler_PreprocessedEnvironmentDepthTexture, float3(uv.x, uv.y, slice));
}

// Include our custom occlusion logic instead of the original
#include "EnvironmentOcclusionCustom.cginc"

#endif
