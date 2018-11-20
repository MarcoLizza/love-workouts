/*

void main( )
{
ivec2 ires = textureSize( uImageUnit, 0 );
float ResS = float( ires.s );
float ResT = float( ires.t );
vec3 irgb = texture( uImageUnit, vST ).rgb;
vec3 brgb = texture( uBeforeUnit, vST ).rgb;
vec3 argb = texture( uAfterUnit, vST ).rgb;
vec3 rgb = texture( uImageUnit, vST ).rgb;
vec2 stp0 = vec2(1./uResS, 0. );
vec2 st0p = vec2(0. , 1./uResT);
vec2 stpp = vec2(1./uResS, 1./uResT);
vec2 stpm = vec2(1./uResS, -1./uResT);
const vec3 W = vec3( 0.2125, 0.7154, 0.0721 );
float i00 = dot( texture( uImageUnit, vST).rgb, W );
float im1m1 = dot( texture( uImageUnit, vST-stpp ).rgb, W );
float ip1p1 = dot( texture( uImageUnit, vST+stpp ).rgb, W );
float im1p1 = dot( texture( uImageUnit, vST-stpm ).rgb, W );
float ip1m1 = dot( texture( uImageUnit, vST+stpm ).rgb, W );
float im10 = dot( texture( uImageUnit, vST-stp0 ).rgb, W );
float ip10 = dot( texture( uImageUnit, vST+stp0 ).rgb, W );
float i0m1 = dot( texture( uImageUnit, vST-st0p ).rgb, W );
float i0p1 = dot( texture( uImageUnit, vST+st0p ).rgb, W );
// next two lines apply the H and V Sobel filters at the pixel
float h= -1.*im1p1-2.*i0p1-1.*ip1p1+1.*im1m1+2.*i0m1+1.*ip1m1;
float v= -1.*im1m1-2.*im10-1.*im1p1+1.*ip1m1+2.*ip10+1.*ip1p1;
float mag = length( vec2( h, v ) ); // how much change
// is there?
if( mag > uMagTol )
{ // if too much, use black
fFragColor = vec4( 0., 0., 0., 1. );
}
else
{ // else quantize the color
rgb.rgb *= uQuantize;
rgb.rgb += vec3( .5, .5, .5 ); // round
ivec3 intrgb = ivec3( rgb.rgb ); // truncate
rgb.rgb = vec3( intrgb ) / Quantize;
fFragColor = vec4( rgb, 1. );
}
}

*/

/*
Calculate the luminance of each pixel.
2. Apply the Sobel edge-detection filter and get a magnitude.
3. If magnitude > threshold, color the pixel black
4. Else, quantize the pixel’s color.
5. Output the colored pixel.
*/


// const vec3 WEIGHT = vec3(0.2126, 0.7152, 0.0722); // ITU-R BT.709 (CIE 1931 LUMINANCE if linear)
const vec4 WEIGHT = vec4(0.299, 0.587, 0.114, 0.0); // rec601 luma
// const vec3 WEIGHT = vec3(0.2627, 0.6780, 0.0593); // ITU-R BT.2100 for HDR

void kernel(inout float Y[9], Image image, vec2 center, float width, float height) {
    float h_step = 1.0 / width;
    float v_step = 1.0 / height;

    Y[0] = dot(texture2D(image, center + vec2(-h_step, -v_step)), WEIGHT);
    Y[1] = dot(texture2D(image, center + vec2(0.0, -v_step)), WEIGHT);
    Y[2] = dot(texture2D(image, center + vec2( h_step, -v_step)), WEIGHT);
    Y[3] = dot(texture2D(image, center + vec2(-h_step, 0.0)), WEIGHT);
    Y[4] = dot(texture2D(image, center + vec2(0.0, 0.0)), WEIGHT);
    Y[5] = dot(texture2D(image, center + vec2( h_step, 0.0)), WEIGHT);
    Y[6] = dot(texture2D(image, center + vec2(-h_step,  v_step)), WEIGHT);
    Y[7] = dot(texture2D(image, center + vec2(0.0,  v_step)), WEIGHT);
    Y[8] = dot(texture2D(image, center + vec2( h_step,  v_step)), WEIGHT);
}

uniform float _width = 1.0;
uniform float _height = 1.0;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = texture2D(texture, texture_coords);

    float Y[9];
    kernel(Y, texture, texture_coords, _width, _height);

    float h_sobel = Y[0] - Y[2] + 2.0 * Y[3] - 2.0 * Y[5] + Y[6] - Y[8];
    float v_sobel = Y[0] + 2.0 * Y[1] + Y[2] - Y[6] - 2.0 * Y[7] - Y[8];

    float sobel = sqrt(h_sobel * h_sobel + v_sobel * v_sobel);

    if (sobel > 0.25) {
        return vec4(0.0, 0.0, 0.0, pixel.a);
    }
    return pixel;
}
