package org.zamedev.particles;

import openfl.display.Sprite;
import openfl.display.Tilesheet;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.gl.GL;

class DrawTilesParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private static inline var TILE_DATA_FIELDS = 9; // x, y, tileId, scale, rotation, red, green, blue, alpha

    private var ps:ParticleSystem;
    private var tilesheet:Tilesheet;
    private var tileData:Array<Float>;

    public function init(ps:ParticleSystem):Void {
        this.ps = ps;
        tilesheet = new Tilesheet(ps.textureBitmapData);

        tilesheet.addTileRect(
            ps.textureBitmapData.rect.clone(),
            new Point(ps.textureBitmapData.rect.width / 2, ps.textureBitmapData.rect.height / 2)
        );

        tileData = new Array<Float>();
        tileData[Std.int(ps.maxParticles * TILE_DATA_FIELDS - 1)] = 0.0; // Std.int(...) required for neko

        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    public function destroy():Void {
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function onEnterFrame(_):Void {
        if (!ps.__update()) {
            return;
        }

        graphics.clear();

        var index:Int = 0;
        var ethalonSize:Float = ps.textureBitmapData.width;

        var flags = (ps.blendFuncSource == GL.SRC_ALPHA && ps.blendFuncDestination == GL.ONE
            ? Tilesheet.TILE_BLEND_ADD
            : Tilesheet.TILE_BLEND_NORMAL
        );

        for (i in 0 ... ps.__particleCount) {
            var particle = ps.__particleList[i];

            tileData[index] = particle.position.x * ps.particleScaleX; // x
            tileData[index + 1] = particle.position.y * ps.particleScaleY; // y
            tileData[index + 2] = 0.0; // tileId
            tileData[index + 3] = particle.particleSize / ethalonSize * ps.particleScaleSize; // scale
            tileData[index + 4] = particle.rotation; // rotation
            tileData[index + 5] = particle.color.r;
            tileData[index + 6] = particle.color.g;
            tileData[index + 7] = particle.color.b;
            tileData[index + 8] = particle.color.a;

            index += TILE_DATA_FIELDS;
        }

        tilesheet.drawTiles(
            graphics,
            tileData,
            true,
            Tilesheet.TILE_SCALE | Tilesheet.TILE_ROTATION | Tilesheet.TILE_RGB | Tilesheet.TILE_ALPHA | flags,
            index
        );

        // removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
}
