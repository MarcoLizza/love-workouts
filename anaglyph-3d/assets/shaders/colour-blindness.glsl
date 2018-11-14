uniform int _type = 0;

/**
 *
 * https://ixora.io/projects/colorblindness/color-blindness-simulation-research/
 * https://tylerdavidhoward.com/thesis/
 *
 * There are four different kinds of visual impairment that pertains the color perception. Three of them are called
 * DICROMACIES, that is the lack (or reduced) of one type of cone
 *
 * https://www.color-blindness.com/protanopia-red-green-color-blindness/
 * https://www.color-blindness.com/deuteranopia-red-green-color-blindness/
 * https://www.color-blindness.com/tritanopia-blue-yellow-color-blindness/
 *
 *   - pronanomaly (red-green colour blindness, lack of red, 1% of males)
 *   - deuteranomaly (red-green colour blindness, lack of green, 1% of males)
 *   - tritanomaly (blue-yellow colour blindness, lack of blue, <1% of males)
 *
 * The last anomaly is called ACHROMATOPIA, which translates to see only in black-and-white (or, more generally, a
 * monocrhomatic vision with grades of a single color).
 *
 * The deficience is sex-related, since the anomaly is carried by the X chromosome (and females have two of them
 * reducing the impact). Daughers of a male red-green colour-blind will carry on the anomaly to their male children with
 * a 50% probability.
 *
 * Unluckily we are not mantis shrimps (which have 12 to 16 different photoreceptors).
 *
 * The classic mode, used in many shaders, if really wrong in rendering the tritanopia.
*/

// http://brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
//#define CLASSIC_MODE   1
#define RGB_NOT_NATIVELY_LINEAR   1
//#define USE_CIE_RGB 1

// http://biecoll.ub.uni-bielefeld.de/volltexte/2007/52/pdf/ICVS2007-6.pdf
// https://arxiv.org/pdf/1711.10662.pdf
#ifdef CLASSIC_MODE

// https://web.archive.org/web/20180323160018/http://blog.noblemaster.com/2013/10/26/opengl-shader-to-correct-and-simulate-color-blindness-experimental/
// http://web.archive.org/web/20081014161121/http://www.colorjack.com/labs/colormatrix/

vec3 rgb_to_lsm(vec3 color) {
    mat3 m = mat3(
        17.88240,  3.45565, 0.0299566,
        43.51610, 27.15540, 0.1843090,
         4.11935,  3.86714, 1.4670900
    );
    return m * color;
}

vec3 lms_to_rgb(vec3 color) {
    mat3 m = mat3(
         0.0809444479, -0.0102485335, -0.000365296938,
        -0.1305044090,  0.0540193266, -0.004121614690,
         0.1167210660, -0.1136147080,  0.693511405000
    );
    return m * color;
}

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
             0.00000, 0.0, 0.0,
             2.02344, 1.0, 0.0,
            -2.52581, 0.0, 1.0
        );
    } else
    if (type == 2) { // Deuteranope - greens are greatly reduced (1% men)
        m = mat3(
            1.0, 0.494207, 0.0,
            0.0, 0.000000, 0.0,
            0.0, 1.248270, 1.0
        );
    } else
    if (type == 3) { // Tritanope - blues are greatly reduced (0.003% population)
        m = mat3(
            1.0, 0.0, -0.395913,
            0.0, 1.0,  0.801109,
            0.0, 0.0,  0.000000
        );
    }

    return m * color;
}

#else // CLASSIC_MODE

float remove_gamma(float s) {
    float r = (s <= 0.04045) ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4);
    return r;//clamp(r, 0.0, 1.0);
}

float apply_gamma(float s) {
    float r = (s <= 0.0031308) ? 12.92 * s : 1.055 * pow(s, 1 / 2.4) - 0.055;
    return r;//clamp(r, 0.0, 1.0);
}

// https://www.image-engineering.de/library/technotes/958-how-to-convert-between-srgb-and-ciexyz
/*
// Converts a color from linear light gamma to sRGB gamma
vec3 fromLinear(vec4 linearRGB)
{
    bvec3 cutoff = lessThan(linearRGB, vec3(0.0031308));
    vec3 higher = vec4(1.055)*pow(linearRGB, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB * vec3(12.92);

    return mix(higher, lower, cutoff);
}

// Converts a color from sRGB gamma to linear light gamma
vec3 toLinear(vec3 sRGB)
{
    bvec3 cutoff = lessThan(sRGB, vec3(0.04045));
    vec3 higher = pow((sRGB + vec3(0.055))/vec3(1.055), vec3(2.4));
    vec3 lower = sRGB/vec3(12.92);

    return mix(higher, lower, cutoff);
}
*/
// https://en.wikipedia.org/wiki/SRGB
// http://www.brucelindbloom.com/index.html?Eqn_RGB_to_XYZ.html
// http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_RGB.html
vec3 srgb_to_rgb(vec3 srgb) {
    return vec3(remove_gamma(srgb.r), remove_gamma(srgb.g), remove_gamma(srgb.b)); // sRGB to Linear RGB.
}

