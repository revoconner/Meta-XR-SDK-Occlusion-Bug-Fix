/*
 * Custom Environment Occlusion Override
 * This file modifies Meta's depth occlusion behavior for distant objects
 * Include this instead of the original EnvironmentOcclusion.cginc
 */

#ifndef META_DEPTH_ENVIRONMENT_OCCLUSION_CUSTOM_INCLUDED
#define META_DEPTH_ENVIRONMENT_OCCLUSION_CUSTOM_INCLUDED

// First, include the original file to get all base definitions and macros
#include "../EnvironmentOcclusion.cginc"

// Constants for distant object handling
#define SENSOR_RANGE_LIMIT 0.3f  // Adjustable sensor range limit

// Custom function: Check if depth data is valid AND within our artificial sensor range limit
bool IsValidDepthData(float2 uv, float linearDepth)
{
    // Check UV bounds
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return false;
    
    // Additional check: sample raw depth to detect invalid values
    float rawDepth = SampleEnvironmentDepth(uv);
    if (rawDepth <= 0.001f || rawDepth >= 0.999f)
        return false;
    
    // CRITICAL: Only consider environment depth valid if it's within our sensor range limit
    // This ensures walls beyond the limit don't occlude distant virtual objects
    if (linearDepth > SENSOR_RANGE_LIMIT)
        return false;
    
    return true;
}

// Override the original hard occlusion function
#ifdef CalculateEnvironmentDepthHardOcclusion
#undef CalculateEnvironmentDepthHardOcclusion
#endif

float CalculateEnvironmentDepthHardOcclusion(float2 depthUv, float sceneDepth)
{
    float environmentDepth = SampleEnvironmentDepthLinear(depthUv);
  
    // Check if we have valid depth data using our custom function
    bool hasValidDepth = IsValidDepthData(depthUv, environmentDepth);
  
    // If virtual object is beyond sensor range
    if (sceneDepth > SENSOR_RANGE_LIMIT)
    {
        // For distant objects: only occlude if we have valid real-world depth data
        // that is closer than the virtual object
        if (hasValidDepth && environmentDepth < sceneDepth)
        {
            return 0.0f; // Occlude - real object is closer
        }
        else
        {
            return 1.0f; // Show virtual object (no valid occlusion data or real object is farther)
        }
    }
    else
    {
        // For close objects: use original algorithm
        // If no valid depth data, assume occlusion (original behavior)
        if (!hasValidDepth)
        {
            return 0.0f; // Occlude when no valid depth data for close objects
        }
    
        // Normal comparison
        return environmentDepth > sceneDepth ? 1.0f : 0.0f;
    }
}

// Override the original soft occlusion function  
#ifdef CalculateEnvironmentDepthSoftOcclusion
#undef CalculateEnvironmentDepthSoftOcclusion
#endif

float CalculateEnvironmentDepthSoftOcclusion(float2 uvCoords, float linearSceneDepth)
{
    const float2 halfPixelOffset = 0.5f * float2(_PreprocessedEnvironmentDepthTexture_TexelSize.xy);
    uvCoords -= halfPixelOffset;

    float biasedDepthSpace = _EnvironmentDepthZBufferParams.x / linearSceneDepth - _EnvironmentDepthZBufferParams.y;
    float cubeDepthRangeLow = (biasedDepthSpace + 1.0f) * 0.5f;

    const float kRange = 1.0f / 1.04f - 1.0f;
    float cubeDepthRangeInv = 1.0f / (cubeDepthRangeLow * kRange - kRange);

    float4 texSample = SamplePreprocessedDepth(uvCoords, unity_StereoEyeIndex);
    float3 minMaxMid = float3(1.0f - texSample.x, 1.0f - texSample.y, texSample.z + 1.0f - texSample.x);
    float3 alphas = clamp((minMaxMid - cubeDepthRangeLow) * cubeDepthRangeInv, 0.0f, 1.0f);

    float alpha = alphas.z;
    if (alphas.y - alphas.x > 0.03f)
    {
        const float kForegroundLevel = 0.2f;
        const float kBackgroundLevel = 0.8f;
        float interp = texSample.z / texSample.w;
        alpha = lerp(alphas.x, alphas.y, smoothstep(kForegroundLevel, kBackgroundLevel, interp));
    }

    // Apply distant object logic for soft occlusion too
    if (linearSceneDepth > SENSOR_RANGE_LIMIT)
    {
        // For distant objects in soft occlusion, check if we have valid preprocessed data
        // If no valid data, default to visible
        if (texSample.w <= 0.001f || any(isnan(texSample)) || any(isinf(texSample)))
        {
            return 1.0f; // Show distant objects when no valid soft occlusion data
        }
    }

    return alpha;
}

#endif // META_DEPTH_ENVIRONMENT_OCCLUSION_CUSTOM_INCLUDED
