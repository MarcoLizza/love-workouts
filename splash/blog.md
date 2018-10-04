Some days ago I was playing with some Lua code in order to implement a splash/boot screen inspired to the one developed by Nintendo for the *Game Boy*. A single-line text entering from the top of the screen and scrolling down until it reaches the center of it. Once on the final position a jingle is played.

Despite being a very basic assignment, it offers room for developing some interesting code. The most naïve approach requires very little code in order to achieve the desired result, and it would certainly work. With some additional effort we can develop some interesting and general code that can be reused in many other occasions. The most interesting part being how the text is moved through the screen, that is the *path* it follows. Rather than coding the path movement **inside** the `Message` object we are better off creating a `Path` object that implements it and that can be used by the former.

What kind of paths we need to implement? We'd like the path to be a sequence of segments. Segments are going to be **linear**, but **curved** ones can be useful. A very straightforward way to implement this is by means of [Bézier curves](https://en.wikipedia.org/wiki/B%C3%A9zier_curve). I'm not going to describe them here (I suggest you to follow the link to Wikipedia and read there), let's just say they are very appealing since by simple playing with the curve order one can go from linear to smooth curves.

Let's dive in some code and seem them in action.

```lua
function linear_bezier(p0, p1, t)
    local x = (1 - t) * p0[1] + t * p1[1]
    local y = (1 - t) * p0[2] + t * p1[2]
    return x, y
end

function quadratic_bezier(p0, p1, p2, t)
    local x = (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
    local y = (1 - t) * (1 - t) * p0[2] + 2 * (1 - t) * t * p1[2] + t * t * p2[2]
    return x, y
end

function cubic_bezier(p0, p1, p2, p3, t)
    local x = (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
    local y = (1 - t) * (1 - t) * p0[2] + 2 * (1 - t) * t * p1[2] + t * t * p2[2]
    return x, y
end
```

Easy, uh? A plain straightforward translation to Lua of the [Bernstein polynomial](https://en.wikipedia.org/wiki/Bernstein_polynomial) representing the Bézier curves.

Another method to accomplish this is with [De-Casteljua's algorithm](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm), which is in layman's word a recursive LERP between pairs of control points.

```lua
function lerp(a, b, t)
    return (1 - t) * a + t * b
end

function linear_bezier(p0, p1, t)
    local x = (1 - t) * p0[1] + t * p1[1]
    local y = (1 - t) * p0[2] + t * p1[2]
    return lerp(p0[1], p1[1], t), lerp(p0[2], p1[2], t)
end

function quadratic_bezier(p0, p1, p2, t)
    local p01 = { linear_bezier(p0, p1, t) }
    local p12 = { linear_bezier(p1, p2, t) }
    return linear_bezier(p01, p12, t)
end

function cubic_bezier(p0, p1, p2, p3, t)
    local p01 = { linear_bezier(p0, p1, t) }
    local p12 = { linear_bezier(p1, p2, t) }
    local p23 = { linear_bezier(p2, p3, t) }
    local p012 = { linear_bezier(p01, p12, t) }
    local p123 = { linear_bezier(p12, p23, t) }
    return linear_bezier(p012, p123, t)
end
```

However, this is going to give very bad performance and the code can be optimized quite a bit. I know that premature optimization is *evil*, but I am confident we can reach some elegant and efficient code with some effort. Here's a list of changes we can apply:

* the control point can be passed as a table (i.e. vector) for a more compact function signature,
* there's no need to pass the control points every time,
* we can avoid the recursion if we limit ourselves to some reasonable Bézier curve order (e.g. cubic) and use the Bernstein polynomial,
* some repeated math operations can be pre-computed and reused to save time,

Here's the resulting code, using closure and explicitly *unpacking* the vector for faster access to the points' components.

```lua
-- The function *compiles* a bézier curve evaluator, given the control points
-- (as two-element arrays). The aim of this function is to avoid passing the
-- control-control_points at each evaluation.
--
-- It supports linear, quadratic, and cubic béziers cuvers. The evaluators are
-- the following (with `u = 1 - t`)
--
-- B1(p0, p1, t) = u*p0 + t*p1
-- B2(p0, p1, p2, t) = u*u*p0 + 2*t*u*p1 + t*t*p2
-- B3(p0, p1, p2, p3, t) = u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3
local function compile_bezier(control_points)
  local n = #control_points
  if n == 4 then
    local p0, p1, p2, p3 = unpack(control_points)
    local p0x, p0y = unpack(p0)
    local p1x, p1y = unpack(p1)
    local p2x, p2y = unpack(p2)
    local p3x, p3y = unpack(p3)
    return function(t)
        local u = 1 - t
        local uu = u * u
        local tt = t * t
        local a = uu * u
        local b = 3 * uu * t
        local c = 3 * u * tt
        local d = t * tt
        local x = a * p0x + b * p1x + c * p2x + d * p3x
        local y = a * p0y + b * p1y + c * p2y + d * p3y
        return x, y
      end
  elseif n == 3 then
    local p0, p1, p2 = unpack(control_points)
    local p0x, p0y = unpack(p0)
    local p1x, p1y = unpack(p1)
    local p2x, p2y = unpack(p2)
    return function(t)
        local u = 1 - t
        local a = u * u
        local b = 2 * t * u
        local c = t * t
        local x = a * p0x + b * p1x + c * p2x
        local y = a * p0y + b * p1y + c * p2y
        return x, y
      end
  elseif n == 2 then
    local p0, p1 = unpack(control_points)
    local p0x, p0y = unpack(p0)
    local p1x, p1y = unpack(p1)
    return function(t)
        local u = 1 - t
        local x = u * p0x + t * p1x
        local y = u * p0y + t * p1y
        return x, y
      end
  else
    error('Beziér curves are supported up to 3rd order.')
  end
end
```

There are other methods? Yes, we can represent the curve as polynomial (non-Bernstein) form. The benefits of this is the coefficients can be pre-computed and reused for many curves. However this approach, while teoretically faster, lack the numerical stability of the [De-Casteljua's algorithm](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm).


Of course, **LOVE2D** math API has a specific Bézier 