#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Film grain for the sky gradients (the soft paper texture in the reference designs).
// Static per pixel, so it never shimmers or draws the eye.
// Optional: add this file to the FocusApp target (needs `xcodebuild -downloadComponent MetalToolchain`)
// and use `.colorEffect(ShaderLibrary.grain(.float(0.04)))` on SkyBackground instead of GrainTexture.
// Optional: add this file to the FocusApp target (needs `xcodebuild -downloadComponent MetalToolchain`)
// and use `.colorEffect(ShaderLibrary.grain(.float(0.04)))` on SkyBackground instead of GrainTexture.
[[ stitchable ]] half4 grain(float2 position, half4 color, float strength) {
    float n = fract(sin(dot(floor(position), float2(12.9898, 78.233))) * 43758.5453);
    half g = half((n - 0.5) * strength);
    return half4(clamp(color.rgb + g * color.a, half3(0.0), half3(1.0)), color.a);
}
