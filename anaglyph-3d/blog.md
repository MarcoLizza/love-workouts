## Anaglyph

## Stereo-vision

Parallax scrolling through shaders.

## Colour-blindness


## Shader chaining

Why doesn't GLSL support some kind og automatic shader chaining? Is a pre-compiler useful?

## Hot-reload

----

Interaction with other developers, albeit being feared by many, can be a huge stimulus. Ideas can be shared and since we `#gamedev` are a pretty weird race, one could find himself (or herself) **re**implementing a feature a fellow developer has just tackled down.

Some days ago, fellow `#gamedev` [Joe Tra](https://www.fistfulofsquid.com/) posted an update on Tweeter, telling everybody he was adding **hot-reload** support to its current engine (*Mr. Clops*, a really nice name for an engine if you ask me). It immediately occurred me that in many years of programming, and quite a few engines written, I never considered the idea to add support for *live synch* in my games. I'm so used in creating smaller *toy projects* when developing features, only to merge them later in my larger project(s), that I never considered that as a valid option. This was some sort of *D'ho!* moment for me, since in the last month only it could have saved a considerable amount of time spent tweaking fragment-shaders's code...

## What?

Since I'm currently using LOVE (for faster prototyping and since I don't want to clog my current laptop with a SSD-hog IDE), I could be tempted to implement *live editing* from the script level up. However, this might prove cumbersome due to the dynamic error handling. The side-effects of a reloaded script cannot easily predicted and we would end up in re-issuing the `love.load()` event, which is pretty much the same as restarting the application (but *less* safe). We can restrict script reload to a small portion of the script code-base, but that's not useful to be worth the effort.

Let's just focus on the **resources** used by the game. Actually, we are developing a *resource-manager*. They can be split in the following types

* images/textures,
* fonts,
* shaders,
* sounds/musics.

This should cover most of the scenarios when rapidly iterating the resource editing during development.

## How?

The key in implementing a *hot-reload* feature is **abstraction**, AKA when loading a resource you won't be referring to it through the native (ehm) handler, but via an alias (e.g. the name of the resource).

Since the resource could be potentially reloaded any time during the life-cycle of the application you simply can't store its runtime reference (e.g. the pointer to the bitmap it represents) since in case of reload it will be a *dangling reference* to something doens't exists anymore (this, of course, in the case your are not using an SDK/library that already tracks and handles the resource changes).

The solution to this is either query the resource-manager for actual resource handler each time you need or, or exploit some kind of event-based system that notifies to the interested listeners the new handler each time the resource changes.

For each resource we need to track

* the resource type (in order for the resource-manager to know how to "recreate" the resource when changed),
* the resource path and file,
* any additional parameters used when the resource was initially created (e.g. the font size),
* resource file modification time and content digest (to compare for changes).
* the list of current listeners for changes in the resource,
* the resource "native" handler

We choose to test both the resource file modification time **and** it's content (by storing it's hashed digest) to speed up the test phase: first we check if the file time has changed, then we load and check for changes in its content. Only if both values have changed we trigger a reload. Please note that, in any case, the latest (most recent) file modification time and content digest are stored and updated.

## Impact