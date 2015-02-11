package org.zamedev.particles.renderers;

#if (html5 && dom)
    typedef DefaultParticleRenderer = GLViewParticleRenderer;
#else
    typedef DefaultParticleRenderer = DrawTilesParticleRenderer;
#end
