# Particle system for OpenFl

*(and for KHA, see below)*

![](http://blog.zame-dev.org/wp-content/uploads/2015/03/Screen-Shot-2015-03-18-at-12.53.43.png)

[Demo](http://blog.zame-dev.org/pub/particles/html5-dom-v3/)

Features:

 - Can load files from Particle Designer or [Particle Designer 2](https://71squared.com/en/particledesigner).
 - Support for embedded textures, both zipped or not.
 - Can load files from [Starling Particle Editor](http://onebyonedesign.com/flash/particleeditor/).
 - Has 5 renderers - Sprites, DrawTiles (OpenFL 3) / Tilemap (OpenFL 4), Stage3d (OpenFL 4), and GL renderer.

**Work in progress, more features coming.**

## OpenFL 3 note

This is last version that support OpenFL 3. It will be under branch `openfl3`.

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
  - flash (stage3d renderer) - [link](http://blog.zame-dev.org/pub/particles/flash-stage3d-v3/)

GL renderer is the best choise for html5 (with `-Ddom`) - it support many features and super fast. It use "hacked" version of OpenGLView to be able to add canvas with proper z-index. However GL renderer is available **only** for html with `-Ddom`.

Sprites renderer is best for flash, because it support color effects. If you use [TilesheetStage3D](https://github.com/as3boyan/TilesheetStage3D) library you may consider of using stage3d renderer, because it has much better performance.

Also use sprites renderer for cpp target (mac, linux, windows, android, ios) with OpenFL 4.

All other targets should use DrawTiles renderer for OpenFL 3 and Tilemap renderer for OpenFL 4:

  - html5 in canvas mode - still pretty fast, doesn't support color effects. **OpenFL 3:** Can render incorrectly due to bug in openfl, please apply [this patch](https://github.com/openfl/openfl/pull/1113) ([or this for earlier versions of openfl](https://github.com/openfl/openfl/pull/434)) if you encounter it.
  - native - fast, on OpenFL 3 support color effects.

**DefaultParticleRenderer**

Usually you don't need to choose renderer manually, just use `DefaultParticleRenderer.createInstance()` to create best renderer.

**OpenFL 4**

| Target / Renderer | DrawTiles | GLView | Sprites | Stage3D | Tilemap |
|---|---|---|---|---|---|
| html5<br />`-Ddom` | n/a | **effects:** full,<br />**speed:** fast,<br /><br />**best choise** | **effects:** no,<br />**speed:** very slow | n/a | **effects:** no,<br />**speed:** slow |
| html5<br />`-Dcanvas` | n/a | n/a | **effects:** no,<br />**speed:** almost fast | n/a | **effects:** no,<br />**speed:** fast,<br /><br />**best choise** |
| html5<br />`-Dwebgl` | n/a | n/a | **effects:** almost full,<br />**speed:** almost fast,<br /><br />**best choise** | n/a | **effects:** no,<br />**speed:** fast |
| cpp | n/a | n/a | **effects:** almost full,<br />**speed:** almost fast,<br /><br />**best choise** | n/a | **effects:** no,<br />**speed:** fast |
| neko | n/a | n/a | **effects:** almost full,<br />**speed:** very slow | n/a | **effects:** no,<br />**speed:** almost fast,<br /><br />**best choise** |
| flash | n/a | n/a | **effects:** partial,<br />**speed:** not so slow,<br /><br />**best choise** | n/a | **effects:** no,<br />**speed:** not so slow |

**OpenFL 3**

| Target / Renderer | DrawTiles | GLView | Sprites | Stage3D | Tilemap |
|---|---|---|---|---|---|
| html5<br />`-Ddom` | **effects:** no,<br />**speed:** slow | **effects:** full,<br />**speed:** fast,<br /><br />**best choise** | **effects:** no,<br />**speed:** very slow | n/a | n/a |
| html5<br />`-Dcanvas` | **effects:** no,<br />**speed:** fast,<br /><br />**best choise** | n/a | **effects:** no,<br />**speed:** slow | n/a | n/a |
| cpp<br />`-Dlegacy` | **effects:** partial,<br />**speed:** fast,<br /><br />**best choise** | n/a | **effects:** no,<br />**speed:** almost fast | n/a | n/a |
| neko<br />`-Dlegacy` | **effects:** partial,<br />**speed:** fast,<br /><br />**best choise** | n/a | **effects:** no,<br />**speed:** almost fast | n/a | n/a |
| flash | **effects:** no,<br />**speed:** slow | n/a | **effects:** partial,<br />**speed:** not so slow,<br /><br />**best choise** | n/a | n/a |
| flash with<br />`TilesheetStage3D` | **effects:** no,<br />**speed:** slow | n/a | **effects:** partial,<br />**speed:** not so slow | **effects:** full,<br />**speed:** fast,<br /><br />**best choise** | n/a |

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
- [ ] Support for lime / snow directly without openfl / luxeengine
- [ ] Support for HaxeFlixel and / or HaxePunk?
- [ ] Support KHA directly in this library

## KHA port by RafaelOliveira

https://github.com/RafaelOliveira/z-particles
