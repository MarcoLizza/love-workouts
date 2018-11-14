uniform Image _left;
uniform Image _right;
uniform int _mode = 0;

// Intro, why binocular 3d perception works on retinal disparity.
// https://en.wikipedia.org/wiki/Anaglyph_3D
// http://www.david-romeuf.fr/3D/Anaglyphes/MontageFenetreVolume/AnaglyphAssemblyWindowsVolume.html
// http://courses.washington.edu/psy333/lecture_pdfs/Week7_Day3.pdf
// https://blog.spoongraphics.co.uk/tutorials/how-to-create-anaglyph-3d-images-that-really-work

// The greater the disparity, the closer the objects. This is easily seen in parallax scrolling.

// http://3dtv.at/Knowhow/AnaglyphComparison_en.aspx
// https://www.dpreview.com/forums/thread/3845115

// DUBOIS
// https://ixora.io/projects/camera-3D/dubois-anaglyphs/
// https://github.com/hx2A/Camera3D/blob/master/src/camera3D/generators/AnaglyphGenerator.java
vec3 redblue_grey(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.299, 0.000, 0.000,
        0.587, 0.000, 0.000,
        0.114, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.299,
        0.000, 0.000, 0.587,
        0.000, 0.000, 0.114
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 redgreen_grey(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.299, 0.000, 0.000,
        0.587, 0.000, 0.000,
        0.114, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.299, 0.000,
        0.000, 0.587, 0.000,
        0.000, 0.114, 0.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

// UNPOPULAR, TOO MUCH DISPARITY IN COLOR SENSITIVITY BETWEEN BLUE AND GREEN?
vec3 bluegreen_grey(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.000, 0.000, 0.299,
        0.000, 0.000, 0.587,
        0.000, 0.000, 0.114
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.299, 0.000,
        0.000, 0.587, 0.000,
        0.000, 0.114, 0.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 redcyan_grey(vec3 pixel_left, vec3 pixel_right) {
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

vec3 redcyan_color(vec3 pixel_left, vec3 pixel_right) {
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

vec3 redcyan_halfcolor(vec3 pixel_left, vec3 pixel_right) {
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

// https://ixora.io/projects/camera-3D/dubois-anaglyphs/
// https://github.com/hx2A/Camera3D/blob/master/src/camera3D/generators/AnaglyphGenerator.java
vec3 redcyan_dubois(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.437, -0.062, -0.048,
        0.449, -0.062, -0.050,
        0.164, -0.024, -0.017
    );
    mat3 matrix_right = mat3( // Column first.
        -0.011, 0.377, -0.026,
        -0.032, 0.761, -0.093,
        -0.007, 0.009,  1.234
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 amberblue_grey(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.299, 0.299, 0.000,
        0.587, 0.587, 0.000,
        0.114, 0.114, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.299,
        0.000, 0.000, 0.587,
        0.000, 0.000, 0.114
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 amberblue_color(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 0.000, 1.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

// ColorCode 3-D, a stereoscopic color scheme, uses the RG color space to simulate a broad spectrum of color in one eye; the blue portion of the spectrum transmits a black-and-white (black-and-blue) image to the other eye to give depth perception.
vec3 amberblue_halfcolor(vec3 pixel_left, vec3 pixel_right) { // i.e. ColorCode-3D
    mat3 matrix_left = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.299,
        0.000, 0.000, 0.587,
        0.000, 0.000, 0.114
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 amberblue_dubois(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
         1.062, -0.026, -0.038,
        -0.205,  0.908, -0.173,
         0.299,  0.068,  0.022
    );
    mat3 matrix_right = mat3( // Column first.
        -0.016,  0.006, 0.094,
        -0.123,  0.062, 0.185,
        -0.017, -0.017, 0.911
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 magentagreen_grey(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        0.299, 0.000, 0.299,
        0.587, 0.000, 0.587,
        0.114, 0.000, 0.114
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.299, 0.000,
        0.000, 0.587, 0.000,
        0.000, 0.114, 0.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 magentagreen_color(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 0.000, 1.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 0.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

// trioscopics3d
vec3 magentagreen_halfcolor(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 0.000, 1.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.299, 0.000,
        0.000, 0.587, 0.000,
        0.000, 0.114, 0.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 magentagreen_dubois(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        -0.062, 0.284, -0.015,
        -0.158, 0.668, -0.027,
        -0.039, 0.143,  0.021
    );
    mat3 matrix_right = mat3( // Column first.
        0.529, -0.016, 0.009,
        0.705, -0.015, 0.075,
        0.024, -0.065, 0.937
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec3 magentayellow_color(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 0.000, 1.000
    );
    mat3 matrix_right = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 0.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}
vec3 magentacyan_color(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 0.000, 0.000,
        0.000, 0.000, 1.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 1.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}
vec3 yellowcyan_color(vec3 pixel_left, vec3 pixel_right) {
    mat3 matrix_left = mat3( // Column first.
        1.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 0.000
    );
    mat3 matrix_right = mat3( // Column first.
        0.000, 0.000, 0.000,
        0.000, 1.000, 0.000,
        0.000, 0.000, 1.000
    );
    return matrix_left * pixel_left + matrix_right * pixel_right;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec3 pixel_left = texture2D(_left, texture_coords).rgb;
    vec3 pixel_right = texture2D(_right, texture_coords).rgb;

    vec3 pixel;
    if (_mode == 0) {
        pixel = texture2D(texture, texture_coords).rgb;
    } else
    if (_mode == 1) {
        pixel = redblue_grey(pixel_left, pixel_right);
    } else
    if (_mode == 2) {
        pixel = redgreen_grey(pixel_left, pixel_right);
    } else
    if (_mode == 3) {
        pixel = bluegreen_grey(pixel_left, pixel_right);
    } else
    if (_mode == 4) {
        pixel = redcyan_grey(pixel_left, pixel_right);
    } else
    if (_mode == 5) {
        pixel = redcyan_color(pixel_left, pixel_right);
    } else
    if (_mode == 6) {
        pixel = redcyan_halfcolor(pixel_left, pixel_right);
    } else
    if (_mode == 7) {
        pixel = redcyan_dubois(pixel_left, pixel_right);
    } else
    if (_mode == 8) {
        pixel = amberblue_grey(pixel_left, pixel_right);
    } else
    if (_mode == 9) {
        pixel = amberblue_color(pixel_left, pixel_right);
    } else
    if (_mode == 10) {
        pixel = amberblue_halfcolor(pixel_left, pixel_right);
    } else
    if (_mode == 11) {
        pixel = amberblue_dubois(pixel_left, pixel_right);
    } else
    if (_mode == 12) {
        pixel = magentagreen_grey(pixel_left, pixel_right);
    } else
    if (_mode == 13) {
        pixel = magentagreen_color(pixel_left, pixel_right);
    } else
    if (_mode == 14) {
        pixel = magentagreen_halfcolor(pixel_left, pixel_right);
    } else
    if (_mode == 15) {
        pixel = magentagreen_dubois(pixel_left, pixel_right);
    } else
    if (_mode == 16) {
        pixel = magentayellow_color(pixel_left, pixel_right);
    } else
    if (_mode == 17) {
        pixel = magentacyan_color(pixel_left, pixel_right);
    } else
    if (_mode == 18) {
        pixel = yellowcyan_color(pixel_left, pixel_right);
    }
    return vec4(pixel, 1.0);
}
