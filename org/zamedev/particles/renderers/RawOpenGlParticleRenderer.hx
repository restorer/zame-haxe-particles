package org.zamedev.particles.renderers;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Float32Array;
import lime.utils.Int16Array;
import openfl.display.OpenGLRenderer;
import openfl.geom.Matrix;
import org.zamedev.particles.ParticleSystem;

#if (lime >= "7.0.0")
    import lime.graphics.WebGLRenderContext;
#else
    import lime.graphics.opengl.WebGLContext in WebGLRenderContext;
#end

class RawOpenGlParticleRendererData {
    public var ps : ParticleSystem;
    public var vertexData : Float32Array;
    public var indicesData : Int16Array;
    public var initialized : Bool = false;
    public var texture : GLTexture;
    public var vertexBuffer : GLBuffer;
    public var indicesBuffer : GLBuffer;

    public function new(ps : ParticleSystem, vertexData : Float32Array, indicesData : Int16Array) {
        this.ps = ps;
        this.vertexData = vertexData;
        this.indicesData = indicesData;
    }
}

class RawOpenGlParticleRenderer implements ParticleSystemRenderer {
    private static inline var SIZE_FLOAT32 = 4;

    private static inline var VERTEX_XYZ : Int = 0;
    private static inline var VERTEX_UV : Int = 3;
    private static inline var VERTEX_RGBA : Int = 5;
    private static inline var VERTEX_SIZE : Int = 9;
    private static inline var INDEX_SIZE : Int = 6;

    private static var VERTEX_SHADER_SOURCE = "
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

    // For non-premultiplied alpha:
    //
    // gl_FragColor = vec4(
    //     color.r * color.a * vColor.r,
    //     color.g * color.a * vColor.g,
    //     color.b * color.a * vColor.b,
    //     color.a * vColor.a
    // );
    private static var FRAGMENT_SHADER_SOURCE = #if !desktop "precision mediump float;" + #end "
        varying vec4 vColor;
        varying vec2 vTexCoord;

        uniform sampler2D uImage;

        vec4 color;

        void main(void) {
            color = texture2D(uImage, vTexCoord);

            gl_FragColor = vec4(
                color.r * vColor.r,
                color.g * vColor.g,
                color.b * vColor.b,
                color.a * vColor.a
            );
        }
    ";

    private var dataList : Array<RawOpenGlParticleRendererData> = [];
    private var program : Null<GLProgram> = null;
    private var vertexAttrLocation : Int;
    private var textureAttrLocation : Int;
    private var colorAttrLocation : Int;
    private var matrixUniformLocation : GLUniformLocation;
    private var imageUniformLocation : GLUniformLocation;

    public function new() {
    }

    public function hasParticleSystems() : Bool {
        return (dataList.length != 0);
    }

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        ps.__initialize();

        var vertexData = new Float32Array(VERTEX_SIZE * 4 * ps.maxParticles);
        var indicesData = new Int16Array(INDEX_SIZE * ps.maxParticles);

        var vertexPos : Int = 0;
        var indexPos : Int = 0;
        var quadIdx : Int = 0;

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

