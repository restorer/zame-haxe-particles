# Particle system for OpenFl

![](http://blog.zame-dev.org/wp-content/uploads/2015/02/Screen-Shot-2015-02-11-at-17.43.16.png)

[Demo](http://blog.zame-dev.org/pub/particles/html5-dom-v3/)

Features:

 - Can load files from Particle Designer or [Particle Designer 2](https://71squared.com/en/particledesigner).
 - Support for embedded textures, both zipped or not.
 - Can load files from [Starling Particle Editor](http://onebyonedesign.com/flash/particleeditor/).
 - Has 3 renderers - sprites, drawTiles, and GL renderer.

**NOTE: work in progress, more features coming.**

## Installation

```
haxelib git zame-particles https://github.com/restorer/zame-haxe-particles.git
haxelib git zame-miscutils https://github.com/restorer/zame-haxe-miscutils.git
```

## Usage

First of all, append following to your project.xml:

```xml
<haxelib name="format" />
<haxelib name="zame-miscutils" />
<haxelib name="zame-particles" />
<haxedef name="haxeJSON" />
```

Next, in code, create particle renderer and add it as child to container:

```haxe
var renderer = DefaultParticleRenderer.createInstance();
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

**See minimal example under samples/minimal for more info.**

## Export notes

Embedded textures is **supported**, hovewer it is not recommended to use them for large images. For large texture images it is recommended to **uncheck** "embed" before export.

![](http://blog.zame-dev.org/wp-content/uploads/2015/02/particledesigner.png)

## Renderer notes

  - html5 with `-Ddom` (GL renderer) - [link](http://blog.zame-dev.org/pub/particles/html5-dom-v3/)
  - html5 in canvas mode (drawTiles renderer) - [link](http://blog.zame-dev.org/pub/particles/html5-canvas-v3/)
  - flash (sprites renderer) - [link](http://blog.zame-dev.org/pub/particles/flash-v3.swf)

GL renderer is the best choise for html5 (with `-Ddom`) - it support many features and super fast. It use "hacked" version of OpenGLView to be able to add canvas with proper z-index. However GL renderer is available **only** for html with `-Ddom`.

Sprites renderer is best for flash, because it support color effects via ColorTransform. But this renderer is slow.

All other targets should use drawTiles renderer:

  - html5 in canvas mode - still pretty fast, doesn't support color effects. Can render incorrectly due to bug in openfl, please apply [this patch](https://github.com/openfl/openfl/pull/434) if you encounter it.
  - native - fast, support color effects, hovewer in some cases GL renderer looks better.

## Roadmap for future

- [x] Support for .json output format
- [x] Support for .lap and .pex output formats
- [x] Support for embedded textures
- [x] Create importer for particles in luxeengine
- [x] Implement SpritesRenderer
- [ ] Support for lime / snow directly without openfl / luxeengine
- [ ] Support for HaxeFlixel and / or HaxePunk?
