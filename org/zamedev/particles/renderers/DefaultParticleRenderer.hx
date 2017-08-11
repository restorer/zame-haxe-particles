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
                    #if (openfl < "6.0.0")
                        return new TilemapParticleRenderer();
                    #else
                        // Tilemap is broken in OpenFL 6.0.1
                        return new SpritesParticleRenderer();
                    #end
                }
            #elseif webgl
                return new SpritesParticleRenderer();
            #else
                #if (openfl < "6.0.0")
                    return new TilemapParticleRenderer();
                #else
                    // Tilemap is broken in OpenFL 6.0.1
                    return new SpritesParticleRenderer();
                #end
            #end
        #elseif flash
            return new SpritesParticleRenderer();
        #else // native
            #if cpp
                return new SpritesParticleRenderer();
            #else
                #if (openfl < "6.0.0")
                    return new TilemapParticleRenderer();
                #else
                    // Tilemap is broken in OpenFL 6.0.1
                    return new SpritesParticleRenderer();
                #end
            #end
        #end
    }
}
