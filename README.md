# Particle system for OpenFl

Features:

 - Can load files from Particle Designer or [Particle Designer 2](https://71squared.com/en/particledesigner).
 - Has drawTiles renderer along with GL renderer.

**NOTE: work in progress, more features coming.**

## Export notes

Embedded textures is not supported, so you must **uncheck** "embed" before export.
![](http://blog.zame-dev.org/wp-content/uploads/2015/02/particledesigner.png)

## Renderer notes

GL renderer is the best choise for html5 (with -Ddom) - it support many features and super fast. It use "hacked" version of OpenGLView to be able to add canvas with proper z-index. [html5-dom demo](http://blog.zame-dev.org/pub/particles/html5-dom-v2/).

However GL renderer is available **only** for html with `-Ddom`.

For all other targets use drawTiles renderer:

  - html5 in canvas mode - still pretty fast, doesn't support color effects. Can render incorrectly due to bug in openfl, please apply [this patch](https://github.com/openfl/openfl/pull/434) if you encounter it. [html5-canvas demo](http://blog.zame-dev.org/pub/particles/html5-canvas-v2/).
  - native - fast, support color effects, hovewer in some cases GL renderer looks better.
  - flash - slow, can be buggy (due to drawTiles implementation in openfl). [flash demo](http://blog.zame-dev.org/pub/particles/flash-v2.swf).

## How to use

Open terminal, go to some folder (if you want to), than:

```
git clone git@github.com:restorer/zame-haxe-particles.git
haxelib dev zame-particles ./zame-haxe-particles
```

This library depends on zame-miscutils. If you don't have them, do this:

```
git clone git@github.com:restorer/zame-haxe-miscutils.git
haxelib dev zame-miscutils ./zame-haxe-miscutils
```

#### Now you can create beautiful things

First of all, append following to your project.xml:

```xml
<haxelib name="zame-miscutils" />
<haxelib name="zame-particles" />
```

If you plan to load particles from .json, append also:

```xml
<haxedef name="haxeJSON" />
```

Next, in code, create particle renderer and add it as child to container:

```haxe
var renderer = new DefaultParticleRenderer();
addChild(cast renderer);
```

Than load particle emitter config from file, and add loaded particle system to renderer:

```haxe
var ps = ParticleLoader.load("particle/fire.plist");
renderer.addParticleSystem(ps);
```

Finally, call emit() where you need:

```
ps.emit(stage.stageWidth / 2, stage.stageHeight / 2);
```

**There is minimal example under samples/minimal.**

## Roadmap for future

- [x] Support for .json output format
- [x] Support for .lap and .pex output formats
- [ ] Support for embedded textures
- [ ] Create importer for particles in luxeengine
- [ ] Support for lime / snow directly without openfl / luxeengine
- [ ] Support for HaxeFlixel and / or HaxePunk?
