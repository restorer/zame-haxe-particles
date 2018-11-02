package org.zamedev.particles.renderers;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.RenderEvent;
import org.zamedev.particles.ParticleSystem;

class WebGlParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private var manualUpdate : Bool;
    private var rawRenderer = new RawGlParticleRenderer();

    public function new(manualUpdate : Bool = false) {
        super();
        this.manualUpdate = manualUpdate;
    }

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        if (!rawRenderer.hasParticleSystems()) {
            addEventListener(RenderEvent.RENDER_OPENGL, onRenderOpenGl);

            if (!manualUpdate) {
                addEventListener(Event.ENTER_FRAME, onEnterFrame);
            }
        }

        rawRenderer.addParticleSystem(ps);
        return this;
    }

    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        rawRenderer.removeParticleSystem(ps);

        if (!rawRenderer.hasParticleSystems()) {
            removeEventListener(RenderEvent.RENDER_OPENGL, onRenderOpenGl);

            if (!manualUpdate) {
                removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            }
        }

        return this;
    }

    public function update() : Void {
        rawRenderer.update();
        invalidate();
    }

    private function onRenderOpenGl(event : RenderEvent) : Void {
        rawRenderer.render(cast event.renderer, event.objectMatrix, event.allowSmoothing);
    }

    private function onEnterFrame(_) : Void {
        update();
    }
}
