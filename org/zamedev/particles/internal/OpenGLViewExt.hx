package org.zamedev.particles.internal;

import openfl.display.OpenGLView;

#if (html5 && dom)

import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.dom.DOMRenderer;
import openfl.errors.Error;
import openfl.geom.Rectangle;

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

                if (__worldZ != ++renderSession.z) {
                    __worldZ = renderSession.z;
                    __style.setProperty("z-index", Std.string(__worldZ), null);
                }
            }

            if (__context != null && __render != null) {
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

#else

typedef OpenGLViewExt = OpenGLView;

#end
