package org.sample;

import openfl.display.FPS;
import openfl.display.Sprite;
import org.zamedev.particles.ParticleSystem;
import org.zamedev.particles.loaders.ParticleLoader;
import org.zamedev.particles.renderers.DefaultParticleRenderer;

class App extends Sprite {
    private var particleSystemList:Array<ParticleSystem> = [];

    public function new() : Void {
        super();

        var particlesRenderer = DefaultParticleRenderer.createInstance();
        addChild(cast particlesRenderer);

        addChild(new FPS(10, 10, 0xff0000));

        particleSystemList.push(ParticleLoader.load("particle/heart.pex"));
        particleSystemList.push(ParticleLoader.load("particle/fountain.lap"));
        particleSystemList.push(ParticleLoader.load("particle/bubbles.json"));
        particleSystemList.push(ParticleLoader.load("particle/fire.plist"));
        particleSystemList.push(ParticleLoader.load("particle/frosty-blood.plist"));
        particleSystemList.push(ParticleLoader.load("particle/line-of-fire.plist"));
        particleSystemList.push(ParticleLoader.load("particle/trippy.plist"));
        particleSystemList.push(ParticleLoader.load("particle/sun.plist"));
        particleSystemList.push(ParticleLoader.load("particle/iris.plist"));
        particleSystemList.push(ParticleLoader.load("particle/hyperflash.plist"));
        particleSystemList.push(ParticleLoader.load("particle/dust.plist"));

        for (particleSystem in particleSystemList) {
            particlesRenderer.addParticleSystem(particleSystem);
            particleSystem.restart = true;
            particleSystem.emit(stage.stageWidth / 2, stage.stageHeight / 2);
        }
    }
}
