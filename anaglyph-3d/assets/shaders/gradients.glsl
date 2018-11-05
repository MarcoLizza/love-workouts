struct Gradient {
    float threshold;
    vec3 color;
};

const Gradient[] GRADIENTS = Gradient[](
    Gradient(0.00, vec3(1.0, 0.0, 0.0)),
    //Gradient(0.25, vec3(1.0, 1.0, 0.0)),
    Gradient(0.40, vec3(1.0, 1.0, 1.0)),
    //Gradient(0.75, vec3(0.0, 1.0, 1.0)),
    Gradient(1.00, vec3(0.0, 0.0, 1.0))
);

uniform vec2 _origin;
uniform vec2 _size;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = texture2D(texture, texture_coords);

    vec2 uv = screen_coords / vec2(love_ScreenSize);

    if (uv.x <= 0.5) {
        uv = (screen_coords - _origin) / _size;
    }

    for (int i = GRADIENTS.length() - 2; i >= 0; --i) {
        Gradient current = GRADIENTS[i];
        Gradient next = GRADIENTS[i + 1];
        float delta = uv.y - current.threshold;
        if (delta >= 0.0) {
            float size = next.threshold - current.threshold;
            float alpha = delta / size;
            return vec4(mix(current.color, next.color, alpha), pixel.a);
        }
    }
    return pixel;
}
