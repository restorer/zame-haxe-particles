package org.zamedev.particles.renderers;

import openfl.display.Sprite;
import openfl.display.Tile;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.gl.GL;

typedef TilemapParticleRendererData = {
    ps : ParticleSystem,
    tilemap : Tilemap,
    tileList : Array<Tile>,
    updated : Bool,
};

class TilemapParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private var dataList : Array<TilemapParticleRendererData> = [];

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        if (dataList.length == 0) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        ps.__initialize();
        var tileList = new Array<Tile>();

        var tileset = new Tileset(ps.textureBitmapData);
        tileset.addRect(ps.textureBitmapData.rect);

        var tilemap = new Tilemap(stage.stageWidth, stage.stageHeight, tileset);
        addChild(tilemap);

        /*
        for (i in 0 ... ps.maxParticles) {
            var tile = new Tile(0);
            tile.visible = false;

            tileList.push(tile);
            tilemap.addTile(tile);
        }
        */

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

        if (dataList.length == 0) {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        return this;
    }

    private function onEnterFrame(_) : Void {
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
            var tileList = data.tileList;
            var ethalonSize : Float = ps.textureBitmapData.width;
            var halfWidth : Float = ethalonSize * 0.5;
            var halfHeight : Float = ps.textureBitmapData.height * 0.5;

            for (i in 0 ... ps.__particleCount) {
                var particle = ps.__particleList[i];
                var tile : Tile;

                if (i < tileList.length) {
                    tile = tileList[i];
                } else {
                    tile = new Tile(0);
                    tileList.push(tile);
                    data.tilemap.addTile(tile);
                }

                var scale : Float = particle.particleSize / ethalonSize * ps.particleScaleSize;
                var mat = tile.matrix;

                mat.a = Math.cos(particle.rotation) * scale;
                mat.c = Math.sin(particle.rotation) * scale;
                mat.b = - mat.c;
                mat.d = mat.a;

                // set matrix **before** setting x and y, because they are setters, and they set
                // internal flag __transformDirty
                tile.x = particle.position.x * ps.particleScaleX - halfWidth * mat.a - halfHeight * mat.c;
                tile.y = particle.position.y * ps.particleScaleY - halfWidth * mat.b - halfHeight * mat.d;

                tile.alpha = particle.color.a;

                /*
                if (!tile.visible) {
                    tile.visible = true;
                }
                */
            }

            /*
             * tile.visible currently not working for neko (at least)
             *
            for (i in ps.__particleCount ... tileList.length) {
                var tile = tileList[i];

                if (tile.visible) {
                    tile.visible = false;
                }
            }
            */

            if (tileList.length > ps.__particleCount) {
                data.tilemap.removeTiles(ps.__particleCount, tileList.length);
                tileList.splice(ps.__particleCount, tileList.length - ps.__particleCount + 1);
            }
        }
    }
}
