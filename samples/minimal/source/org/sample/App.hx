package org.sample;

import openfl.display.Sprite;
import openfl.events.Event;
import org.zamedev.particles.loaders.ParticleLoader;
import org.zamedev.particles.renderers.DefaultParticleRenderer;

#if (flash11 && zameparticles_stage3d && openfl < "4.0")
    import com.asliceofcrazypie.flash.TilesheetStage3D;
    import openfl.display3D.Context3DRenderMode;
#end

class App extends Sprite {
    public function new() : Void {
        super();

        #if (flash11 && zameparticles_stage3d && openfl < "4.0")
            addEventListener(Event.ADDED_TO_STAGE, function(_) {
                TilesheetStage3D.init(stage, 0, 5, ready, Context3DRenderMode.AUTO);
            });
        #else
            ready(null);
        #end
    }

    private function ready(result : String) : Void {
        #if (flash11 && zameparticles_stage3d && openfl < "4.0")
            if (result != "success") {
                trace("Stage3D error. Probably wrong wmode.");
                return;
            }
        #end

        var renderer = DefaultParticleRenderer.createInstance();
        addChild(cast renderer);

        var ps = ParticleLoader.load("particle/fire.plist");
        renderer.addParticleSystem(ps);

        ps.emit(stage.stageWidth / 2, stage.stageHeight / 2);
    }
}
