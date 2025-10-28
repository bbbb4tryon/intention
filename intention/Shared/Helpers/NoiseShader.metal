//
//  NoiseShader.metal
//  intention
//
//  Created by Benjamin Tryon on 10/27/25.
//

#include <metal_stdlib>
using namespace metal;

// simple hash-based noise
[[ stitchable ]]
half4 noiseShader(float2 position, half4 baseColor, float2 size, float time, float strength) {
    float2 p = position / size;
    float n = fract(sin(dot(p + time, float2(12.9898, 78.233))) * 43758.5453);
    half noise = half(n) * half(strength);
    // Multiply as luminance-only grain; keep alpha as-is.
    return half4(baseColor.rgb + noise, baseColor.a);
}
