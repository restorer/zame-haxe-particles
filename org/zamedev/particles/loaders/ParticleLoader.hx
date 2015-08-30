package org.zamedev.particles.loaders;

import haxe.crypto.Base64;
import haxe.io.BytesInput;
import haxe.io.Path;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.errors.Error;
import openfl.geom.Rectangle;
import org.zamedev.particles.ParticleSystem;
import org.zamedev.particles.internal.tiff.TiffDecoder;

class ParticleLoader {
    public static function load(path : String) : ParticleSystem {
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

    public static function loadTexture(textureImageData : String, textureFileName : String, path : String) : BitmapData {
        if (textureImageData == null || textureImageData.length == 0) {
            return Assets.getBitmapData(Path.directory(path) + "/" + textureFileName);
        }

        var data = Base64.decode(textureImageData);

        if (data.get(0) == 0x1f && data.get(1) == 0x8b) {
            #if format
                var reader = new format.gz.Reader(new BytesInput(data));
                data = reader.read().data;
            #else
                throw "haxelib \"format\" is required for compressed embedded textures";
            #end
        }

        var decoded = TiffDecoder.decode(data);

        var result = new BitmapData(decoded.width, decoded.height, true, 0);
        result.setPixels(new Rectangle(0.0, 0.0, decoded.width, decoded.height), decoded.pixels);

        return result;
    }
}
