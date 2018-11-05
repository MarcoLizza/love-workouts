uniform float _time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = vec2(texture_coords.x + cos(_time), texture_coords.y + sin(_time));
    return texture2D(texture, uv);
}
