package org.zamedev.particles.loaders;

import haxe.io.Path;
import openfl.errors.Error;
import org.zamedev.particles.ParticleSystem;

class ParticleLoader {
    public static function load(path:String):ParticleSystem {
        var ext = Path.extension(path).toLowerCase();

        switch (ext) {
            case "plist":
                return PlistParticleLoader.load(path);

            case "json":
                return JsonParticleLoader.load(path);

            case "pex" | "lap":
                return PexLapParticleLoader.load(path);

            default:
                throw new Error('Unsupported extension "${ext}"');
        }
    }
}
