package org.zamedev.particles;

#if (html5 && dom)
    typedef DefaultParticleRenderer = GLViewParticleRenderer;
#else
    typedef DefaultParticleRenderer = DrawTilesParticleRenderer;
#end