// https://en.wikipedia.org/wiki/CIE_1931_color_space
// http://www.brucelindbloom.com/index.html?Eqn_RGB_to_XYZ.html
vec3 rgb_to_xyz(vec3 rgb) {
#ifdef USE_CIE_RGB
    mat3 m = mat3( // Linear RGB to XYZ.
        0.49000, 0.17697, 0.00000,
        0.31000, 0.81240, 0.01063,
        0.20000, 0.01063, 0.99000
    );
    return (m * rgb) / 0.17697;
#else
    mat3 m = mat3( // Linear RGB to XYZ.
        0.4124564, 0.2126729, 0.0193339,
        0.3575761, 0.7151522, 0.1191920,
        0.1804375, 0.0721750, 0.9503041
    );
    return m * rgb;
#endif
}

// https://en.wikipedia.org/wiki/LMS_color_space
vec3 xyz_to_lsm(vec3 xyz) {
    mat3 m = mat3( // XYZ to LMS (Hunt-Pointer-Estevez)
         0.4002, -0.2263, 0.0000,
         0.7076,  1.1653, 0.0000,
        -0.0808,  0.0457, 0.9182
    );
    return m * xyz;
}

vec3 lms_to_xyz(vec3 lms) {
    mat3 m = mat3( // XYZ to LMS (Hunt-Pointer-Estevez)
         1.8600670,  0.3612229, 0.000000,
        -1.1294800,  0.6388043, 0.000000,
         0.2198983, -0.000007127501, 1.089087
    );
    return m * lms;
}

vec3 xyz_to_rgb(vec3 xyz) {
#ifdef USE_CIE_RGB
    mat3 m = mat3( // XYZ to Linear RGB.
         0.41847,  -0.091169,  0.00092090,
        -0.15866,   0.25243,  -0.0025498,
        -0.082835,  0.015708,  0.17860
    );
    return m * xyz;
#else
    mat3 m = mat3( // XYZ to Linear RGB.
         3.2404542, -0.9692660,  0.0556434,
        -1.5371385,  1.8760108, -0.2040259,
        -0.4985314,  0.0415560,  1.0572252
    );
    return m * xyz;
#endif
}

vec3 rgb_to_srgb(vec3 rgb) {
    return vec3(apply_gamma(rgb.r), apply_gamma(rgb.g), apply_gamma(rgb.b)); // Linear RGB to sRGB.
}

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
             0.00000000, 0.0, 0.0,
             1.05118294, 1.0, 0.0,
            -0.05116099, 0.0, 1.0
        );
    } else
    if (type == 2) { // Deuteranope - greens are greatly reduced (1% men)
        m = mat3(
            1.0, 0.95130920, 0.0,
            0.0, 0.00000000, 0.0,
            0.0, 0.04866992, 1.0
        );
    } else
    if (type == 3) { // Tritanope - blues are greatly reduced (0.003% population)
        m = mat3(
            1.0, 0.0, -0.86744736,
            0.0, 1.0,  1.86727089,
            0.0, 0.0,  0.00000000
        );
    } else
    if (type == 4) { // Acromatopsia (Rod Monochromacy)
        m = mat3(
            0.212656, 0.212656, 0.212656,
            0.715158, 0.715158, 0.715158,
            0.072186, 0.072186, 0.072186
        );
    } else
    if (type == 5) { // Blue-cone monochromacy
        m = mat3(
            0.01775, 0.01775, 0.01775,
            0.10945, 0.10945, 0.10945,
            0.87262, 0.87262, 0.87262
        );
    }

    return m * color;
}

#endif  // CLASSIC_MODE

vec3 compensate(vec3 lms, int type) {
    return lms;
}

// https://web.archive.org/web/20180815090300/http://www.daltonize.org/search/label/Daltonize
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
#ifdef RGB_NOT_NATIVELY_LINEAR
    vec3 srgb = texture2D(texture, texture_coords).rgb;
    vec3 rgb = srgb_to_rgb(srgb);
#else
    vec3 rgb = texture2D(texture, texture_coords).rgb;
#endif

    // Conversion of RGB coordinates into LMS, a color space suitable for calculating color blindness as it's
    // represented by the three types of cones of the human eye, named after their sensitivity at wavelengths;
    // Long (564–580nm), Medium (534–545nm) and Short (420–440nm).
    vec3 xyz = rgb_to_xyz(rgb);
    vec3 lms = xyz_to_lsm(xyz);

    // Simulation of color blindness by reducing the colors along a dichromatic confusion line, the line parallel to
    // the axis of the missing photoreceptor, to a single color.
    lms = daltonize(lms, _type);

    // Compensation for color blindness by shifting wavelengths away from the portion of the spectrum invisible to
    // the dichromat, towards the visible portion.
    lms = compensate(lms, _type);

    // Conversion of LMS coordinates back into RGB using the inverse of the RGB->LMS matrix.
    xyz = lms_to_xyz(lms);
    rgb = xyz_to_rgb(xyz);

#ifdef RGB_NOT_NATIVELY_LINEAR
    srgb = rgb_to_srgb(rgb);
    return vec4(srgb, 1.0);
#else
    return vec4(rgb, 1.0);
#endif
}
