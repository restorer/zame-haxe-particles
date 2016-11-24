package org.zamedev.particles.renderers;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.gl.GL;

#if (native || webgl || flash)
    import openfl.display.BlendMode;
    import openfl.filters.ColorMatrixFilter;
#end

typedef SpriteInfo = {
    bitmap : Bitmap,
    #if (native || webgl || flash)
        colorMatrixFilter : ColorMatrixFilter,
    #end
    #if zameparticles_use_sprite_visibility
        visible : Bool,
    #end
};

typedef SpritesParticleRendererData = {
    ps : ParticleSystem,
    spriteList : Array<SpriteInfo>,
    updated : Bool,
};

// Use -Dzameparticles_use_sprite_visibility to enable sprite pool
// But actually this is slower than array manipulations

class SpritesParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private var manualUpdate : Bool;
    private var dataList : Array<SpritesParticleRendererData> = [];

    public function new(manualUpdate : Bool = false) {
        super();
        this.manualUpdate = manualUpdate;
    }

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        if (dataList.length == 0 && !manualUpdate) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        ps.__initialize();
        var spriteList = new Array<SpriteInfo>();

        #if zameparticles_use_sprite_visibility
            for (i in 0 ... ps.maxParticles) {
                var bitmap = new Bitmap(ps.textureBitmapData);
                bitmap.visible = false;

                spriteList.push({
                    bitmap: bitmap,
                    visible: false,
                    #if (native || webgl || flash)
                        colorMatrixFilter: new ColorMatrixFilter(),
                    #end
                });

                addChild(bitmap);
            }
        #end

        dataList.push({
            ps: ps,
            spriteList: spriteList,
            updated: false,
        });

        return this;
    }

    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        var index = 0;

        while (index < dataList.length) {
            if (dataList[index].ps == ps) {
                for (info in dataList[index].spriteList) {
                    removeChild(info.bitmap);
                }

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

            #if (native || webgl || flash)
                var blendMode = if (ps.blendFuncSource == GL.DST_COLOR) {
                    BlendMode.MULTIPLY;
                } else if (
                    (ps.blendFuncSource == GL.ZERO || ps.blendFuncSource == GL.SRC_ALPHA_SATURATE)
                    && ps.blendFuncDestination == GL.ONE_MINUS_SRC_ALPHA
                ) {
                    BlendMode.SUBTRACT;
                } else if (ps.blendFuncDestination == GL.ONE) {
                    BlendMode.ADD;
                } else {
                    BlendMode.NORMAL;
                }
            #end

            var widthMult : Float;
            var heightMult : Float;

            if (!ps.forceSquareTexture
                || ps.textureBitmapData.width == ps.textureBitmapData.height
                || ps.textureBitmapData.width == 0
                || ps.textureBitmapData.height == 0
            ) {
                widthMult = 1.0;
                heightMult = 1.0;
            } else if (ps.textureBitmapData.width > ps.textureBitmapData.height) {
                widthMult = ps.textureBitmapData.height / ps.textureBitmapData.width;
                heightMult = 1.0;
            } else {
                widthMult = 1.0;
                heightMult = ps.textureBitmapData.width / ps.textureBitmapData.height;
            }

            var ethalonSize : Float = ps.textureBitmapData.width * widthMult;
            var halfWidth : Float = ps.textureBitmapData.width * 0.5;
            var halfHeight : Float = ps.textureBitmapData.height * 0.5;
            var spriteList = data.spriteList;

            for (i in 0 ... ps.__particleCount) {
                var particle = ps.__particleList[i];

                #if zameparticles_use_sprite_visibility
                    var info = spriteList[i];
                #else
                    var info : SpriteInfo;

                    if (i < spriteList.length) {
                        info = spriteList[i];
                    } else {
                        var bitmap = new Bitmap(ps.textureBitmapData);

                        info = {
                            bitmap: bitmap,
                            #if (native || webgl || flash)
                                colorMatrixFilter: new ColorMatrixFilter(),
                            #end
                        };

                        spriteList.push(info);
                        addChild(bitmap);
                    }
                #end

                var scale : Float = particle.particleSize / ethalonSize * ps.particleScaleSize;
                var scaleX : Float = scale * widthMult;
                var scaleY : Float = scale * heightMult;

                var rotationSine : Float = Math.sin(- particle.rotation);
                var rotationCosine : Float = Math.cos(- particle.rotation);

                var matA : Float = rotationCosine * scaleX;
                var matB : Float = rotationSine * scaleY;
                var matC : Float = - rotationSine * scaleX;
                var matD : Float = rotationCosine * scaleY;

                var bitmap = info.bitmap;
                bitmap.scaleX = scaleX;
                bitmap.scaleY = scaleY;
                bitmap.rotation = particle.rotation * 180.0 / Math.PI;
                bitmap.x = particle.position.x * ps.particleScaleX - halfWidth * matA - halfHeight * matB;
                bitmap.y = particle.position.y * ps.particleScaleY - halfWidth * matC - halfHeight * matD;

                #if (native || webgl || flash)
                    var colorMatrix = info.colorMatrixFilter.matrix;
                    colorMatrix[0] = particle.color.r;
                    colorMatrix[5 + 1] = particle.color.g;
                    colorMatrix[10 + 2] = particle.color.b;
                    colorMatrix[15 + 3] = particle.color.a;

                    info.colorMatrixFilter.matrix = colorMatrix;
                    bitmap.filters = [ info.colorMatrixFilter ];
                    bitmap.blendMode = blendMode;
                #end

                #if (html5 && (canvas || dom))
                    bitmap.alpha = particle.color.a;
                #end

                #if zameparticles_use_sprite_visibility
                    if (!info.visible) {
                        info.visible = true;
                        bitmap.visible = true;
                    }
                #end
            }

            #if zameparticles_use_sprite_visibility
                for (i in ps.__particleCount ... spriteList.length) {
                    var info = spriteList[i];

                    if (info.visible) {
                        info.visible = false;
                        info.bitmap.visible = false;
                    }
                }
            #else
                if (spriteList.length > ps.__particleCount) {
                    for (i in ps.__particleCount ... spriteList.length) {
                        removeChild(spriteList[i].bitmap);
                    }

                    spriteList.splice(ps.__particleCount, spriteList.length - ps.__particleCount + 1);
                }
            #end
        }
    }

    private function onEnterFrame(_) : Void {
        update();
    }
}
