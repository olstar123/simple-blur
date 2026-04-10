#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

// Motion blur strength (0.0 = off, 1.0 = full)
#define MOTION_BLUR_STRENGTH 0.5
const float motionBlurStrength = MOTION_BLUR_STRENGTH;

// Number of samples for motion blur (higher = smoother but slower)
#define MOTION_BLUR_SAMPLES 10

// Contrast (1.0 = default, >1.0 = more contrast, <1.0 = less)
#define CONTRAST 1.0
const float contrast = CONTRAST;

// Brightness (1.0 = default)
#define BRIGHTNESS 1.0
const float brightness = BRIGHTNESS;

#endif
