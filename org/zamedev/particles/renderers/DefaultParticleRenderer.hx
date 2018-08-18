package org.zamedev.particles.renderers;

class DefaultParticleRenderer {
    public static function createInstance(manualUpdate : Bool = false) : ParticleSystemRenderer {
        #if flash
            return new SpritesParticleRenderer(manualUpdate);
        #else
            return new TilemapParticleRenderer(manualUpdate);
        #end
    }
}