        dataList.push(new RawOpenGlParticleRendererData(ps, vertexData, indicesData));
        return this;
    }

    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        var index = 0;

        while (index < dataList.length) {
            if (dataList[index].ps == ps) {
                dataList.splice(index, 1);
            } else {
                index++;
            }
        }

        return this;
    }

    public function update() : Void {
        for (data in dataList) {
            data.ps.__update();
        }
    }

    public function render(renderer : OpenGLRenderer, objectMatrix : Matrix, allowSmoothing : Bool = true) : Void {
        var gl : WebGLRenderContext = renderer.gl;

        // Initialize

        if (program == null) {
            program = #if (lime >= "7.0.0")
                GLProgram.fromSources(gl, VERTEX_SHADER_SOURCE, FRAGMENT_SHADER_SOURCE);
            #else
                lime.utils.GLUtils.createProgram(VERTEX_SHADER_SOURCE, FRAGMENT_SHADER_SOURCE);
            #end

            gl.useProgram(program);

            vertexAttrLocation = GL.getAttribLocation(program, "aPosition");
            textureAttrLocation = GL.getAttribLocation(program, "aTexCoord");
            colorAttrLocation = GL.getAttribLocation(program, "aColor");
            matrixUniformLocation = GL.getUniformLocation(program, "uMatrix");
            imageUniformLocation = GL.getUniformLocation(program, "uImage");

            gl.uniform1i(imageUniformLocation, 0);
        } else {
            gl.useProgram(program);
        }

        // Startup

        gl.enableVertexAttribArray(vertexAttrLocation);
        gl.enableVertexAttribArray(textureAttrLocation);
        gl.enableVertexAttribArray(colorAttrLocation);

        gl.activeTexture(gl.TEXTURE0);
        gl.disable(gl.CULL_FACE);
        gl.enable(gl.BLEND);

        #if desktop
            gl.enable(GL.TEXTURE_2D);
        #end

        // Main

        // gl.clearColor(0.0, 0.0, 0.0, 0.0);
        // gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.uniformMatrix4fv(matrixUniformLocation, false, renderer.getMatrix(objectMatrix));

        for (data in dataList) {
            var ps = data.ps;

            if (!data.initialized) {
                #if !flash
                    data.texture = ps.textureBitmapData.getTexture(@:privateAccess renderer.__context);
                #end

                data.vertexBuffer = gl.createBuffer();
                data.indicesBuffer = gl.createBuffer();
                data.initialized = true;
            }

            var vertexData = data.vertexData;
            var indicesData = data.indicesData;
            var vertexPos : Int = 0;

            var widthMult : Float;
            var heightMult : Float;
            var sizeMult : Float;

            if (ps.forceSquareTexture
                || ps.textureBitmapData.width == ps.textureBitmapData.height
                || ps.textureBitmapData.width == 0
                || ps.textureBitmapData.height == 0
            ) {
                widthMult = 1.0;
                heightMult = 1.0;
                sizeMult = 1.0;
            } else if (ps.textureBitmapData.width > ps.textureBitmapData.height) {
                widthMult = ps.textureBitmapData.width / ps.textureBitmapData.height;
                heightMult = 1.0;
                sizeMult = ps.textureBitmapData.height / ps.textureBitmapData.width;
            } else {
                widthMult = 1.0;
                heightMult = ps.textureBitmapData.height / ps.textureBitmapData.width;
                sizeMult = ps.textureBitmapData.width / ps.textureBitmapData.height;
            }

            sizeMult *= ps.particleScaleSize * 0.5;

            for (i in 0 ... ps.__particleCount) {
                var particle = ps.__particleList[i];

                var tx : Float = particle.position.x * ps.particleScaleX;
                var ty : Float = particle.position.y * ps.particleScaleY;
                var cr : Float = particle.color.r;
                var cg : Float = particle.color.g;
                var cb : Float = particle.color.b;
                var ca : Float = particle.color.a;
                var sn : Float = Math.sin(particle.rotation);
                var cs : Float = Math.cos(particle.rotation);

                var halfSize : Float = particle.particleSize * sizeMult;
                var halfWidth : Float = halfSize * widthMult;
                var halfHeight : Float = halfSize * heightMult;

                vertexData[vertexPos + VERTEX_XYZ + 0] = halfWidth * cs - halfHeight * sn + tx;
                vertexData[vertexPos + VERTEX_XYZ + 1] = halfWidth * sn + halfHeight * cs + ty;
                vertexData[vertexPos + VERTEX_RGBA + 0] = cr;
                vertexData[vertexPos + VERTEX_RGBA + 1] = cg;
                vertexData[vertexPos + VERTEX_RGBA + 2] = cb;
                vertexData[vertexPos + VERTEX_RGBA + 3] = ca;
                vertexPos += VERTEX_SIZE;

                vertexData[vertexPos + VERTEX_XYZ + 0] = (-halfWidth) * cs - halfHeight * sn + tx;
                vertexData[vertexPos + VERTEX_XYZ + 1] = (-halfWidth) * sn + halfHeight * cs + ty;
                vertexData[vertexPos + VERTEX_RGBA + 0] = cr;
                vertexData[vertexPos + VERTEX_RGBA + 1] = cg;
                vertexData[vertexPos + VERTEX_RGBA + 2] = cb;
                vertexData[vertexPos + VERTEX_RGBA + 3] = ca;
                vertexPos += VERTEX_SIZE;

                vertexData[vertexPos + VERTEX_XYZ + 0] = halfWidth * cs - (-halfHeight) * sn + tx;
                vertexData[vertexPos + VERTEX_XYZ + 1] = halfWidth * sn + (-halfHeight) * cs + ty;
                vertexData[vertexPos + VERTEX_RGBA + 0] = cr;
                vertexData[vertexPos + VERTEX_RGBA + 1] = cg;
                vertexData[vertexPos + VERTEX_RGBA + 2] = cb;
                vertexData[vertexPos + VERTEX_RGBA + 3] = ca;
                vertexPos += VERTEX_SIZE;

                vertexData[vertexPos + VERTEX_XYZ + 0] = (-halfWidth) * cs - (-halfHeight) * sn + tx;
                vertexData[vertexPos + VERTEX_XYZ + 1] = (-halfWidth) * sn + (-halfHeight) * cs + ty;
                vertexData[vertexPos + VERTEX_RGBA + 0] = cr;
                vertexData[vertexPos + VERTEX_RGBA + 1] = cg;
                vertexData[vertexPos + VERTEX_RGBA + 2] = cb;
                vertexData[vertexPos + VERTEX_RGBA + 3] = ca;
                vertexPos += VERTEX_SIZE;
            }

            gl.bindBuffer(gl.ARRAY_BUFFER, data.vertexBuffer);
            gl.bufferData(gl.ARRAY_BUFFER, vertexData, gl.DYNAMIC_DRAW);

            gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, data.indicesBuffer);
            gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indicesData, gl.DYNAMIC_DRAW);

            gl.vertexAttribPointer(vertexAttrLocation, 3, gl.FLOAT, false, VERTEX_SIZE * SIZE_FLOAT32, VERTEX_XYZ);
            gl.vertexAttribPointer(textureAttrLocation, 2, gl.FLOAT, false, VERTEX_SIZE * SIZE_FLOAT32, VERTEX_UV * SIZE_FLOAT32);
            gl.vertexAttribPointer(colorAttrLocation, 4, gl.FLOAT, false, VERTEX_SIZE * SIZE_FLOAT32, VERTEX_RGBA * SIZE_FLOAT32);

            gl.bindTexture(gl.TEXTURE_2D, data.texture);

            if (allowSmoothing) {
                gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
                gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
            } else {
    			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
	    		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            }

            gl.blendFunc(ps.blendFuncSource, ps.blendFuncDestination);
            gl.drawElements(GL.TRIANGLES, ps.__particleCount * INDEX_SIZE, GL.UNSIGNED_SHORT, 0);
        }

        // Shutdown

        #if desktop
            gl.disable(gl.TEXTURE_2D);
        #end

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
        gl.bindBuffer(gl.ARRAY_BUFFER, null);
        gl.bindTexture(gl.TEXTURE_2D, null);

        gl.disableVertexAttribArray(vertexAttrLocation);
        gl.disableVertexAttribArray(textureAttrLocation);
        gl.disableVertexAttribArray(colorAttrLocation);
        gl.useProgram(null);
    }
}
