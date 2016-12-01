# Particle system for OpenFl

*(and for KHA, see below)*

![](http://blog.zame-dev.org/wp-content/uploads/2015/03/Screen-Shot-2015-03-18-at-12.53.43.png)

[Demo (old version)](http://blog.zame-dev.org/pub/particles/html5-dom-v3/)

Features:

 - Can load files from Particle Designer or [Particle Designer 2](https://71squared.com/en/particledesigner).
 - Support for embedded textures, both zipped or not.
 - Can load files from [Starling Particle Editor](http://onebyonedesign.com/flash/particleeditor/).
 - Has 3 renderers - Sprites, Tilemap (OpenFL 4), and GL renderer.

**Work in progress, more features coming.**

## OpenFL 3 note

This version supports OpenFL 4 only. If you still use OpenFL 3, find older version under branch `openfl3`.

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
  - flash (old version of sprites renderer) - [link](http://blog.zame-dev.org/pub/particles/flash-v3.swf)

GL renderer is the best choise for html5 (with `-Ddom`) - it support many features and super fast. It use "hacked" version of OpenGLView to be able to add canvas with proper z-index. However GL renderer is available **only** for html with `-Ddom`.

Sprites renderer is best for flash, because it support color effects. Also use sprites renderer for cpp target (mac, linux, windows, android, ios) with OpenFL 4.

All other targets should use Tilemap renderer.

  - html5 in canvas mode - fast, but doesn't support color effects.
  - native - fast and doesn't support color effects too (but this can be changed in future).

**DefaultParticleRenderer**

Usually you don't need to choose renderer manually, just use `DefaultParticleRenderer.createInstance()` to create best renderer.

**Renderers comparison**

| Target / Renderer | GLView | Sprites | Tilemap |
|---|---|---|---|---|---|
| html5<br />`-Ddom` | **effects:** full,<br />**speed:** fast,<br /><br />**best choise** | **effects:** no,<br />**speed:** very slow | **effects:** no,<br />**speed:** slow |
| html5<br />`-Dcanvas` | n/a | **effects:** no,<br />**speed:** almost fast | **effects:** no,<br />**speed:** fast,<br /><br />**best choise** |
| html5<br />`-Dwebgl` | n/a | **effects:** almost full,<br />**speed:** almost fast,<br /><br />**best choise** | **effects:** no,<br />**speed:** fast |
| cpp | n/a | **effects:** almost full,<br />**speed:** almost fast,<br /><br />**best choise** | **effects:** no,<br />**speed:** fast |
| neko | n/a | **effects:** almost full,<br />**speed:** very slow | **effects:** no,<br />**speed:** almost fast,<br /><br />**best choise** |
| flash | n/a | **effects:** partial,<br />**speed:** not so slow,<br /><br />**best choise** | **effects:** no,<br />**speed:** not so slow |

## Product support

Product still is in development (but not active).

| Feature | Support status |
|---|---|
| New features | Yes |
| Non-critical bugfixes | Yes |
| Critical bugfixes | Yes |
| Pull requests | Accepted (after review) |
| Issues | Monitored |
| OpenFL version planned to support | Up to 4.x, and probably later, if Tilemap wouldn't be deprecated like Tilesheet |
| Estimated end-of-life | Up to 2019 |

## Roadmap for future

- [x] Support for .json output format
- [x] Support for .lap and .pex output formats
- [x] Support for embedded textures
- [x] Create importer for particles in luxeengine
- [x] Implement SpritesRenderer
- [x] Implement Stage3DRenderer
- [x] Implement TilemapRenderer
- [x] Fix rotation calculations (to be the same for all renderers)
- [x] Partial support for pixi particles
- [ ] Full support for pixi particles
- [ ] Allow to pass BitmapData to loader
- [ ] Allow to change particle system parameters dynamically
- [ ] Move non openfl-related stuff to core (particle, particle system, utils, base loaders)
- [ ] Support for lime / snow directly without openfl / luxeengine
- [ ] Support for HaxeFlixel and / or HaxePunk?
- [ ] Support KHA directly in this library

## KHA port by RafaelOliveira

https://github.com/RafaelOliveira/z-particles
