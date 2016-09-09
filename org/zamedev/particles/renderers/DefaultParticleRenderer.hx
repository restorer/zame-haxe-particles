package org.zamedev.particles.renderers;

import openfl.display.OpenGLView;

class DefaultParticleRenderer {
    public static function createInstance() : ParticleSystemRenderer {
        #if (html5 && dom)
            if (OpenGLView.isSupported) {
                return new GLViewParticleRenderer();
            } else {
                #if (openfl < "4.0")
                    return new DrawTilesParticleRenderer();
                #else
                    return new TilemapParticleRenderer();
                #end
            }
        #elseif (flash11 && zameparticles_stage3d && openfl < "4.0")
            return new Stage3DParticleRenderer();
        #elseif flash
            return new SpritesParticleRenderer();
        #elseif (openfl < "4.0")
            return new DrawTilesParticleRenderer();
        #else
            return new TilemapParticleRenderer();
        #end
    }
}
