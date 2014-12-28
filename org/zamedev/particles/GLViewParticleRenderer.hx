package org.zamedev.particles;

import openfl.geom.Rectangle;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLTexture;
import openfl.gl.GLUniformLocation;
import openfl.utils.Float32Array;
import openfl.utils.Int16Array;
import openfl.utils.UInt8Array;
import org.zamedev.particles.internal.GLUtils;
import org.zamedev.particles.internal.Matrix4;
import org.zamedev.particles.internal.OpenGLViewExt;
import org.zamedev.particles.internal.SizeUtils;

class GLViewParticleRenderer extends OpenGLViewExt implements ParticleSystemRenderer {
    private static inline var VERTEX_XYZ = 0;
    private static inline var VERTEX_UV = 3;
    private static inline var VERTEX_RGBA = 5;
    private static inline var VERTEX_SIZE = 9;
    private static inline var INDEX_SIZE = 6;

    private var ps:ParticleSystem;
    private var program:GLProgram;
    private var vertexAttrLocation:Int;
    private var textureAttrLocation:Int;
    private var colorAttrLocation:Int;
    private var matrixUniformLocation:GLUniformLocation;
    private var imageUniformLocation:GLUniformLocation;
    private var texture:GLTexture;
    private var vertexBuffer:GLBuffer;
    private var vertexData:Float32Array;
    private var indicesBuffer:GLBuffer;
    private var indicesData:Int16Array;

    public function init(ps:ParticleSystem):Void {
        this.ps = ps;

        initGl();
        render = renderGl;
    }

    public function destroy():Void {
        render = null;
    }

    public function initGl() {
        var bitmapData = ps.textureBitmapData;

        // vColor = aColor;

        var vertexShaderSource = "
            varying vec4 vColor;
            varying vec2 vTexCoord;

            attribute vec4 aColor;
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;

            uniform mat4 uMatrix;

            void main(void) {
                vColor = aColor;
                vTexCoord = aTexCoord;
                gl_Position = uMatrix * aPosition;
            }
        ";

        var fragmentShaderSource = #if !desktop "precision mediump float;" + #end "
            varying vec4 vColor;
            varying vec2 vTexCoord;

            uniform sampler2D uImage;

            vec4 color;

            void main(void) {" +
                #if lime_legacy
                    "color = texture2D(uImage, vTexCoord).gbar;"
                #else
                    "color = texture2D(uImage, vTexCoord);"
                #end
            + "
                gl_FragColor = vec4(
                    color.r * color.a * vColor.r,
                    color.g * color.a * vColor.g,
                    color.b * color.a * vColor.b,
                    color.a * vColor.a
                );
            }
        ";

        program = GLUtils.createProgram(vertexShaderSource, fragmentShaderSource);
        GL.useProgram(program);

        vertexAttrLocation = GL.getAttribLocation(program, "aPosition");
        textureAttrLocation = GL.getAttribLocation(program, "aTexCoord");
        colorAttrLocation = GL.getAttribLocation(program, "aColor");

        matrixUniformLocation = GL.getUniformLocation(program, "uMatrix");
        imageUniformLocation = GL.getUniformLocation(program, "uImage");

        GL.enableVertexAttribArray(vertexAttrLocation);
        GL.enableVertexAttribArray(textureAttrLocation);
        GL.enableVertexAttribArray(colorAttrLocation);
        GL.uniform1i(imageUniformLocation, 0);

        texture = GL.createTexture();
        GL.bindTexture(GL.TEXTURE_2D, texture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

        #if js
            var pixelData = bitmapData.getPixels(bitmapData.rect).byteView;
        #else
            var pixelData = new UInt8Array(bitmapData.getPixels(bitmapData.rect));
        #end

        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixelData);

        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.bindTexture(GL.TEXTURE_2D, null);

        vertexBuffer = GL.createBuffer();
        vertexData = new Float32Array(VERTEX_SIZE * 4 * ps.maxParticles);

        indicesBuffer = GL.createBuffer();
        indicesData = new Int16Array(INDEX_SIZE * ps.maxParticles);

        var vertexPos:Int = 0;
        var indexPos:Int = 0;
        var quadIdx:Int = 0;

        for (i in 0 ... ps.maxParticles) {
            vertexData[vertexPos + VERTEX_XYZ + 3] = 0.0;
            vertexData[vertexPos + VERTEX_UV + 0] = 1.0;
            vertexData[vertexPos + VERTEX_UV + 1] = 1.0;
            vertexPos += VERTEX_SIZE;

            vertexData[vertexPos + VERTEX_XYZ + 3] = 0.0;
            vertexData[vertexPos + VERTEX_UV + 0] = 0.0;
            vertexData[vertexPos + VERTEX_UV + 1] = 1.0;
            vertexPos += VERTEX_SIZE;

            vertexData[vertexPos + VERTEX_XYZ + 3] = 0.0;
            vertexData[vertexPos + VERTEX_UV + 0] = 1.0;
            vertexData[vertexPos + VERTEX_UV + 1] = 0.0;
            vertexPos += VERTEX_SIZE;

            vertexData[vertexPos + VERTEX_XYZ + 3] = 0.0;
            vertexData[vertexPos + VERTEX_UV + 0] = 0.0;
            vertexData[vertexPos + VERTEX_UV + 1] = 0.0;
            vertexPos += VERTEX_SIZE;

            indicesData[indexPos + 0] = quadIdx + 0;
            indicesData[indexPos + 1] = quadIdx + 1;
            indicesData[indexPos + 2] = quadIdx + 2;
            indicesData[indexPos + 3] = quadIdx + 2;
            indicesData[indexPos + 4] = quadIdx + 3;
            indicesData[indexPos + 5] = quadIdx + 1;

            indexPos += INDEX_SIZE;
            quadIdx += 4;
        }

        GL.useProgram(null);
    }

