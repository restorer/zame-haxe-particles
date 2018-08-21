package org.zamedev.particles.renderers;

class DefaultParticleRenderer {
    public static function createInstance(manualUpdate : Bool = false) : ParticleSystemRenderer {
        #if flash
            return new SpritesParticleRenderer(manualUpdate);
        // #elseif webgl
            // return new OpenGlParticleRenderer(manualUpdate);
        #else
            return new TilemapParticleRenderer(manualUpdate);
        #end
    }
}
