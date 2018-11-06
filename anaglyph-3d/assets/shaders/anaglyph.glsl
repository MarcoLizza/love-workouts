const float DISTANCE_MULTIPLIER = 4.0;

// https://pdfs.semanticscholar.org/1db2/b741bedb782b4b4b67ec8a648b7fecf58ef8.pdf
uniform Image _depth_map;
uniform float _offset = 0.0125;
uniform int _mode = 0;
uniform vec2 _vanishing_point = vec2(0.5, 0.5);

// http://3dtv.at/Knowhow/AnaglyphComparison_en.aspx
vec3 grey_anaglyph(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.299, 0.000, 0.000,
        0.587, 0.000, 0.000,
        0.114, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.299, 0.299,
        0.000, 0.587, 0.587,
        0.000, 0.114, 0.114
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 color_anaglyph(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 1.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 halfcolor_anaglyph(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.299, 0.000, 0.000,
        0.587, 0.000, 0.000,
        0.114, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 1.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 optimized_anaglyph(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.000, 0.000, 0.000,
        0.700, 0.000, 0.000,
        0.300, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 1.000
    );
    return pow(matrix_left * pixel_left + matrix_right * pixel_right, vec3(1.0 / 1.5, 1.0, 1.0)); // Gamma encoding, to correct RED component.
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 depth = texture2D(_depth_map, texture_coords);

    // Compute the x offset, basing of the depth map pixel (which is a black-and-white
    // image with back as "no offset" and white as "max offset").
    float factor = depth.r;
    float offset = factor * _offset;
    // Alse the distance from the vanishing point should be used control the offset.
    vec2 xy = screen_coords / vec2(love_ScreenSize);
    offset *= distance(xy, _vanishing_point) * DISTANCE_MULTIPLIER;

    // Negative offset for RED channel.
    vec2 uv_left = vec2(texture_coords.x - offset, texture_coords.y);
    vec2 uv_right = vec2(texture_coords.x + offset, texture_coords.y);

    vec3 pixel_left = texture2D(texture, uv_left).rgb;
    vec3 pixel_right = texture2D(texture, uv_right).rgb;

    vec3 pixel;
    if (_mode == 0) {
        pixel = grey_anaglyph(pixel_left, pixel_right);
    } else
    if (_mode == 1) {
        pixel = color_anaglyph(pixel_left, pixel_right);
    } else
    if (_mode == 2) {
        pixel = halfcolor_anaglyph(pixel_left, pixel_right);
    } else
    if (_mode == 3) {
        pixel = optimized_anaglyph(pixel_left, pixel_right);
    }
    return vec4(pixel, 1.0);
}
