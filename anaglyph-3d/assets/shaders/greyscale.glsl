// The input is defined as linear-RGB, the output linear luminance Y.
//
// https://en.wikipedia.org/wiki/Grayscale
// const vec3 WEIGHT = vec3(0.2126, 0.7152, 0.0722); // ITU-R BT.709 (CIE 1931 LUMINANCE if linear)
const vec3 WEIGHT = vec3(0.299, 0.587, 0.114); // rec601 luma
// const vec3 WEIGHT = vec3(0.2627, 0.6780, 0.0593); // ITU-R BT.2100 for HDR

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = texture2D(texture, texture_coords);
    float y = dot(pixel.rgb, WEIGHT);
    return vec4(y, y, y, pixel.a);
}
