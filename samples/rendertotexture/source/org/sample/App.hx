package org.sample;

import lime.graphics.opengl.GL;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import org.zamedev.particles.loaders.ParticleLoader;
import org.zamedev.particles.renderers.DefaultParticleRenderer;
import org.zamedev.particles.renderers.ParticleSystemRenderer;

@:access(lime.graphics.opengl.GL)
class App extends Sprite {
    private var bitmap : Bitmap;
    private var bitmapData : BitmapData;
    private var renderer : ParticleSystemRenderer;

    public function new() : Void {
        super();
        ready();
    }

    private function ready() : Void {
        bitmap = new Bitmap();
        addChild(bitmap);

        // P.S. try to use POT texture
        // var texture = stage.stage3Ds[0].context3D.createTexture(stage.stageWidth, stage.stageHeight, BGRA, true);
        // bitmapData = BitmapData.fromTexture(texture);

        bitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, true, 0);

        if (GL.context != null) {
            bitmapData.disposeImage();
        }

        renderer = DefaultParticleRenderer.createInstance(true);

        var ps = ParticleLoader.load("particle/fire.plist");
        renderer.addParticleSystem(ps);
        ps.emit(stage.stageWidth / 2, stage.stageHeight / 2);

        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function onEnterFrame(_) : Void {
        renderer.update();

        bitmapData.fillRect(bitmapData.rect, 0);
        bitmapData.draw(cast renderer);

        bitmap.bitmapData = bitmapData;
        bitmap.smoothing = true;
    }
}
