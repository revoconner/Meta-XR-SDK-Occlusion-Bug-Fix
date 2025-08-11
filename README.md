# Meta XR SDK Occlusion algorithm (Unity 6+ )
Removed the limitation of Meta Quest SDK occlusion system where game objects won't render beyond depth sensor range

## Use in a shader 
```
#include "EnvironmentOcclusionURPCustom.hlsl"
                // Apply custom occlusion logic
                META_DEPTH_OCCLUDE_OUTPUT_PREMULTIPLY(input, finalColor, 0);
```
