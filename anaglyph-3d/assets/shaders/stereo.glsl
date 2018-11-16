uniform Image _left;
uniform Image _right;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / vec2(love_ScreenSize.xy);

    if (uv.x < 0.5) {
        return texture2D(_left, vec2(uv.x * 2.0, uv.y));
    } else {
        return texture2D(_right, vec2((uv.x - 0.5) * 2.0, uv.y));
    }
}
