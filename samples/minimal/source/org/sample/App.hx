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
        var renderer = DefaultParticleRenderer.createInstance();
        addChild(cast renderer);

        var ps = ParticleLoader.load("particle/fire.plist");
        renderer.addParticleSystem(ps);

        ps.emit(stage.stageWidth / 2, stage.stageHeight / 2);
    }
}
