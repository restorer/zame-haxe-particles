package org.zamedev.particles.renderers;

#if (html5 && dom)
    import openfl.display.OpenGLView;
#end

class DefaultParticleRenderer {
    public static function createInstance(manualUpdate : Bool = false) : ParticleSystemRenderer {
        #if html5
            #if dom
                if (!manualUpdate && OpenGLView.isSupported) {
                    return new GLViewParticleRenderer();
                } else {
                    return new TilemapParticleRenderer();
                }
            #elseif webgl
                return new SpritesParticleRenderer();
            #else
                return new TilemapParticleRenderer();
            #end
        #elseif flash
            return new SpritesParticleRenderer();
        #else // native
            #if cpp
                return new SpritesParticleRenderer();
            #else
                return new TilemapParticleRenderer();
            #end
        #end
    }
}
