package org.zamedev.particles;

import openfl.Lib;
import openfl.display.BitmapData;
import openfl.gl.GL;
import org.zamedev.particles.util.ParticleColor;
import org.zamedev.particles.util.ParticleVector;

class ParticleSystem {
    public static inline var EMITTER_TYPE_GRAVITY:Int = 0;
    public static inline var EMITTER_TYPE_RADIAL:Int = 1;

    public static inline var POSITION_TYPE_FREE:Int = 0;
    public static inline var POSITION_TYPE_RELATIVE:Int = 1;
    public static inline var POSITION_TYPE_GROUPED:Int = 2;

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
    public var blendFuncSource:Int;
    public var blendFuncDestination:Int;
    public var textureBitmapData:BitmapData;
    public var active:Bool;
    public var restart:Bool;
    public var particleScaleX:Float;
    public var particleScaleY:Float;
    public var particleScaleSize:Float;
    public var yCoordMultiplier:Float;

    private var prevTime:Int;
    private var emissionRate:Float;
    private var emitCounter:Float;
    private var elapsedTime:Float;

    public var __particleList:Array<Particle>;
    public var __particleCount:Int;

    public function new() {
        active = false;
        restart = false;
        particleScaleX = 1.0;
        particleScaleY = 1.0;
        particleScaleSize = 1.0;
    }

    public function __initialize():ParticleSystem {
        if (blendFuncSource == GL.DST_ALPHA) {
            blendFuncSource = GL.ONE;
        }

        if (blendFuncDestination == GL.DST_ALPHA) {
            blendFuncDestination = GL.ONE;
        }

        prevTime = -1;
        emissionRate = maxParticles / particleLifespan;
        emitCounter = 0.0;
        elapsedTime = 0.0;

        __particleList = new Array<Particle>();
        __particleCount = 0;

        for (i in 0 ... maxParticles) {
            __particleList[i] = new Particle();
        }

        return this;
    }

    public function __update():Bool {
        var currentTime = Lib.getTimer();

        if (prevTime < 0) {
            prevTime = currentTime;
            return false;
        }

        var dt:Float = (currentTime - prevTime) / 1000.0;

        if (dt < 0.0001) {
            return false;
        }

        prevTime = currentTime;

        if (active && emissionRate > 0.0) {
            var rate:Float = 1.0 / emissionRate;
            emitCounter += dt;

            while (__particleCount < maxParticles && emitCounter > rate) {
                initParticle(__particleList[__particleCount]);
                __particleCount++;
                emitCounter -= rate;
            }

            elapsedTime += dt;

            if (duration >= 0.0 && duration < elapsedTime) {
                stop();
            }
        }

        var updated:Bool = false;

        if (__particleCount > 0) {
            updated = true;
        }

        var index:Int = 0;

        while (index < __particleCount) {
            var particle = __particleList[index];

            if (particle.update(this, dt)) {
                index++;
            } else {
                if (index != __particleCount - 1) {
                    var tmp = __particleList[index];
                    __particleList[index] = __particleList[__particleCount - 1];
                    __particleList[__particleCount - 1] = tmp;
                }

                __particleCount--;
            }
        }

        if (__particleCount > 0) {
            updated = true;
        } else if (restart) {
            active = true;
        }

        return updated;
    }

    private function initParticle(p:Particle):Void {
        // Common
        p.timeToLive = Math.max(0.0001, particleLifespan + particleLifespanVariance * rnd());

        p.startPos.x = sourcePosition.x / particleScaleX;
        p.startPos.y = sourcePosition.y / particleScaleY;

        p.color = {
            r: clamp(startColor.r + startColorVariance.r * rnd()),
            g: clamp(startColor.g + startColorVariance.g * rnd()),
            b: clamp(startColor.b + startColorVariance.b * rnd()),
            a: clamp(startColor.a + startColorVariance.a * rnd()),
        };

        p.colorDelta = {
            r: (clamp(finishColor.r + finishColorVariance.r * rnd()) - p.color.r) / p.timeToLive,
            g: (clamp(finishColor.g + finishColorVariance.g * rnd()) - p.color.g) / p.timeToLive,
            b: (clamp(finishColor.b + finishColorVariance.b * rnd()) - p.color.b) / p.timeToLive,
            a: (clamp(finishColor.a + finishColorVariance.a * rnd()) - p.color.a) / p.timeToLive,
        };

        p.particleSize = Math.max(0.0, startParticleSize + startParticleSizeVariance * rnd());
        p.particleSizeDelta = (Math.max(0.0, finishParticleSize + finishParticleSizeVariance * rnd()) - p.particleSize) / p.timeToLive;
        p.rotation = rotationStart + rotationStartVariance * rnd();
        p.rotationDelta = (rotationEnd + rotationEndVariance * rnd() - p.rotation) / p.timeToLive;

        var computedAngle = angle + angleVariance * rnd();

        // For gravity emitter type
        var directionSpeed = speed + speedVariance * rnd();

        p.position.x = p.startPos.x + sourcePositionVariance.x * rnd();
        p.position.y = p.startPos.y + sourcePositionVariance.y * rnd();
        p.direction.x = Math.cos(computedAngle) * directionSpeed;
        p.direction.y = Math.sin(computedAngle) * directionSpeed;
        p.radialAcceleration = radialAcceleration + radialAccelerationVariance * rnd();
        p.tangentialAcceleration = tangentialAcceleration + tangentialAccelerationVariance * rnd();

        // For radial emitter type
        p.angle = computedAngle;
        p.angleDelta = (rotatePerSecond + rotatePerSecondVariance * rnd()) / p.timeToLive;
        p.radius = maxRadius + maxRadiusVariance * rnd();
        p.radiusDelta = (minRadius + minRadiusVariance * rnd() - p.radius) / p.timeToLive;
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

        for (i in 0 ... __particleCount) {
            __particleList[i].timeToLive = 0.0;
        }
    }

    private inline static function rnd():Float {
        return Math.random() * 2.0 - 1.0;
    }

    private static function clamp(value:Float):Float {
        return (value < 0.0 ? 0.0 : (value < 1.0 ? value : 1.0));
    }
}
