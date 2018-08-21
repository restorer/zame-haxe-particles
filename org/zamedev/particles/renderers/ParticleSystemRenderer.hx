package org.zamedev.particles.renderers;

import org.zamedev.particles.ParticleSystem;

interface ParticleSystemRenderer {
    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer;
    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer;
    public function update() : Void;
}
