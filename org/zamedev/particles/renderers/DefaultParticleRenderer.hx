package org.zamedev.particles.renderers;

#if (html5 && dom)
    typedef DefaultParticleRenderer = GLViewParticleRenderer;
#elseif flash
    typedef DefaultParticleRenderer = SpritesParticleRenderer;
#else
    typedef DefaultParticleRenderer = DrawTilesParticleRenderer;
#end
