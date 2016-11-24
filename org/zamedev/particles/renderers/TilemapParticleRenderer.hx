package org.zamedev.particles.renderers;

import openfl.display.BlendMode;
import openfl.display.Sprite;
import openfl.display.Tile;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.events.Event;
import openfl.gl.GL;

typedef TilemapParticleRendererData = {
    ps : ParticleSystem,
    tilemap : Tilemap,
    tileList : Array<Tile>,
    updated : Bool,
};

// Use -Dzameparticles_use_tile_visibility to enable tile pool
// But actually this is slower than array manipulations (significantly on neko)

class TilemapParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private var manualUpdate : Bool;
    private var dataList : Array<TilemapParticleRendererData> = [];

    public function new(manualUpdate : Bool = false) {
        super();
        this.manualUpdate = manualUpdate;
    }

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        if (dataList.length == 0 && !manualUpdate) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        ps.__initialize();
        var tileList = new Array<Tile>();

        var tileset = new Tileset(ps.textureBitmapData);
        tileset.addRect(ps.textureBitmapData.rect);

        var currentStage = (stage != null ? stage : openfl.Lib.current.stage);

        var tilemap = new Tilemap(currentStage.stageWidth, currentStage.stageHeight, tileset);
        addChild(tilemap);

        #if zameparticles_use_tile_visibility
            for (i in 0 ... ps.maxParticles) {
                var tile = new Tile(0);
                tile.visible = false;

                tileList.push(tile);
                tilemap.addTile(tile);
            }
        #end

        dataList.push({
            ps: ps,
            tilemap: tilemap,
            tileList: tileList,
            updated: false,
        });

        return this;
    }

    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        var index = 0;

        while (index < dataList.length) {
            if (dataList[index].ps == ps) {
                removeChild(dataList[index].tilemap);
                dataList.splice(index, 1);
            } else {
                index++;
            }
        }

        if (dataList.length == 0 && !manualUpdate) {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        return this;
    }

    public function update() : Void {
        var updated = false;

        for (data in dataList) {
            if (data.updated = data.ps.__update()) {
                updated = true;
            }
        }

        if (!updated) {
            return;
        }

        for (data in dataList) {
            if (!data.updated) {
                continue;
            }

            var ps = data.ps;

            if (ps.blendFuncSource == GL.DST_COLOR) {
                data.tilemap.blendMode = BlendMode.MULTIPLY;
            } else if (ps.blendFuncDestination == GL.ONE) {
                data.tilemap.blendMode = BlendMode.ADD;
            } else {
                data.tilemap.blendMode = BlendMode.NORMAL;
            }

            var widthMult : Float;
            var heightMult : Float;
            var ethalonSize : Float;

            if (!ps.forceSquareTexture
                || ps.textureBitmapData.width == ps.textureBitmapData.height
                || ps.textureBitmapData.width == 0
                || ps.textureBitmapData.height == 0
            ) {
                widthMult = 1.0;
                heightMult = 1.0;
                ethalonSize = ps.textureBitmapData.width;
            } else if (ps.textureBitmapData.width > ps.textureBitmapData.height) {
                widthMult = ps.textureBitmapData.height / ps.textureBitmapData.width;
                heightMult = 1.0;
                ethalonSize = ps.textureBitmapData.height;
            } else {
                widthMult = 1.0;
                heightMult = ps.textureBitmapData.width / ps.textureBitmapData.height;
                ethalonSize = ps.textureBitmapData.width;
            }

            var halfWidth : Float = ps.textureBitmapData.width * 0.5;
            var halfHeight : Float = ps.textureBitmapData.height * 0.5;
            var tileList = data.tileList;

            for (i in 0 ... ps.__particleCount) {
                var particle = ps.__particleList[i];

                #if zameparticles_use_tile_visibility
                    var tile : Tile = tileList[i];
                #else
                    var tile : Tile;

                    if (i < tileList.length) {
                        tile = tileList[i];
                    } else {
                        tile = new Tile(0);
                        tileList.push(tile);
                        data.tilemap.addTile(tile);
                    }
                #end

                var scale : Float = particle.particleSize / ethalonSize * ps.particleScaleSize;
                var scaleX : Float = scale * widthMult;
                var scaleY : Float = scale * heightMult;

                var rotationSine : Float = Math.sin(particle.rotation);
                var rotationCosine : Float = Math.cos(particle.rotation);

                var mat = tile.matrix;
                mat.a = rotationCosine * scaleX;
                mat.b = rotationSine * scaleX;
                mat.c = - rotationSine * scaleY;
                mat.d = rotationCosine * scaleY;
                mat.tx = particle.position.x * ps.particleScaleX - halfWidth * mat.a - halfHeight * mat.c;
                mat.ty = particle.position.y * ps.particleScaleY - halfWidth * mat.b - halfHeight * mat.d;

                tile.matrix = mat;
                tile.alpha = particle.color.a;

                #if zameparticles_use_tile_visibility
                    tile.visible = true;
                #end
            }

            #if zameparticles_use_tile_visibility
                for (i in ps.__particleCount ... tileList.length) {
                    tileList[i].visible = false;
                }
            #else
                if (tileList.length > ps.__particleCount) {
                    data.tilemap.removeTiles(ps.__particleCount, tileList.length);
                    tileList.splice(ps.__particleCount, tileList.length - ps.__particleCount + 1);
                }
            #end
        }
    }

    private function onEnterFrame(_) : Void {
        update();
    }
}
