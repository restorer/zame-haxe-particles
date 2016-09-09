# Particle system for OpenFl

*(and for KHA, see below)*

![](http://blog.zame-dev.org/wp-content/uploads/2015/03/Screen-Shot-2015-03-18-at-12.53.43.png)

[Demo](http://blog.zame-dev.org/pub/particles/html5-dom-v3/)

Features:

 - Can load files from Particle Designer or [Particle Designer 2](https://71squared.com/en/particledesigner).
 - Support for embedded textures, both zipped or not.
 - Can load files from [Starling Particle Editor](http://onebyonedesign.com/flash/particleeditor/).
 - Has 5 renderers - sprites, drawTiles (OpenFL 3) / tilemap (OpenFL 4), stage3d (OpenFL 4), and GL renderer.

**NOTE: work in progress, more features coming.**

## Important note about OpenFL 4

**Tilesheet and tilemap**

Tilesheet support was removed from OpenFL 4 in favour of new Tilemap / Tilesheet classes. That's fine, but:

- new API doesn't support rotating about arbitrary pivot point (however this can be achieved by direct modification of transform matrix);
- new API doesn't support color transform;
- new API doesn't support blending modes.

You can use this renderer, it fast, but ugly.

**Sprites**

Work well for flash, work very slow for other targets (http://community.openfl.org/t/openfl-4-sprites-and-or-haxe-3-3-slow-as-hell/8132).

**GL renderer**

Still work fine, but only for html5 and only in `-Ddom` mode.

## Installation

Stable version from haxelib:

```
haxelib install zame-particles
```

Latest development version:

```
haxelib git zame-particles https://github.com/restorer/zame-haxe-particles.git
```

## Usage

First of all, append following to your project.xml:

```xml
<haxedef name="haxeJSON" />
<haxelib name="zame-particles" />
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

If you have multiple particle systems (particle emitters), you should use only one renderer for them:

```
var renderer = DefaultParticleRenderer.createInstance();
addChild(cast renderer);

var ps1 = ParticleLoader.load("particle/ps1.plist");
renderer.addParticleSystem(ps1);

var ps2 = ParticleLoader.load("particle/ps2.plist");
renderer.addParticleSystem(ps2);

var ps3 = ParticleLoader.load("particle/ps3.plist");
renderer.addParticleSystem(ps3);
```

In some cases you may need several renderers, for example some particles on background layer, than player sprite, than some particles over player sprite. It is safe to use several renderers, but there is one important note about GL renderer for html5 with `-Ddom`. Browser give you limited number of WebGL contexts, so don't use too much renderers and test you game in various browsers.

## Export notes

Embedded textures is **supported**, hovewer it is not recommended to use them for large images. For large texture images it is recommended to **uncheck** "embed" before export.

![](http://blog.zame-dev.org/wp-content/uploads/2015/02/particledesigner.png)

## Renderer notes

  - html5 with `-Ddom` (GL renderer) - [link](http://blog.zame-dev.org/pub/particles/html5-dom-v3/)
  - html5 in canvas mode (drawTiles renderer) - [link](http://blog.zame-dev.org/pub/particles/html5-canvas-v3/)
  - flash (sprites renderer) - [link](http://blog.zame-dev.org/pub/particles/flash-v3.swf)
  - flash (stage3d renderer) - [link](http://blog.zame-dev.org/pub/particles/flash-stage3d-v3/)

GL renderer is the best choise for html5 (with `-Ddom`) - it support many features and super fast. It use "hacked" version of OpenGLView to be able to add canvas with proper z-index. However GL renderer is available **only** for html with `-Ddom`.

Sprites renderer is best for flash, because it support color effects via ColorTransform. But this renderer is slow.
If you use [TilesheetStage3D](https://github.com/as3boyan/TilesheetStage3D) library you may consider of using stage3d renderer, because it has much better performance.

All other targets should use drawTiles renderer:

  - html5 in canvas mode - still pretty fast, doesn't support color effects. Can render incorrectly due to bug in openfl, please apply [this patch](https://github.com/openfl/openfl/pull/1113) ([or this for earlier versions of openfl](https://github.com/openfl/openfl/pull/434)) if you encounter it.
  - native - fast, support color effects, hovewer in some cases GL renderer looks better.

## Roadmap for future

- [x] Support for .json output format
- [x] Support for .lap and .pex output formats
- [x] Support for embedded textures
- [x] Create importer for particles in luxeengine
- [x] Implement SpritesRenderer
- [x] Implement Stage3DRenderer
- [x] Implement TilemapRenderer
- [ ] Support for lime / snow directly without openfl / luxeengine
- [ ] Support for HaxeFlixel and / or HaxePunk?
- [x] Partial support for pixi particles
- [ ] Full support for pixi particles
- [ ] Fix rotation calculations (to be the same for all renderers)
- [ ] Support KHA directly in this library

## KHA port by RafaelOliveira

https://github.com/RafaelOliveira/z-particles
