package org.sample;

import openfl.display.Sprite;
import openfl.events.Event;
import org.zamedev.particles.loaders.ParticleLoader;
import org.zamedev.particles.renderers.DefaultParticleRenderer;

class App extends Sprite {
    public function new() : Void {
        super();
        ready();
    }

    private function ready() : Void {
        /*
        var renderer = DefaultParticleRenderer.createInstance();
        addChild(cast renderer);

        var ps = ParticleLoader.load("particle/fire.plist");
        renderer.addParticleSystem(ps);

        ps.emit(stage.stageWidth / 2, stage.stageHeight / 2);
        */


        // var r1 = new org.zamedev.particles.renderers.SpritesParticleRenderer();
        var r2 = new org.zamedev.particles.renderers.TilemapParticleRenderer();
        // var r3 = new org.zamedev.particles.renderers.DomGlParticleRenderer();

        // addChild(r1);
        addChild(r2);
        // addChild(r3);

        // var ps1 = ParticleLoader.load("particle/arrow.json");
        var ps2 = ParticleLoader.load("particle/arrow.json");
        // var ps3 = ParticleLoader.load("particle/arrow.json");

        // r1.addParticleSystem(ps1);
        r2.addParticleSystem(ps2);
        // r3.addParticleSystem(ps3);

        // ps1.emit(stage.stageWidth / 2, stage.stageHeight / 2);
        ps2.emit(stage.stageWidth / 2, stage.stageHeight / 2);
        // ps3.emit(stage.stageWidth / 2, stage.stageHeight / 2);

        // r1.x = 200;
        // r1.scaleX = 0.5;

        // r2.x = 200;
        r2.scaleX = 0.5;

        // r3.x = 200;
        // r3.scaleX = 0.5;
    }
}
