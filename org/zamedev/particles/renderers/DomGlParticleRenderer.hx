package org.zamedev.particles.renderers;

import openfl.display.DOMRenderer;
import openfl.display.OpenGLRenderer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.RenderEvent;
import openfl.geom.Matrix;
import openfl.Lib;
import org.zamedev.particles.ParticleSystem;

#if (js && html5 && lime >= "7.0.0")
    import js.Browser;
    import js.html.CanvasElement;
    import lime._internal.backend.html5.HTML5WebGL2RenderContext;
    import lime.graphics.opengl.GL;
    import lime.graphics.RenderContext;
#end

#if (lime >= "7.0.0")
    @:access(lime._internal.backend.html5.HTML5WebGL2RenderContext)
    @:access(lime.graphics.opengl.GL)
    @:access(lime.graphics.RenderContext)
    @:access(openfl.display.OpenGLRenderer)
#end
class DomGlParticleRenderer extends Sprite implements ParticleSystemRenderer {
    private var manualUpdate : Bool;
    private var rawRenderer = new RawGlParticleRenderer();
    private var lastStageWidth : Int = -1;
    private var lastStageHeight : Int = -1;

	#if (js && html5 && lime >= "7.0.0")
    	private var canvasElement : Null<CanvasElement> = null;
        private var openGlRenderer : Null<OpenGLRenderer> = null;
	#end

    public function new(manualUpdate : Bool = false) {
        super();
        this.manualUpdate = manualUpdate;

        addEventListener(RenderEvent.CLEAR_DOM, onClearDom);
        addEventListener(RenderEvent.RENDER_DOM, onRenderDom);
    }

    public function addParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        if (!rawRenderer.hasParticleSystems() && !manualUpdate) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        rawRenderer.addParticleSystem(ps);
        return this;
    }

    public function removeParticleSystem(ps : ParticleSystem) : ParticleSystemRenderer {
        rawRenderer.removeParticleSystem(ps);

        if (!rawRenderer.hasParticleSystems() && !manualUpdate) {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        return this;
    }

    public function update() : Void {
        rawRenderer.update();
        invalidate();
    }

    private function onEnterFrame(_) : Void {
        update();
    }

    private function onClearDom(event : RenderEvent) : Void {
        #if (js && html5 && lime >= "7.0.0")
            var renderer : DOMRenderer = cast event.renderer;
            renderer.clearStyle(canvasElement);
        #end
    }

    private function onRenderDom(event : RenderEvent) : Void {
        #if (js && html5 && lime >= "7.0.0")
            var renderer : DOMRenderer = cast event.renderer;

            if (canvasElement == null) {
                canvasElement = cast Browser.document.createElement("canvas");
                canvasElement.addEventListener("webglcontextlost", onWebGlContextLost, false);
                canvasElement.addEventListener("webglcontextrestored", onWebGlContextRestored, false);
            }

            if (lastStageWidth != Lib.current.stage.stageWidth || lastStageHeight != Lib.current.stage.stageHeight) {
                canvasElement.width = Lib.current.stage.stageWidth;
                canvasElement.height = Lib.current.stage.stageHeight;

                lastStageWidth = Lib.current.stage.stageWidth;
                lastStageHeight = Lib.current.stage.stageHeight;
            }

            if (openGlRenderer == null) {
                createContext();
            }

            renderer.applyStyle(this, canvasElement);
            canvasElement.style.setProperty("pointer-events", "none", null);

            if (openGlRenderer != null) {
                if (openGlRenderer.__worldTransform == null) {
                    openGlRenderer.__worldTransform = new Matrix();
                }

                if (Lib.current.stage.stageWidth > 0 && Lib.current.stage.stageHeight > 0) {
                    openGlRenderer.__worldTransform.identity();
                    openGlRenderer.__worldTransform.translate(- Lib.current.stage.stageWidth, - Lib.current.stage.stageHeight);
                    openGlRenderer.__worldTransform.scale(2.0 / Lib.current.stage.stageWidth, - 2.0 / Lib.current.stage.stageHeight);
                    openGlRenderer.__worldTransform.translate(1.0, -1.0);
                }

                rawRenderer.render(openGlRenderer, event.objectMatrix, event.allowSmoothing);
            }
        #end
    }

    private function onWebGlContextLost(event : js.html.Event) : Void {
        openGlRenderer = null;
    }

    private function onWebGlContextRestored(event : js.html.Event) : Void {
        createContext();
    }

    private function createContext() : Void {
        var webgl : HTML5WebGL2RenderContext = null;

        var options = {
            alpha : true,
            antialias : true,
            depth : false,
            premultipliedAlpha : true,
            stencil : false,
            preserveDrawingBuffer : false,
        };

        for (name in ["webgl", "experimental-webgl"]) {
            webgl = cast canvasElement.getContext(name, options);

            if (webgl != null) {
                break;
            }
        }

        if (webgl != null) {
            #if webgl_debug
                webgl = untyped WebGLDebugUtils.makeDebugContext(webgl);
            #end

            var renderContext = new RenderContext();
            renderContext.window = Lib.current.stage.window;
            // renderContext.attributes = ...;

            renderContext.webgl = webgl;
            renderContext.type = WEBGL;
            renderContext.version = "1";

            if (GL.context == null) {
                GL.context = cast webgl;
                GL.type = WEBGL;
                GL.version = 1;
            }

            openGlRenderer = new OpenGLRenderer(renderContext);
        }
    }

    public static function isSupported() : Bool {
        #if (dom && js && html5 && lime >= "7.0.0")
            if (untyped(!window.WebGLRenderingContext)) {
                return false;
            }

            if (GL.context != null) {
                return true;
            }

			var canvasElement : CanvasElement = cast Browser.document.createElement("canvas");

            for (name in ["webgl", "experimental-webgl"]) {
                if ((cast canvasElement.getContext(name)) != null) {
                    return true;
                }
            }
        #end

        return false;
    }
}
