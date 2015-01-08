package org.zamedev.particles.internal;

import openfl.display.OpenGLView;

#if (html5 && dom)

import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.dom.DOMRenderer;
import openfl.errors.Error;
import openfl.geom.Rectangle;
import openfl.gl.GL;

@:access(lime.graphics.opengl.GL)
class OpenGLViewExt extends OpenGLView {
    public function new() {
        super();

        if (!OpenGLView.isSupported) {
            throw new Error("OpenGL context required");
        }
    }

    @:noCompletion
    public override function __renderDOM(renderSession:RenderSession):Void {
        if (stage != null && __worldVisible && __renderable) {
            if (!__added) {
                renderSession.element.appendChild(__canvas);
                __added = true;

                DOMRenderer.initializeElement(this, __canvas, renderSession);
            }

            if (__worldZ != ++renderSession.z) {
                __worldZ = renderSession.z;
                __style.setProperty("z-index", Std.string(__worldZ), null);
            }

            if (__context != null && __render != null) {
                GL.context = cast __context;

                if (scrollRect == null) {
                    __render(new Rectangle(0, 0, __canvas.width, __canvas.height));
                } else {
                    __render(new Rectangle(x + scrollRect.x, y + scrollRect.y, scrollRect.width, scrollRect.height));
                }
            }
        } else if (__added) {
            renderSession.element.removeChild(__canvas);
            __added = false;
        }
    }
}

/*
#elseif flash

import flash.display.Stage;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.events.Event;

class OpenGLViewExt extends OpenGLView {
    private var __stage:Stage;
    private var __stage3d:Stage3D;
    private var __context3d:Context3D;

    public function new() {
        super();
        context3d = null;

        __stage = flash.Lib.current.stage;
        __stage.addEventListener(Event.RESIZE, __onStageResize);

        __stage3d = __stage.stage3Ds[0];
        __stage3d.addEventListener(Event.CONTEXT3D_CREATE, __onContext3dCreated);
        __stage3d.requestContext3D("auto");
    }

    private function __onStageResize(_):Void {
        if (__context3d != null) {
            __context3d.configureBackBuffer(__stage.stageWidth, __stage.stageHeight, 0, false);
        }
    }

    private function __onContext3dCreated(_):Void {
        __context3d = __stage3d.context3D;
        __onStageResize(null);

        addEventListener(Event.ENTER_FRAME, __renderFlash);
    }

    private function __renderFlash(_):Void {
        if (stage != null && __worldVisible && __renderable && __context3d != null && __render != null) {
            if (scrollRect == null) {
                __render(new Rectangle(0, 0, __stage.stageWidth, __stage.stageHeight));
            } else {
                __render(new Rectangle(x + scrollRect.x, y + scrollRect.y, scrollRect.width, scrollRect.height));
            }
        }
    }
}
*/

#else

typedef OpenGLViewExt = OpenGLView;

#end
