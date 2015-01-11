package org.zamedev.particles;

#if (html5 || openfl_next)
    typedef DefaultParticleRenderer = GLViewParticleRenderer;
#else
    typedef DefaultParticleRenderer = DrawTilesParticleRenderer;
#end
