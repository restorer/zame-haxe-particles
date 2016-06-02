package org.zamedev.particles.renderers;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.gl.GL;

typedef SpriteInfo = {
    sprite : Sprite,
    colorTransform : ColorTransform,
    visible : Bool,
};

typedef SpritesParticleRendererData = {
    ps : ParticleSystem,
    spriteList : Array<SpriteInfo>,
    updated : Bool,
};

class SpritesParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private var dataList : Array<SpritesParticleRendererData> = [];

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        if (dataList.length == 0) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        ps.__initialize();
        var spriteList = new Array<SpriteInfo>();

        for (i in 0 ... ps.maxParticles) {
            var sprite = new Sprite();
            sprite.visible = false;

            var bitmap = new Bitmap(ps.textureBitmapData);
            bitmap.x = - ps.textureBitmapData.width * 0.5;
            bitmap.y = - ps.textureBitmapData.height * 0.5;
            sprite.addChild(bitmap);

            spriteList.push({
                sprite: sprite,
                colorTransform: new ColorTransform(),
                visible: false,
            });

            addChild(sprite);
        }

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
                    removeChild(info.sprite);
                }

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
            var spriteList = data.spriteList;
            var ethalonSize : Float = ps.textureBitmapData.width;

            for (i in 0 ... ps.__particleCount) {
                var particle = ps.__particleList[i];
                var info = spriteList[i];

                var sprite = info.sprite;
                sprite.x = particle.position.x * ps.particleScaleX;
                sprite.y = particle.position.y * ps.particleScaleY;

                var scale = particle.particleSize / ethalonSize * ps.particleScaleSize;
                sprite.scaleX = scale;
                sprite.scaleY = scale;

                sprite.rotation = particle.rotation * 180.0 / Math.PI + 90.0;

                var colorTransform = info.colorTransform;
                colorTransform.redMultiplier = particle.color.r;
                colorTransform.greenMultiplier = particle.color.g;
                colorTransform.blueMultiplier = particle.color.b;
                colorTransform.alphaMultiplier = particle.color.a;
                sprite.transform.colorTransform = colorTransform;

                #if html5
                    // TODO: it seems that alphaMultiplier in colorTransform
                    // should work well even in html5, but users reports that it isn't true
                    sprite.alpha = particle.color.a;
                #end

                if (!info.visible) {
                    info.visible = true;
                    sprite.visible = true;
                }
            }

            for (i in ps.__particleCount ... spriteList.length) {
                var info = spriteList[i];

                if (info.visible) {
                    info.visible = false;
                    info.sprite.visible = false;
                }
            }
        }
    }
}
