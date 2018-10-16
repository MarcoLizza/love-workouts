const float PI = 3.1415926535897932384626433f;

const float[] HEIGHTS = float[]( 0.0f, 0.0f, 0.0f );
const float[] AMPLITUDES = float[]( 0.015f, 0.025f, 0.020f );
const float[] OFFSETS = float[]( 0.0f, 0.0f, 0.0f );
const float[] STRETCHES = float[]( 7.00f, 9.00f, 5.00f );
const float[] SPEEDS = float[]( 5.00f, 7.00f, 3.00f );

const int WAVES = 3;

float sine(float x, float a, float b)
{
    return sin(a * x) * cos(b * x);
}

float floating(float x)
{
    return sine(x, 0.5f, 0.7f);
}

float horizon(float time)
{
    float x = time * 0.125f;
    float height = (sin(x) + 1.0) / 2.0;
    float offset = floating(x * 8.0f) / 64.0;
    return height + offset;
}

vec4 wave(float time, vec2 uv, vec4 color)
{
    float y = 0.0;

    for (int i = 0; i < WAVES; ++i) {
        y += HEIGHTS[i] +
            AMPLITUDES[i] *
            sin(OFFSETS[i] + uv.x * STRETCHES[i] + time * SPEEDS[i]);
    }

    y += horizon(time);

    if (uv.y > y) {
        return vec4(color.rgb, 0.125);
    } else {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
}

extern float time;
extern vec2 screen_resolution;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = screen_coords / screen_resolution; // vec2(love_ScreenSize)
    return wave(time, uv, color);
}