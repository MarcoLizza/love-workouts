uniform Image _depth_map;
uniform float _time;

float offset(vec4 depth) {

    return depth.r * 

}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
//    vec2 uv = screen_coords / vec2(love_ScreenSize);

    vec4 depth = texture2D(_depth_map, texture_coords);
    float time = _time;

    vec4 pixel = texture2D(texture, texture_coords);
    return pixel;
}
