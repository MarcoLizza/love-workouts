/*
 * Calculate the luminance of each pixel.
 * 2. Apply the Sobel edge-detection filter and get a magnitude.
 * 3. If magnitude > threshold, color the pixel black
 * 4. Else, quantize the pixel’s color.
 * 5. Output the colored pixel.
 */
#ifndef TWEAKED_SOBEL
const mat3 sx = mat3( 
    1.0, 2.0, 1.0, 
    0.0, 0.0, 0.0, 
    -1.0, -2.0, -1.0 
);
const mat3 sy = mat3( 
    1.0, 0.0, -1.0, 
    2.0, 0.0, -2.0, 
    1.0, 0.0, -1.0 
);
#else
const mat3 sx = mat3( 
    3.0, 10.0, 3.0, 
    0.0, 0.0, 0.0, 
    -3.0, -10.0, -3.0 
);
const mat3 sy = mat3( 
    3.0, 0.0, -3.0, 
    10.0, 0.0, -10.0, 
    3.0, 0.0, -3.0 
);
#endif

const vec3 WEIGHT = vec3(0.2125, 0.7154, 0.0721);
// const vec3 WEIGHT = vec3(0.2126, 0.7152, 0.0722); // ITU-R BT.709 (CIE 1931 LUMINANCE if linear)
// const vec3 WEIGHT = vec3(0.299, 0.587, 0.114); // rec601 luma
// const vec3 WEIGHT = vec3(0.2627, 0.6780, 0.0593); // ITU-R BT.2100 for HDR

uniform vec2 _step;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec3 diffuse = texture2D(texture, texture_coords).rgb;

    mat3 I;
    for (int i = 0; i < 3; i++) {
        float x = _step.x * (i - 1);
        for (int j = 0; j < 3; j++) {
            float y = _step.y * (j - 1);
            I[i][j] = dot(texture2D(texture, texture_coords + vec2(x, y)).rgb, WEIGHT);
        }
    }

    float gx = dot(sx[0], I[0]) + dot(sx[1], I[1]) + dot(sx[2], I[2]); 
    float gy = dot(sy[0], I[0]) + dot(sy[1], I[1]) + dot(sy[2], I[2]);

    float g = sqrt(pow(gx, 2.0)+pow(gy, 2.0));

    g = smoothstep(0.50, 1.00, g);

    return vec4(mix(diffuse, vec3(0.0, 0.0, 0.0), g), 1.);
}
