package org.zamedev.particles.internal;

import openfl.errors.Error;

#if (openfl < "5.1.0")
    import openfl.gl.GL;
    import openfl.gl.GLProgram;
    import openfl.gl.GLShader;
#else
    import lime.graphics.opengl.GL;
    import lime.graphics.opengl.GLProgram;
    import lime.graphics.opengl.GLShader;
#end

// taken from lime.utils.GLUtils (for older openfl versions)

@:access(lime.graphics.opengl.GL)
class GLUtils {
    public static function compileShader(source : String, type : Int) : GLShader {
        var shader = GL.createShader(type);
        GL.shaderSource(shader, source);
        GL.compileShader(shader);

        if (GL.getShaderParameter(shader, GL.COMPILE_STATUS) == 0) {
            switch (type) {
                case GL.VERTEX_SHADER:
                    throw new Error("Error compiling vertex shader");

                case GL.FRAGMENT_SHADER:
                    throw new Error("Error compiling fragment shader");

                default:
                    throw new Error("Error compiling unknown shader type");
            }
        }

        return shader;
    }

    public static function createProgram(vertexSource : String, fragmentSource : String) : GLProgram {
        var vertexShader = compileShader (vertexSource, GL.VERTEX_SHADER);
        var fragmentShader = compileShader (fragmentSource, GL.FRAGMENT_SHADER);

        var program = GL.createProgram();
        GL.attachShader(program, vertexShader);
        GL.attachShader(program, fragmentShader);
        GL.linkProgram(program);

        if (GL.getProgramParameter(program, GL.LINK_STATUS) == 0) {
            throw new Error("Unable to initialize the shader program");
        }

        return program;
    }
}
