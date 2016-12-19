package org.zamedev.particles.renderers;

import openfl.display.BlendMode;
import openfl.display.DisplayObject;
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
    private var offsetX : Float = 0.0;
    private var offsetY : Float = 0.0;
    private var parentScaleX : Float = 1.0;
    private var parentScaleY : Float = 1.0;

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

        fixPosition();

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

            widthMult *= parentScaleX;
            heightMult *= parentScaleY;

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

                var particleScale : Float = particle.particleSize / ethalonSize * ps.particleScaleSize;
                var particleScaleX : Float = particleScale * widthMult;
                var particleScaleY : Float = particleScale * heightMult;

                var rotationSine : Float = Math.sin(particle.rotation);
                var rotationCosine : Float = Math.cos(particle.rotation);

                var mat = tile.matrix;
                mat.a = rotationCosine * particleScaleX;
                mat.b = rotationSine * particleScaleX;
                mat.c = - rotationSine * particleScaleY;
                mat.d = rotationCosine * particleScaleY;
                mat.tx = (particle.position.x * ps.particleScaleX - offsetX) * parentScaleX - halfWidth * mat.a - halfHeight * mat.c;
                mat.ty = (particle.position.y * ps.particleScaleY - offsetY) * parentScaleY - halfWidth * mat.b - halfHeight * mat.d;

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

    // TODO: rework using inverse matrices, take rotation in account.
    private function fixPosition() : Void {
        var offsetX : Float = 0.0;
        var offsetY : Float = 0.0;
        var parentScaleX : Float = 1.0;
        var parentScaleY : Float = 1.0;

        var parentDisplayObject : DisplayObject = parent;
        var currentStage = (stage != null ? stage : openfl.Lib.current.stage);
        var parentList = new Array<DisplayObject>();

        while (parentDisplayObject != null && parentDisplayObject != currentStage) {
            parentList.unshift(parentDisplayObject);
            parentDisplayObject = parentDisplayObject.parent;
        }

        for (displayObject in parentList) {
            if (displayObject.scaleX == 0.0 || displayObject.scaleY == 0.0) {
                offsetX = 0.0;
                offsetY = 0.0;
                parentScaleX = 1.0;
                parentScaleY = 1.0;
                break;
            }

            offsetX = (offsetX - displayObject.x) / displayObject.scaleX;
            offsetY = (offsetY - displayObject.y) / displayObject.scaleY;
            parentScaleX *= displayObject.scaleX;
            parentScaleY *= displayObject.scaleY;
        }

        if (this.offsetX != offsetX || this.offsetY != offsetY || this.parentScaleX != parentScaleX || this.parentScaleY != parentScaleY) {
            x = offsetX;
            y = offsetY;
            scaleX = 1.0 / parentScaleX;
            scaleY = 1.0 / parentScaleY;

            this.offsetX = offsetX;
            this.offsetY = offsetY;
            this.parentScaleX = parentScaleX;
            this.parentScaleY = parentScaleY;
        }
    }
}
