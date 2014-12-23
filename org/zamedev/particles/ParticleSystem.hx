package org.zamedev.particles;

import openfl.Assets;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.Tilesheet;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.gl.GL;
import org.zamedev.lib.FileUtils;

using StringTools;
using org.zamedev.lib.DynamicTools;
using org.zamedev.lib.XmlExt;

class ParticleSystem extends Sprite {
    public static inline var EMITTER_TYPE_GRAVITY:Int = 0;
    public static inline var EMITTER_TYPE_RADIAL:Int = 1;

    public static inline var POSITION_TYPE_FREE:Int = 0;
    public static inline var POSITION_TYPE_RELATIVE:Int = 1;
    public static inline var POSITION_TYPE_GROUPED:Int = 2;

    private static inline var TILE_DATA_FIELDS = 9; // x, y, tileId, scale, rotation, red, green, blue, alpha

    public var emitterType:Int;
    public var maxParticles:Int;
    public var positionType:Int;
    public var duration:Float;
    public var gravity:ParticleVector;
    public var particleLifespan:Float;
    public var particleLifespanVariance:Float;
    public var speed:Float;
    public var speedVariance:Float;
    public var sourcePosition:ParticleVector;
    public var sourcePositionVariance:ParticleVector;
    public var angle:Float;
    public var angleVariance:Float;
    public var startParticleSize:Float;
    public var startParticleSizeVariance:Float;
    public var finishParticleSize:Float;
    public var finishParticleSizeVariance:Float;
    public var startColor:ParticleColor;
    public var startColorVariance:ParticleColor;
    public var finishColor:ParticleColor;
    public var finishColorVariance:ParticleColor;
    public var minRadius:Float;
    public var minRadiusVariance:Float;
    public var maxRadius:Float;
    public var maxRadiusVariance:Float;
    public var rotationStart:Float;
    public var rotationStartVariance:Float;
    public var rotationEnd:Float;
    public var rotationEndVariance:Float;
    public var radialAcceleration:Float;
    public var radialAccelerationVariance:Float;
    public var tangentialAcceleration:Float;
    public var tangentialAccelerationVariance:Float;
    public var rotatePerSecond:Float;
    public var rotatePerSecondVariance:Float;
    public var blendFuncDestination:Int;
    public var blendFuncSource:Int;
    public var textureBitmapData:BitmapData;
    public var active:Bool;
    public var restart:Bool;
    public var particleScaleX:Float;
    public var particleScaleY:Float;
    public var particleScaleSize:Float;

    private var initialized:Bool;
    private var particleList:Array<Particle>;
    private var particleCount:Int;
    private var emissionRate:Float;
    private var emitCounter:Float;
    private var prevTime:Int;
    private var elapsedTime:Float;
    private var tilesheet:Tilesheet;
    private var tileData:Array<Float>;

