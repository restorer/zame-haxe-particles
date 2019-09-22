package org.sample;

import openfl.Assets;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import org.zamedev.particles.ParticleSystem;
import org.zamedev.particles.loaders.ParticleLoader;
import org.zamedev.particles.loaders.PixiParticleLoader;
import org.zamedev.particles.renderers.TileContainerParticleRenderer;

class App extends Sprite {
    private var mousePressed : Bool = false;
    private var particleSystemList : Array<ParticleSystem> = [];
    private var infoTextField : TextField;
    private var currentIndex : Int = 0;

    public function new() : Void {
        super();
        ready();
    }

    private function ready() : Void {
        addClickableArea();
        addInterface();
        loadAndAddParticles();
        updateInfo();

        addChild(new FPS(0, 0, 0xff0000));

        stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
    }

    private function addClickableArea() : Void {
        graphics.clear();
        graphics.beginFill(0x030b2d);
        graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
        graphics.endFill();
    }

    private function addInterface() : Void {
        addTextField(20, 20, 100, 0xfab91e, 0x000000, "Prev");
        infoTextField = addTextField(120, 20, 100, -1, 0xffffff);
        addTextField(220, 20, 100, 0xfab91e, 0x000000, "Next");
        addTextField(20, 55, 300, -1, 0xffffff, "Click to emit");
    }

    private function addTextField(x : Float, y : Float, width : Float, backgroundColor : Int, textColor : Int, ?text : String) : TextField {
        var textField = new TextField();
        textField.x = x;
        textField.y = y;
        textField.width = width;
        textField.height = #if !html5 30 #else 25 #end;
        textField.embedFonts = true;
        textField.selectable = false;

        if (backgroundColor >= 0) {
            textField.background = true;
            textField.backgroundColor = backgroundColor;
        }

        var textFormat = new TextFormat();
        textFormat.size = 24;
        textFormat.color = textColor;
        textFormat.font = Assets.getFont("font/Intro.ttf").fontName;
        textFormat.align = TextFormatAlign.CENTER;

        textField.defaultTextFormat = textFormat;

        if (text != null) {
            textField.text = text;
        }

        addChild(textField);
        return textField;
    }

    private function loadAndAddParticles() : Void {
        var currentStage = (stage != null ? stage : openfl.Lib.current.stage);
        var tileMap = new org.zamedev.particles.internal.TilemapExt(currentStage.stageWidth, currentStage.stageHeight);
        addChild(tileMap);

        var particlesRenderer = new TileContainerParticleRenderer();
        tileMap.addTile(particlesRenderer);

        particleSystemList.push(ParticleLoader.load("particle/galaxy.pex"));
        particleSystemList.push(ParticleLoader.load("particle/duman-2.plist"));
        particleSystemList.push(ParticleLoader.load("particle/ex.plist"));
        particleSystemList.push(ParticleLoader.load("particle/snow.lap"));
        particleSystemList.push(ParticleLoader.load("particle/fancyflame.json"));
        particleSystemList.push(ParticleLoader.load("particle/fire-4.json"));
        particleSystemList.push(ParticleLoader.load("particle/heart.pex"));
        particleSystemList.push(ParticleLoader.load("particle/fountain.lap"));
        particleSystemList.push(ParticleLoader.load("particle/bubbles.json"));
        particleSystemList.push(ParticleLoader.load("particle/fire.plist"));
        particleSystemList.push(ParticleLoader.load("particle/frosty-blood.plist"));
        particleSystemList.push(ParticleLoader.load("particle/line-of-fire.plist"));
        particleSystemList.push(ParticleLoader.load("particle/trippy.plist"));
        particleSystemList.push(ParticleLoader.load("particle/sun.plist"));
        particleSystemList.push(ParticleLoader.load("particle/iris.plist"));
        particleSystemList.push(ParticleLoader.load("particle/hyperflash.plist"));
        particleSystemList.push(ParticleLoader.load("particle/dust.plist"));
        particleSystemList.push(PixiParticleLoader.load("particle/pixi-flame.json", "pixi-flame-2.png"));
        particleSystemList.push(PixiParticleLoader.load("particle/pixi-gas.json", "pixi-gas-1.png"));
        particleSystemList.push(ParticleLoader.load("particle/arrow.json"));

        for (particleSystem in particleSystemList) {
            particlesRenderer.addParticleSystem(particleSystem);
        }
    }

    private function updateInfo() : Void {
        infoTextField.text = Std.string(currentIndex + 1) + ":" + Std.string(particleSystemList.length);
        particleSystemList[currentIndex].emit(stage.stageWidth / 2, stage.stageHeight / 2);
    }

    private function onMouseDown(e : Event) : Void {
        var me : MouseEvent = cast e;

        if (me.stageY >= 20 && me.stageY <= #if !html5 50 #else 45 #end) {
            if (me.stageX >= 20 && me.stageX <= 120) {
                particleSystemList[currentIndex].stop();
                currentIndex = (currentIndex - 1 + particleSystemList.length) % particleSystemList.length;
                updateInfo();
                return;
            }

            if (me.stageX >= 220 && me.stageX <= 320) {
                particleSystemList[currentIndex].stop();
                currentIndex = (currentIndex + 1) % particleSystemList.length;
                updateInfo();
                return;
            }
        }

        particleSystemList[currentIndex].emit(me.stageX, me.stageY);
        mousePressed = true;
    }

    private function onMouseMove(e : Event) : Void {
        if (mousePressed) {
            var me : MouseEvent = cast e;
            particleSystemList[currentIndex].emit(me.stageX, me.stageY);
        }
    }

    private function onMouseUp(e : Event) : Void {
        mousePressed = false;
    }
}
