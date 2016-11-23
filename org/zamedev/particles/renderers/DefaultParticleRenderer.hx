package org.zamedev.particles.renderers;

#if (html5 && dom)
    import openfl.display.OpenGLView;
#end

class DefaultParticleRenderer {
    public static function createInstance() : ParticleSystemRenderer {
        #if html5
            #if dom
                if (OpenGLView.isSupported) {
                    return new GLViewParticleRenderer();
                } else {
                    #if (openfl >= "4.0")
                        return new TilemapParticleRenderer();
                    #else
                        return new DrawTilesParticleRenderer();
                    #end
                }
            #elseif webgl
                #if (openfl >= "4.0")
                    return new SpritesParticleRenderer();
                #else
                    return new DrawTilesParticleRenderer();
                #end
            #else
                return new TilemapParticleRenderer();
            #end
        #elseif flash
            #if (flash11 && zameparticles_stage3d && openfl < "4.0")
                return new Stage3DParticleRenderer();
            #else
                return new SpritesParticleRenderer();
            #end
        #else // native
            #if (openfl >= "4.0")
                #if cpp
                    return new SpritesParticleRenderer();
                #else
                    return new TilemapParticleRenderer();
                #end
            #else
                return new DrawTilesParticleRenderer();
            #end
        #end
    }
}