    public function new() {
        super();

        active = false;
        restart = false;
        particleScaleX = 1.0;
        particleScaleY = 1.0;
        particleScaleSize = 1.0;
        initialized = false;
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    public function initialize():Void {
        initialized = true;
        prevTime = -1;

        particleList = new Array<Particle>();
        particleCount = 0;
        emissionRate = maxParticles / particleLifespan;
        emitCounter = 0.0;
        elapsedTime = 0.0;

        for (i in 0 ... maxParticles) {
            particleList[i] = new Particle();
        }

        tilesheet = new Tilesheet(textureBitmapData);
        tilesheet.addTileRect(textureBitmapData.rect.clone(), new Point(textureBitmapData.rect.width / 2, textureBitmapData.rect.height / 2));

        tileData = new Array<Float>();
        tileData[maxParticles * TILE_DATA_FIELDS - 1] = 0.0;
    }

    private function onEnterFrame(_):Void {
        if (!initialized) {
            return;
        }

        var currentTime = Lib.getTimer();

        if (prevTime < 0) {
            prevTime = currentTime;
            return;
        }

        var dt:Float = (currentTime - prevTime) / 1000.0;
        prevTime = currentTime;

        if (active && emissionRate > 0.0) {
            var rate:Float = 1.0 / emissionRate;
            emitCounter += dt;

            while (particleCount < maxParticles && emitCounter > rate) {
                if (particleCount < maxParticles) {
                    particleList[particleCount].init(this);
                    particleCount++;
                }

                emitCounter -= rate;
            }

            elapsedTime += dt;

            if (duration >= 0.0 && duration < elapsedTime) {
                stop();
            }
        }

        if (particleCount > 0) {
            graphics.clear();
        }

        var index:Int = 0;

        while (index < particleCount) {
            var particle = particleList[index];

            if (particle.update(this, dt)) {
                index++;
            } else {
                if (index != particleCount - 1) {
                    var tmp = particleList[index];
                    particleList[index] = particleList[particleCount - 1];
                    particleList[particleCount - 1] = tmp;
                }

                particleCount--;
            }
        }

        if (particleCount > 0) {
            render();
        } else if (restart) {
            active = true;
        }
    }

    public function emit(sourcePositionX:Null<Float> = null, sourcePositionY:Null<Float> = null):Void {
        if (sourcePositionX != null) {
            sourcePosition.x = sourcePositionX;
        }

        if (sourcePositionY != null) {
            sourcePosition.y = sourcePositionY;
        }

        active = true;
    }

    public function stop():Void {
        active = false;
        elapsedTime = 0.0;
        emitCounter = 0.0;
    }

    public function reset():Void {
        stop();

        for (i in 0 ... particleCount) {
            particleList[i].timeToLive = 0.0;
        }
    }

    private function render():Void {
        var index:Int = 0;
        var ethalonSize:Float = textureBitmapData.width;

        var flags = (blendFuncSource == GL.SRC_ALPHA && blendFuncDestination == GL.ONE
            ? Tilesheet.TILE_BLEND_ADD
            : Tilesheet.TILE_BLEND_NORMAL
        );

        for (i in 0 ... particleCount) {
            var particle = particleList[i];

            tileData[index] = particle.position.x * particleScaleX; // x
            tileData[index + 1] = particle.position.y * particleScaleY; // y
            tileData[index + 2] = 0.0; // tileId
            tileData[index + 3] = particle.particleSize / ethalonSize * particleScaleSize; // scale
            tileData[index + 4] = particle.rotation; // rotation
            tileData[index + 5] = particle.color.r;
            tileData[index + 6] = particle.color.g;
            tileData[index + 7] = particle.color.b;
            tileData[index + 8] = particle.color.a;

            index += TILE_DATA_FIELDS;
        }

        tilesheet.drawTiles(
            graphics,
            tileData,
            true,
            Tilesheet.TILE_SCALE | Tilesheet.TILE_ROTATION | Tilesheet.TILE_RGB | Tilesheet.TILE_ALPHA | flags,
            index
        );

        // removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    public static function createFromFile(path:String):ParticleSystem {
        return createFromXml(Xml.parse(Assets.getText(path)), FileUtils.dirname(path));
    }

    public static function createFromXml(xml:Xml, basePath:String):ParticleSystem {
        var root = xml.firstElement().firstElement();

        if (root.nodeName != "dict") {
            throw new Error('Expecting element "dict", but "${root.nodeName}" found');
        }

        var key:String = null;
        var map:Map<String, Dynamic> = new Map<String, Dynamic>();

        for (node in root.elements()) {
            if (key == null) {
                if (node.nodeName == "key") {
                    key = node.innerText().trim().toLowerCase();

                    if (key == "") {
                        throw new ArgumentError("Empty key is not supported");
                    }

                    continue;
                }

                throw new Error('Expecting element "key", but "${node.nodeName}" found');
            }

            var textValue = node.innerText().trim();

            switch (node.nodeName) {
                case "false":
                    map[key] = false;

                case "true":
                    map[key] = true;

                case "real":
                    var value = Std.parseFloat(textValue);

                    if (Math.isNaN(value)) {
                        throw new ArgumentError('Could not parse "${textValue}" as real (for key "${key}")');
                    }

                    map[key] = value;

                case "integer":
                    var value = Std.parseInt(textValue);

                    if (value == null) {
                        throw new ArgumentError('Could not parse "${textValue}" as integer (for key "${key}")');
                    }

                case "string":
                    map[key] = textValue;

                default:
                    throw new Error('Unsupported element "${node.nodeName}"');
            }

            key = null;
        }

        return createFromMap(map, basePath);
    }

    public static function createFromMap(map:Map<String, Dynamic>, basePath:String):ParticleSystem {
        var result = new ParticleSystem();

        result.emitterType = map["emitterType".toLowerCase()].asInt();
        result.maxParticles = map["maxParticles".toLowerCase()].asInt();
        result.positionType = map["positionType".toLowerCase()].asInt();
        result.duration = map["duration".toLowerCase()].asFloat();
        result.gravity = asVector(map, "gravity");
        result.particleLifespan = map["particleLifespan".toLowerCase()].asFloat();
        result.particleLifespanVariance = map["particleLifespanVariance".toLowerCase()].asFloat();
        result.speed = map["speed".toLowerCase()].asFloat();
        result.speedVariance = map["speedVariance".toLowerCase()].asFloat();
        result.sourcePosition = asVector(map, "sourcePosition");
        result.sourcePositionVariance = asVector(map, "sourcePositionVariance");
        result.angle = map["angle".toLowerCase()].asFloat() / 180.0 * Math.PI;
        result.angleVariance = map["angleVariance".toLowerCase()].asFloat() / 180.0 * Math.PI;
        result.startParticleSize = map["startParticleSize".toLowerCase()].asFloat();
        result.startParticleSizeVariance = map["startParticleSizeVariance".toLowerCase()].asFloat();
        result.finishParticleSize = map["finishParticleSize".toLowerCase()].asFloat();
        result.finishParticleSizeVariance = map["finishParticleSizeVariance".toLowerCase()].asFloat();
        result.startColor = asColor(map, "startColor");
        result.startColorVariance = asColor(map, "startColorVariance");
        result.finishColor = asColor(map, "finishColor");
        result.finishColorVariance = asColor(map, "finishColorVariance");
        result.minRadius = map["minRadius".toLowerCase()].asFloat();
        result.minRadiusVariance = map["minRadiusVariance".toLowerCase()].asFloat();
        result.maxRadius = map["maxRadius".toLowerCase()].asFloat();
        result.maxRadiusVariance = map["maxRadiusVariance".toLowerCase()].asFloat();
        result.rotationStart = map["rotationStart".toLowerCase()].asFloat();
        result.rotationStartVariance = map["rotationStartVariance".toLowerCase()].asFloat();
        result.rotationEnd = map["rotationEnd".toLowerCase()].asFloat();
        result.rotationEndVariance = map["rotationEndVariance".toLowerCase()].asFloat();
        result.rotatePerSecond = map["rotatePerSecond".toLowerCase()].asFloat() / 180.0 * Math.PI;
        result.rotatePerSecondVariance = map["rotatePerSecondVariance".toLowerCase()].asFloat() / 180.0 * Math.PI;
        result.radialAcceleration = map["radialAcceleration".toLowerCase()].asFloat();
        result.radialAccelerationVariance = map["radialAccelVariance".toLowerCase()].asFloat();
        result.tangentialAcceleration = map["tangentialAcceleration".toLowerCase()].asFloat();
        result.tangentialAccelerationVariance = map["tangentialAccelVariance".toLowerCase()].asFloat();
        result.blendFuncSource = map["blendFuncSource".toLowerCase()].asInt();
        result.blendFuncDestination = map["blendFuncDestination".toLowerCase()].asInt();
        result.textureBitmapData = Assets.getBitmapData(basePath + "/" + map["textureFileName".toLowerCase()].asString());

        result.initialize();
        return result;
    }

    private static function asVector(map:Map<String, Dynamic>, prefix:String):ParticleVector {
        return {
            x: map['${prefix}x'.toLowerCase()].asFloat(),
            y: map['${prefix}y'.toLowerCase()].asFloat(),
        };
    }

    private static function asColor(map:Map<String, Dynamic>, prefix:String):ParticleColor {
        return {
            r: map['${prefix}Red'.toLowerCase()].asFloat(),
            g: map['${prefix}Green'.toLowerCase()].asFloat(),
            b: map['${prefix}Blue'.toLowerCase()].asFloat(),
            a: map['${prefix}Alpha'.toLowerCase()].asFloat(),
        };
    }
}
