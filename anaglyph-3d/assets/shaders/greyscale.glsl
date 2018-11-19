vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = texture2D(texture, texture_coords);
    float y = 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
    return vec4(y, y, y, pixel.a);
}
