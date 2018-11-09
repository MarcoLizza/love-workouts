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

#ifdef RGB_NOT_NATIVELY_LINEAR
float remove_gamma(float s) {
    float r = (s <= 0.04045) ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4);
    return clamp(r, 0.0, 1.0);
}

float apply_gamma(float s) {
    float r = (s <= 0.0031308) ? 12.92f * s : 1.055 * pow(s, 1 / 2.4) - 0.055;
    return clamp(r, 0.0, 1.0);
}
#endif

vec3 rgb_to_lsm(vec3 color) {
#ifdef RGB_NOT_NATIVELY_LINEAR
    vec3 rgb = vec3(remove_gamma(color.r), remove_gamma(color.g), remove_gamma(color.b)); // Convert to linear RGB.
#else
    vec3 rgb = color;
#endif
    mat3 m = mat3( // Linear RGB to LMS.
        0.31399022, 0.15537241, 0.01775239,
        0.63951294, 0.75789446, 0.10944209,
        0.04649755, 0.08670142, 0.87256922
    );
    return m * rgb;
}

vec3 lms_to_rgb(vec3 color) {
    mat3 m = mat3(
         5.47221206, -1.12524190,  0.02980165,
        -4.64196010,  2.29317094, -0.19318073,
         0.16963708, -0.16789520,  1.16364789
    );
    vec3 lms = m * color;
#if RGB_NOT_NATIVELY_LINEAR
    return vec3(apply_gamma(lms.r), apply_gamma(lms.g), apply_gamma(lms.b));
#else
    return lms;
#endif
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
    vec3 rgb = texture2D(texture, texture_coords).rgb;

    // Conversion of RGB coordinates into LMS, a color space suitable for calculating color blindness as it's
    // represented by the three types of cones of the human eye, named after their sensitivity at wavelengths;
    // Long (564–580nm), Medium (534–545nm) and Short (420–440nm).
    vec3 lms = rgb_to_lsm(rgb);

    // Simulation of color blindness by reducing the colors along a dichromatic confusion line, the line parallel to
    // the axis of the missing photoreceptor, to a single color.
    lms = daltonize(lms, _type);

    // Compensation for color blindness by shifting wavelengths away from the portion of the spectrum invisible to
    // the dichromat, towards the visible portion.
    lms = compensate(lms, _type);

    // Conversion of LMS coordinates back into RGB using the inverse of the RGB->LMS matrix.
    rgb = lms_to_rgb(lms);

    return vec4(rgb, 1.0);
}
