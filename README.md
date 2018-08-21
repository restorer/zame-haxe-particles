# Particle system for OpenFl

*(and for KHA, see below)*

![](https://eightsines.com/pub/particles/illustration-v4.png)

[Demo (webgl)](https://eightsines.com/pub/particles/html5-webgl-v4/) (see other demos below in "Renderer notes" section)

Features:

 - Can load files from Particle Designer or [Particle Designer 2](https://www.71squared.com/en/particledesigner).
 - Support for embedded textures, both zipped or not.
 - Can load files from [Starling Particle Editor](http://onebyonedesign.com/flash/particleeditor/).
 - Has 2 renderers - Sprites and Tilemap.

**Work in progress, more features coming.**

## Notes about earlier OpenFl versions

This version supports OpenFl 8 and later.
If you use OpenFl from 4.x or 5.x, find you version under branch `openfl4` (probably will work for 6.x and 7.x, but not tested).
If you still use OpenFl 3.x, find older version under branch `openfl3`.

## Installation

Stable version from haxelib:

```bash
haxelib install zame-particles
```

Latest development version:

```bash
haxelib git zame-particles https://github.com/restorer/zame-haxe-particles.git
```

## Usage

First of all, append following to your project.xml:

```xml
<haxelib name="zame-particles" />
```

Next, in code, create particle renderer and add it as child to container:

```haxe
var renderer = DefaultParticleRenderer.createInstance();
addChild(cast renderer);
```

Than load particle emitter config from file, and add loaded particle system to the renderer:

```haxe
var ps = ParticleLoader.load("particle/fire.plist");
renderer.addParticleSystem(ps);
```

Finally, call `emit()` where you need:

```haxe
ps.emit(stage.stageWidth / 2, stage.stageHeight / 2);
```

**See minimal example under samples/minimal for more info.**

If you have multiple particle systems (particle emitters), you should use only one renderer for them:

```haxe
var renderer = DefaultParticleRenderer.createInstance();
addChild(cast renderer);

var ps1 = ParticleLoader.load("particle/ps1.plist");
renderer.addParticleSystem(ps1);

var ps2 = ParticleLoader.load("particle/ps2.plist");
renderer.addParticleSystem(ps2);

var ps3 = ParticleLoader.load("particle/ps3.plist");
renderer.addParticleSystem(ps3);
```

In some cases you may need several renderers, for example some particles on background layer, than player sprite, than some particles over player sprite. It is safe to use many renderers, but it will be better to reduce renderers count.

## Export notes

Embedded textures is **supported**, hovewer it is not recommended to use them for large images. For large texture images it is recommended to **uncheck** "embed" before export.

![](https://eightsines.com/pub/particles/particle-designer.png)

## Renderer notes

  - html5 with `-Dwebgl` (tilemap renderer) - [link](https://eightsines.com/pub/particles/html5-webgl-v4/)
  - html5 with `-Dcanvas` (tilemap renderer) - [link](https://eightsines.com/pub/particles/html5-canvas-v4/)
  - html5 with `-Ddom` (tilemap renderer) - [link](https://eightsines.com/pub/particles/html5-dom-v4/) (loader bar is not disappeared after loading - it's OpenFl, not me :smiley:)
  - flash (sprites renderer) - [link](https://eightsines.com/pub/particles/flash-v4.swf)

Sprites renderer is used for flash, because it has some kind of support for blend modes, also tilemap renderer doesn't work well on flash (however sprites renderer can display various artifacts if particle count is big).

**DefaultParticleRenderer**

Usually you don't need to choose renderer manually, just use `DefaultParticleRenderer.createInstance()` to create best renderer.

## Dropped things

GL renderer was dropped in this version, because OpenFl 8.x doesn't support `OpenGLView` anymore. There is `OpenGLRenderer`, but it is a special thing, not related to standard display list. Currently I'm trying to recreate this functionality.

Importer for luxeengine is dropped also, because Haxe version of luxeengine is not supported anymore.

Stage3DRenderer was dropped several versions ago, because it depends on various outdated libs, which doesn't work well anymore.

## Product support

Product still is in development (but not active).

| Feature | Support status |
|---|---|
| New features | Yes |
| Non-critical bugfixes | Yes |
| Critical bugfixes | Yes |
| Pull requests | Accepted (after review) |
| Issues | Monitored |
| OpenFl version planned to support | Up to 8.x, and probably later |
| Estimated end-of-life | Up to 2019 |

## Roadmap for future

- [x] Support for .json output format
- [x] Support for .lap and .pex output formats
- [x] Support for embedded textures
- [x] Implement SpritesRenderer
- [x] Implement TilemapRenderer
- [x] Fix rotation calculations (to be the same for all renderers)
- [x] Partial support for pixi particles
- [x] Add support for native GL rendering (via `OpenGLRenderer`)
- [ ] Ability to use GL rendering in `-Ddom` mode
- [ ] Move non openfl-related stuff to core (particle, particle system, utils, base loaders)
- [ ] Allow to pass BitmapData to loader
- [ ] Allow to change particle system parameters dynamically
- [ ] Full support for pixi particles
- [ ] Add support for Stage3D
- [ ] Support for HaxeFlixel and / or HaxePunk?
- [ ] Support KHA directly in this library
- [ ] Support for Stencyl?

## KHA port by RafaelOliveira

https://github.com/RafaelOliveira/z-particles
