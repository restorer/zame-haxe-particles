package org.zamedev.particles.renderers;

#if (html5 && dom)

import openfl.geom.Rectangle;
import openfl.errors.Error;
import org.zamedev.particles.internal.GLUtilsExt;
import org.zamedev.particles.internal.Matrix4;
import org.zamedev.particles.internal.OpenGLViewExt;
import org.zamedev.particles.internal.SizeUtils;

#if (openfl < "5.1.0")
    import openfl.gl.GL;
    import openfl.gl.GLBuffer;
    import openfl.gl.GLProgram;
    import openfl.gl.GLTexture;
    import openfl.gl.GLUniformLocation;
    import openfl.utils.Float32Array;
    import openfl.utils.Int16Array;
#else
    import lime.graphics.opengl.GL;
    import lime.graphics.opengl.GLBuffer;
    import lime.graphics.opengl.GLProgram;
    import lime.graphics.opengl.GLTexture;
    import lime.graphics.opengl.GLUniformLocation;
    import lime.utils.Float32Array;
    import lime.utils.Int16Array;
#end

// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display/Stage3D.html
// https://github.com/openfl/openfl-samples/blob/master/SimpleOpenGLView/Source/Main.hx

typedef GLViewParticleRendererData = {
    ps : ParticleSystem,
    texture : GLTexture,
    vertexBuffer : GLBuffer,
    vertexData : Float32Array,
    indicesBuffer : GLBuffer,
    indicesData : Int16Array,
    updated : Bool,
};

class GLViewParticleRenderer extends OpenGLViewExt implements ParticleSystemRenderer {
    private static inline var VERTEX_XYZ : Int = 0;
    private static inline var VERTEX_UV : Int = 3;
    private static inline var VERTEX_RGBA : Int = 5;
    private static inline var VERTEX_SIZE : Int = 9;
    private static inline var INDEX_SIZE : Int = 6;

    private var initialized : Bool = false;
    private var dataList : Array<GLViewParticleRendererData> = [];
    private var program : GLProgram;
    private var vertexAttrLocation : Int;
    private var textureAttrLocation : Int;
    private var colorAttrLocation : Int;
    private var matrixUniformLocation : GLUniformLocation;
    private var imageUniformLocation : GLUniformLocation;

    public function new(manualUpdate : Bool = false) {
        super();

        if (manualUpdate) {
            throw new Error("Manual update is not supported by GLViewParticleRenderer");
        }
    }

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        if (!initialized) {
            initGl();
            initialized = true;
        }

        ps.__initialize();

        var texture = GLUtilsExt.createTexture(ps.textureBitmapData);

        var vertexBuffer = GL.createBuffer();
        var vertexData = new Float32Array(VERTEX_SIZE * 4 * ps.maxParticles);

        var indicesBuffer = GL.createBuffer();
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

        if (dataList.length == 0) {
            render = renderGl;
        }

        dataList.push({
            ps: ps,
            texture: texture,
            vertexBuffer: vertexBuffer,
            vertexData: vertexData,
            indicesBuffer: indicesBuffer,
            indicesData: indicesData,
            updated: false,
        });

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

        if (dataList.length == 0) {
            render = null;
        }

        return this;
    }

    public function update() : Void {
        throw new Error("Manual update is not supported by GLViewParticleRenderer");
    }

    private function initGl() : Void {
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

            void main(void) {
                color = texture2D(uImage, vTexCoord);

                gl_FragColor = vec4(
                    color.r * color.a * vColor.r,
                    color.g * color.a * vColor.g,
                    color.b * color.a * vColor.b,
                    color.a * vColor.a
                );
            }
        ";

        program = GLUtilsExt.createAndUseProgram(vertexShaderSource, fragmentShaderSource);

        vertexAttrLocation = GL.getAttribLocation(program, "aPosition");
        textureAttrLocation = GL.getAttribLocation(program, "aTexCoord");
        colorAttrLocation = GL.getAttribLocation(program, "aColor");
        matrixUniformLocation = GL.getUniformLocation(program, "uMatrix");
        imageUniformLocation = GL.getUniformLocation(program, "uImage");

        GL.enableVertexAttribArray(vertexAttrLocation);
        GL.enableVertexAttribArray(textureAttrLocation);
        GL.enableVertexAttribArray(colorAttrLocation);
        GL.uniform1i(imageUniformLocation, 0);

        GL.useProgram(null);
    }

    private function renderGl(rect : Rectangle) : Void {
        var updated = false;

        for (data in dataList) {
            if (data.updated = data.ps.__update()) {
                updated = true;
            }
        }

        if (!updated) {
            return;
        }

        GL.viewport(Std.int(rect.x), Std.int(rect.y), Std.int(rect.width), Std.int(rect.height));
        GL.clearColor(0.0, 0.0, 0.0, 0.0);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

        GL.useProgram(program);
        GL.activeTexture(GL.TEXTURE0);
        GL.disable(GL.CULL_FACE);
        GL.enable(GL.BLEND);

        #if desktop
            GL.enable(GL.TEXTURE_2D);
        #end

        var worldMatrix = __getWorldTransform();
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

        #if (openfl < "5.1.0")
            GL.uniformMatrix4fv(matrixUniformLocation, false, matrix);
        #else
            GL.uniformMatrix4fvWEBGL(matrixUniformLocation, false, matrix);
        #end

        for (data in dataList) {
            if (!data.updated) {
                continue;
            }

            var ps = data.ps;
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

            GL.bindTexture(GL.TEXTURE_2D, data.texture);
            GL.blendFunc(ps.blendFuncSource, ps.blendFuncDestination);

            GL.bindBuffer(GL.ARRAY_BUFFER, data.vertexBuffer);

            #if (openfl < "5.1.0")
                GL.bufferData(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
            #else
                GL.bufferDataWEBGL(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
            #end

            GL.vertexAttribPointer(vertexAttrLocation, 3, GL.FLOAT, false, VERTEX_SIZE * SizeUtils.SIZE_FLOAT32, VERTEX_XYZ);
            GL.vertexAttribPointer(textureAttrLocation, 2, GL.FLOAT, false, VERTEX_SIZE * SizeUtils.SIZE_FLOAT32, VERTEX_UV * SizeUtils.SIZE_FLOAT32);
            GL.vertexAttribPointer(colorAttrLocation, 4, GL.FLOAT, false, VERTEX_SIZE * SizeUtils.SIZE_FLOAT32, VERTEX_RGBA * SizeUtils.SIZE_FLOAT32);
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, data.indicesBuffer);

            #if (openfl < "5.1.0")
                GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indicesData, GL.DYNAMIC_DRAW);
            #else
                GL.bufferDataWEBGL(GL.ELEMENT_ARRAY_BUFFER, indicesData, GL.DYNAMIC_DRAW);
            #end

            GL.drawElements(GL.TRIANGLES, ps.__particleCount * INDEX_SIZE, GL.UNSIGNED_SHORT, 0);
        }

        #if desktop
            GL.disable(GL.TEXTURE_2D);
        #end

        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
        GL.bindBuffer(GL.ARRAY_BUFFER, null);
        GL.useProgram(null);
    }
}

#end
