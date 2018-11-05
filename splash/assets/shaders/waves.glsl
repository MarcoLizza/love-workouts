const float PI = 3.1415926535897932384626433f;

const float[] HEIGHTS = float[]( 0.0f, 0.0f, 0.0f );
const float[] AMPLITUDES = float[]( 0.015f, 0.025f, 0.020f );
const float[] OFFSETS = float[]( 0.0f, 0.0f, 0.0f );
const float[] STRETCHES = float[]( 7.00f, 9.00f, 5.00f );
const float[] SPEEDS = float[]( 5.00f, 7.00f, 3.00f );

const vec4[] GRADIENTS = vec4[](
        vec4(1.0, 0.0, 0.0, 1.0),
        vec4(1.0, 1.0, 0.0, 1.0),
        vec4(0.0, 1.0, 1.0, 1.0),
        vec4(0.0, 0.0, 1.0, 1.0),
        vec4(1.0, 0.0, 1.0, 1.0),
        vec4(1.0, 1.0, 1.0, 1.0)
    );

const int WAVES = 3;

const int MODE_WAVES = 0;
const int MODE_WATER = 1;
const int MODE_BAR = 2;
const int MODES = 3;

const float BAR_HEIGHT = 0.05f;

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

vec4 wave(int mode, float time, vec2 uv, vec4 color)
{
    float y = 0.0;
    for (int i = 0; i < WAVES; ++i) {
        y += HEIGHTS[i] +
            AMPLITUDES[i] *
            sin(OFFSETS[i] + uv.x * STRETCHES[i] + time * SPEEDS[i]);
    }
    y += horizon(time);

    if (mode == MODE_WAVES) {
        float value = abs(uv.y - y) * (GRADIENTS.length() - 1);
        int from = int(value);
        int to = from + 1;
        return mix(GRADIENTS[from], GRADIENTS[to], value - from);
    } else
    if (mode == MODE_WATER) {
        if (uv.y > y) {
            return vec4(0.0, 1.0, 1.0, 1.0);
        } else {
            return vec4(1.0, 0.0, 1.0, 1.0);
        }
    } else
    if (mode == MODE_BAR) {
        float ratio = abs(uv.y - y) / BAR_HEIGHT;
        if (ratio > 1) {
            return vec4(0.0, 0.0, 0.0, 0.0);
        }
        return mix(vec4(0.0, 1.0, 1.0, 1.0), vec4(0.0, 0.0, 1.0, 1.0), ratio);
    }
}

uniform int _mode = MODES;
uniform float _time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = screen_coords / vec2(love_ScreenSize);

    int mode = _mode >= MODES ? int(uv.x * MODES) : _mode;

    return wave(mode, _time, uv, color);
}
