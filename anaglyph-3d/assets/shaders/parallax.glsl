uniform int _speed;
uniform float _offset;
//uniform float _time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 offset = vec2(_speed * _offset, 0.0);
    vec2 uv = texture_coords + (offset / vec2(love_ScreenSize));
    return texture2D(texture, uv);
}