    private function renderGl(rect:Rectangle):Void {
        if (!ps.__update()) {
            return;
        }

        GL.viewport(Std.int(rect.x), Std.int(rect.y), Std.int(rect.width), Std.int(rect.height));
        GL.clearColor(0.0, 0.0, 0.0, 0.0);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

        var vertexPos:Int = 0;

        for (i in 0 ... ps.__particleCount) {
            var particle = ps.__particleList[i];

            var tx = particle.position.x;
            var ty = particle.position.y;
            var cr = particle.color.r;
            var cg = particle.color.g;
            var cb = particle.color.b;
            var ca = particle.color.a;
            var sn = Math.sin(particle.rotation);
            var cs = Math.cos(particle.rotation);
            var halfSize = particle.particleSize * ps.particleScaleSize * 0.5;

            vertexData[vertexPos + VERTEX_XYZ + 0] = halfSize * cs - halfSize * sn + tx;
            vertexData[vertexPos + VERTEX_XYZ + 1] = halfSize * sn + halfSize * cs + ty;
            vertexData[vertexPos + VERTEX_RGBA + 0] = cr;
            vertexData[vertexPos + VERTEX_RGBA + 1] = cg;
            vertexData[vertexPos + VERTEX_RGBA + 2] = cb;
            vertexData[vertexPos + VERTEX_RGBA + 3] = ca;
            vertexPos += VERTEX_SIZE;

            vertexData[vertexPos + VERTEX_XYZ + 0] = (-halfSize) * cs - halfSize * sn + tx;
            vertexData[vertexPos + VERTEX_XYZ + 1] = (-halfSize) * sn + halfSize * cs + ty;
            vertexData[vertexPos + VERTEX_RGBA + 0] = cr;
            vertexData[vertexPos + VERTEX_RGBA + 1] = cg;
            vertexData[vertexPos + VERTEX_RGBA + 2] = cb;
            vertexData[vertexPos + VERTEX_RGBA + 3] = ca;
            vertexPos += VERTEX_SIZE;

            vertexData[vertexPos + VERTEX_XYZ + 0] = halfSize * cs - (-halfSize) * sn + tx;
            vertexData[vertexPos + VERTEX_XYZ + 1] = halfSize * sn + (-halfSize) * cs + ty;
            vertexData[vertexPos + VERTEX_RGBA + 0] = cr;
            vertexData[vertexPos + VERTEX_RGBA + 1] = cg;
            vertexData[vertexPos + VERTEX_RGBA + 2] = cb;
            vertexData[vertexPos + VERTEX_RGBA + 3] = ca;
            vertexPos += VERTEX_SIZE;

            vertexData[vertexPos + VERTEX_XYZ + 0] = (-halfSize) * cs - (-halfSize) * sn + tx;
            vertexData[vertexPos + VERTEX_XYZ + 1] = (-halfSize) * sn + (-halfSize) * cs + ty;
            vertexData[vertexPos + VERTEX_RGBA + 0] = cr;
            vertexData[vertexPos + VERTEX_RGBA + 1] = cg;
            vertexData[vertexPos + VERTEX_RGBA + 2] = cb;
            vertexData[vertexPos + VERTEX_RGBA + 3] = ca;
            vertexPos += VERTEX_SIZE;
        }

        GL.useProgram(program);

        var worldMatrix = __getTransform();
        var worldMatrixInv = worldMatrix.clone();
        worldMatrixInv.tx = 0.0;
        worldMatrixInv.ty = 0.0;
        worldMatrixInv.invert();

        var matrix = Matrix4.createOrtho(
            0.0,
            rect.width * worldMatrixInv.a + rect.height * worldMatrixInv.c,
            rect.width * worldMatrixInv.b + rect.height * worldMatrixInv.d,
            0.0,
            0.0,
            1000.0
        );

        matrix.prependTranslation(
            worldMatrix.tx * worldMatrixInv.a + worldMatrix.ty * worldMatrixInv.c,
            worldMatrix.tx * worldMatrixInv.b + worldMatrix.ty * worldMatrixInv.d,
            0.0
        );

        GL.uniformMatrix4fv(matrixUniformLocation, false, matrix);

        GL.activeTexture(GL.TEXTURE0);
        GL.bindTexture(GL.TEXTURE_2D, texture);

        #if desktop
            GL.enable(GL.TEXTURE_2D);
        #end

        GL.disable(GL.CULL_FACE);
        GL.enable(GL.BLEND);
        GL.blendFunc(ps.blendFuncSource, ps.blendFuncDestination);

        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
        GL.vertexAttribPointer(vertexAttrLocation, 3, GL.FLOAT, false, VERTEX_SIZE * SizeUtils.SIZE_FLOAT32, VERTEX_XYZ);
        GL.vertexAttribPointer(textureAttrLocation, 2, GL.FLOAT, false, VERTEX_SIZE * SizeUtils.SIZE_FLOAT32, VERTEX_UV * SizeUtils.SIZE_FLOAT32);
        GL.vertexAttribPointer(colorAttrLocation, 4, GL.FLOAT, false, VERTEX_SIZE * SizeUtils.SIZE_FLOAT32, VERTEX_RGBA * SizeUtils.SIZE_FLOAT32);
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indicesBuffer);
        GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indicesData, GL.DYNAMIC_DRAW);
        GL.drawElements(GL.TRIANGLES, ps.__particleCount * INDEX_SIZE, GL.UNSIGNED_SHORT, 0);

        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
        GL.bindBuffer(GL.ARRAY_BUFFER, null);
        GL.useProgram(null);
    }
}
