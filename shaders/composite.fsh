#version 120

// sliders= in shaders.properties registers these as sliders
#define MOTION_BLUR_STRENGTH 0.5 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define CONTRAST 1.0             //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define BRIGHTNESS 1.0           //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

#define MOTION_BLUR_SAMPLES 12

uniform sampler2D colortex0;

// depthtex0 = full scene depth (includes hand)
// depthtex2 = scene depth WITHOUT the hand/held item
// We use both: if depthtex0 != depthtex2 at a pixel, that pixel IS the hand
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

varying vec2 texcoord;

vec2 getPreviousUV(vec2 uv, float depth) {
    vec4 ndcPos = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * ndcPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    vec4 prevClip = gbufferPreviousProjection * (gbufferPreviousModelView * worldPos);
    vec3 prevNDC = prevClip.xyz / prevClip.w;
    return prevNDC.xy * 0.5 + 0.5;
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth0 = texture2D(depthtex0, texcoord).r;
    float depth2 = texture2D(depthtex2, texcoord).r;

    // If depthtex0 and depthtex2 differ, this pixel is part of the hand/held item
    bool isHand = abs(depth0 - depth2) > 0.0001;

    if (!isHand && depth0 < 1.0) {
        vec2 prevUV = getPreviousUV(texcoord, depth0);
        vec2 velocity = (texcoord - prevUV) * MOTION_BLUR_STRENGTH;

        // Cap max blur spread to avoid smearing on sudden camera cuts
        float maxBlur = 0.02;
        float velLen = length(velocity);
        if (velLen > maxBlur) {
            velocity *= maxBlur / velLen;
        }

        vec3 blurred = color;
        float weight = 1.0;
        for (int i = 1; i < MOTION_BLUR_SAMPLES; i++) {
            float t = float(i) / float(MOTION_BLUR_SAMPLES);
            vec2 sampleUV = texcoord - velocity * t;

            // Also skip sampling hand pixels when blurring world geometry behind it
            float sampleDepth0 = texture2D(depthtex0, sampleUV).r;
            float sampleDepth2 = texture2D(depthtex2, sampleUV).r;
            bool sampleIsHand = abs(sampleDepth0 - sampleDepth2) > 0.0001;

            if (!sampleIsHand &&
                sampleUV.x >= 0.0 && sampleUV.x <= 1.0 &&
                sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {
                blurred += texture2D(colortex0, sampleUV).rgb;
                weight += 1.0;
            }
        }
        color = blurred / weight;
    }

    // Contrast (pivot around 0.5 midpoint)
    color = clamp((color - 0.5) * CONTRAST + 0.5, 0.0, 1.0);

    // Brightness
    color = clamp(color * BRIGHTNESS, 0.0, 1.0);

    gl_FragData[0] = vec4(color, 1.0);
}
