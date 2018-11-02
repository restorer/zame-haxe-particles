package org.zamedev.particles.renderers;

class DefaultParticleRenderer {
    public static function createInstance(manualUpdate : Bool = false) : ParticleSystemRenderer {
        #if flash
            return new SpritesParticleRenderer(manualUpdate);
        #elseif (js && html5 && webgl)
            return new WebGlParticleRenderer(manualUpdate);
        #elseif (js && html5 && dom)
            if (DomGlParticleRenderer.isSupported()) {
                return new DomGlParticleRenderer(manualUpdate);
            } else {
                return new TilemapParticleRenderer(manualUpdate);
            }
        #else
            return new TilemapParticleRenderer(manualUpdate);
        #end
    }
}
