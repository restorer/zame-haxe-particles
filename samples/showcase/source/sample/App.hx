package sample;

import openfl.Assets;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import org.zamedev.particles.DefaultParticleRenderer;
import org.zamedev.particles.ParticleSystem;
import org.zamedev.particles.ParticleSystemLoader;

class App extends Sprite {
    private var particleSystemList:Array<ParticleSystem> = [];
    private var currentParticleSystem:ParticleSystem;

    public function new() {
        super();

        addClickableArea();
        addTextNote();
        loadAndAddParticles();

        currentParticleSystem = particleSystemList[0];

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
    }

    private function addClickableArea():Void {
        graphics.clear();
        graphics.beginFill(0x0a0b29);
        graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
        graphics.endFill();
    }

    private function addTextNote():Void {
        var textField = new TextField();
        textField.x = 20;
        textField.y = 20;
        textField.width = 780;
        textField.embedFonts = true;

        var textFormat = new TextFormat();
        textFormat.size = 24;
        textFormat.color = 0xffffff;
        textFormat.font = Assets.getFont("font/Intro.ttf").fontName;

        textField.defaultTextFormat = textFormat;
        textField.text = "Click to emit, press 1 ... 8 to switch";

        addChild(textField);
    }

    private function loadAndAddParticles():Void {
        var particlesRenderer = new DefaultParticleRenderer();
        addChild(cast particlesRenderer);

        particleSystemList.push(ParticleSystemLoader.loadFromPlist("particle/fire.plist"));
        particleSystemList.push(ParticleSystemLoader.loadFromPlist("particle/frosty-blood.plist"));
        particleSystemList.push(ParticleSystemLoader.loadFromPlist("particle/line-of-fire.plist"));
        particleSystemList.push(ParticleSystemLoader.loadFromPlist("particle/trippy.plist"));
        particleSystemList.push(ParticleSystemLoader.loadFromPlist("particle/sun.plist"));
        particleSystemList.push(ParticleSystemLoader.loadFromPlist("particle/iris.plist"));
        particleSystemList.push(ParticleSystemLoader.loadFromPlist("particle/hyperflash.plist"));
        particleSystemList.push(ParticleSystemLoader.loadFromPlist("particle/dust.plist"));

        for (particleSystem in particleSystemList) {
            particlesRenderer.addParticleSystem(particleSystem);
        }
    }

    private function onKeyDown(e:Event):Void {
        var ke:KeyboardEvent = cast e;
        var index = Std.int(ke.charCode) - 49;

        if (index >= 0 && index < particleSystemList.length && currentParticleSystem != particleSystemList[index]) {
            currentParticleSystem.stop();
            currentParticleSystem = particleSystemList[index];
        }
    }

    private function onMouseDown(e:Event):Void {
        var me:MouseEvent = cast e;
        currentParticleSystem.emit(me.localX, me.localY);
    }
}
