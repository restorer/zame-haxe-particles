package org.zamedev.particles.internal;

import openfl.display.OpenGLView;

#if (html5 && dom)

import js.Browser;
import openfl._internal.renderer.dom.DOMRenderer;
import openfl._internal.renderer.RenderSession;
import openfl.errors.Error;
import openfl.geom.Rectangle;
import openfl.gl.GL;
import openfl.Lib;

#if (lime >= "4.0.0")
    import lime.graphics.GLRenderContext;

    @:access(lime.graphics.GLRenderContext)
    @:access(lime._backend.html5.HTML5GLRenderContext)
#end

@:access(lime.graphics.opengl.GL)
class OpenGLViewExt extends OpenGLView {
    #if (lime >= "4.0.0")
        private var __glRenderContext : GLRenderContext = null;
    #end

    public function new() : Void {
        super();

        if (!OpenGLView.isSupported) {
            throw new Error("OpenGL context required");
        }

        if (__initialized) {
            __context = null;
            __canvas = null;

            __canvas = cast Browser.document.createElement("canvas");
            __canvas.width = Lib.current.stage.stageWidth;
            __canvas.height = Lib.current.stage.stageHeight;

            __context = cast __canvas.getContext("webgl", {
                alpha : true,
                premultipliedAlpha : true,
                antialias : false,
                depth : false,
                stencil : false
            });

            if (__context == null) {
                __context = cast __canvas.getContext("experimental-webgl");
            }

            #if webgl_debug
                __context = untyped WebGLDebugUtils.makeDebugContext(__context);
            #end

            #if (lime >= "4.0.0")
                __glRenderContext = new GLRenderContext(cast __context);
                GL.context = __glRenderContext;
            #else
                GL.context = cast __context;
            #end
        }
    }

    @:noCompletion
    public override function __renderDOM(renderSession : RenderSession) : Void {
        if (stage != null && __worldVisible && __renderable) {
            if (!__added) {
                renderSession.element.appendChild(__canvas);
                __added = true;

                DOMRenderer.initializeElement(this, __canvas, renderSession);
                __style.setProperty("pointer-events", "none", null);
            }

            if (__worldZ != ++renderSession.z) {
                __worldZ = renderSession.z;
                __style.setProperty("z-index", Std.string(__worldZ), null);
            }

            if (__context != null && __render != null) {
                #if (lime >= "4.0.0")
                    GL.context = __glRenderContext;
                #else
                    GL.context = cast __context;
                #end

                if (scrollRect == null) {
                    __render(new Rectangle(0.0, 0.0, __canvas.width, __canvas.height));
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

#else

typedef OpenGLViewExt = OpenGLView;

#end
