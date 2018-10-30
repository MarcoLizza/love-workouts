const vec3[] PALETTE = vec3[](
        vec3(1.0, 0.0, 0.0),
        vec3(1.0, 1.0, 0.0),
        vec3(0.0, 1.0, 1.0),
        vec3(0.0, 0.0, 1.0),
        vec3(1.0, 0.0, 1.0),
        vec3(1.0, 1.0, 1.0)
    );

const int LINE_HEIGHT = 16;

uniform float _time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    float height = LINE_HEIGHT;
    height += sin(_time) * 8;
    
    float run = height * love_ScreenSize.x;
    run += cos(_time) * (love_ScreenSize.x / 4.0);

    float v = ((screen_coords.y + _time * 333.3) * love_ScreenSize.x) + (screen_coords.x + _time * 3333.3);
    int index = int(mod(v / run, PALETTE.length()));
    return vec4(PALETTE[index], 1.0);
}
