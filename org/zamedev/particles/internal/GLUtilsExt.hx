package org.zamedev.particles.internal;

import openfl.display.BitmapData;

#if (openfl < "5.1.0")
    import openfl.gl.GL;
    import openfl.gl.GLProgram;
    import openfl.gl.GLTexture;
    import openfl.utils.UInt8Array;
#else
    import lime.graphics.opengl.GL;
    import lime.graphics.opengl.GLProgram;
    import lime.graphics.opengl.GLTexture;
    import lime.utils.UInt8Array;
#end

class GLUtilsExt {
    public static function texImage2D(bitmapData : BitmapData) : Void {
        #if js
            var pixelData = bitmapData.image.data;
        #else
            var pixelData = new UInt8Array(bitmapData.getPixels(bitmapData.rect));
        #end

        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixelData);
    }

    public static function createTexture(bitmapData : BitmapData, ?wrapSParam : Null<Int>, ?wrapTParam : Null<Int>) : GLTexture {
        if (wrapSParam == null) {
            wrapSParam = GL.CLAMP_TO_EDGE;
        }

        if (wrapTParam == null) {
            wrapTParam = GL.CLAMP_TO_EDGE;
        }

        var texture = GL.createTexture();
        GL.bindTexture(GL.TEXTURE_2D, texture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, wrapSParam);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, wrapTParam);
        texImage2D(bitmapData);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.bindTexture(GL.TEXTURE_2D, null);
        return texture;
    }

    public static function createAndUseProgram(vertexSource : String, fragmentSource : String) : GLProgram {
        var program = GLUtils.createProgram(vertexSource, fragmentSource);
        GL.useProgram(program);
        return program;
    }
}
