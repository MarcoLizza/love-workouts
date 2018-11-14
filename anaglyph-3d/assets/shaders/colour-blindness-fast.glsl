uniform int _type = 0;

vec3 daltonize(vec3 color, int type) {
    mat3 m = mat3(1);
    if (type == 0) {
        m = mat3(
            1.0, 0.0, 0.0,
            0.0, 1.0, 0.0,
            0.0, 0.0, 1.0
        );
    } else
    if (type == 1) { // Protanope - reds are greatly reduced (1% men)
        m = mat3(
            0.56667, 0.55833, 0.00000,
            0.43333, 0.44167, 0.24167,
            0.00000, 0.00000, 0.75833
        );
    } else
    if (type == 2) { // Deuteranope - greens are greatly reduced (1% men)
        m = mat3(
            0.625, 0.70, 0.00,
            0.375, 0.30, 0.30,
            0.000, 0.00, 0.70
        );
    } else
    if (type == 3) { // Tritanope - blues are greatly reduced (0.003% population)
        m = mat3(
            0.95, 0.00000, 0.000,
            0.05, 0.43333, 0.475,
            0.00, 0.56667, 0.525
        );
    } else
    if (type == 4) { // Acromatopsia (Rod Monochromacy)
        m = mat3(
            0.299, 0.299, 0.299,
            0.587, 0.587, 0.587,
            0.114, 0.114, 0.114
        );
    }

    return m * color;
}

// Fast, but not very precise. Trinotapia is quite correct.

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec3 pixel = texture2D(texture, texture_coords).rgb;
    return vec4(daltonize(pixel, _type), 1.0);
}
