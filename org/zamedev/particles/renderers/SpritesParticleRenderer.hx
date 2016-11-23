package org.zamedev.particles.renderers;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.gl.GL;

#if flash
    import flash.display.BlendMode;
    import flash.filters.ColorMatrixFilter;
#end

#if ((openfl >= "4.0") && (native || webgl))
    import openfl.display.BlendMode;
    import openfl.filters.ColorMatrixFilter;
#end

typedef SpriteInfo = {
    bitmap : Bitmap,
    #if (((openfl >= "4.0") && (native || webgl)) || flash)
        colorMatrixFilter : ColorMatrixFilter,
    #end
    #if zameparticles_use_sprite_visibility
        visible : Bool,
    #end
};

typedef SpritesParticleRendererData = {
    ps : ParticleSystem,
    #if (((openfl >= "4.0") && (native || webgl)) || flash)
        containerSprite : Sprite,
    #end
    spriteList : Array<SpriteInfo>,
    updated : Bool,
};

// Use -zameparticles_use_sprite_visibility to enable sprite pool
// But actually this is slower than array manipulations

class SpritesParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private var dataList : Array<SpritesParticleRendererData> = [];

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        if (dataList.length == 0) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        #if (((openfl >= "4.0") && (native || webgl)) || flash)
            var containerSprite = new Sprite();
            addChild(containerSprite);
        #end

        ps.__initialize();
        var spriteList = new Array<SpriteInfo>();

        #if zameparticles_use_sprite_visibility
            for (i in 0 ... ps.maxParticles) {
                var bitmap = new Bitmap(ps.textureBitmapData);
                bitmap.visible = false;

                spriteList.push({
                    bitmap: bitmap,
                    visible: false,
                    #if (((openfl >= "4.0") && (native || webgl)) || flash)
                        colorMatrixFilter: new ColorMatrixFilter(),
                    #end
                });

                #if (((openfl >= "4.0") && (native || webgl)) || flash)
                    containerSprite.addChild(bitmap);
                #else
                    addChild(bitmap);
                #end
            }
        #end

        dataList.push({
            ps: ps,
            #if (((openfl >= "4.0") && (native || webgl)) || flash)
                containerSprite: containerSprite,
            #end
            spriteList: spriteList,
            updated: false,
        });

        return this;
    }

    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        var index = 0;

        while (index < dataList.length) {
            if (dataList[index].ps == ps) {
                #if (((openfl >= "4.0") && (native || webgl)) || flash)
                    removeChild(dataList[index].containerSprite);
                #else
                    for (info in dataList[index].spriteList) {
                        removeChild(info.bitmap);
                    }
                #end

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

            #if (((openfl >= "4.0") && (native || webgl)) || flash)
                if (ps.blendFuncSource == GL.DST_COLOR) {
                    data.containerSprite.blendMode = BlendMode.MULTIPLY;
                } else if (ps.blendFuncDestination == GL.ONE) {
                    data.containerSprite.blendMode = BlendMode.ADD;
                } else {
                    data.containerSprite.blendMode = BlendMode.NORMAL;
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
                            #if (((openfl >= "4.0") && (native || webgl)) || flash)
                                colorMatrixFilter: new ColorMatrixFilter(),
                            #end
                        };

                        spriteList.push(info);

                        #if (((openfl >= "4.0") && (native || webgl)) || flash)
                            data.containerSprite.addChild(bitmap);
                        #else
                            addChild(bitmap);
                        #end
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

                #if (((openfl >= "4.0") && (native || webgl)) || flash)
                    var colorMatrix = info.colorMatrixFilter.matrix;
                    colorMatrix[0] = particle.color.r;
                    colorMatrix[5 + 1] = particle.color.g;
                    colorMatrix[10 + 2] = particle.color.b;
                    colorMatrix[15 + 3] = particle.color.a;

                    info.colorMatrixFilter.matrix = colorMatrix;
                    info.bitmap.filters = [ info.colorMatrixFilter ];
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
                        #if (((openfl >= "4.0") && (native || webgl)) || flash)
                            data.containerSprite.removeChild(spriteList[i].bitmap);
                        #else
                            removeChild(spriteList[i].bitmap);
                        #end
                    }

                    spriteList.splice(ps.__particleCount, spriteList.length - ps.__particleCount + 1);
                }
            #end
        }
    }
}
