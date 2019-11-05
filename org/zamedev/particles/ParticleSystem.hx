package org.zamedev.particles;

import haxe.Timer;
import lime.graphics.opengl.GL;
import openfl.display.BitmapData;
import org.zamedev.particles.util.MathHelper;
import org.zamedev.particles.util.ParticleColor;
import org.zamedev.particles.util.ParticleVector;

class ParticleSystem {
    public static inline var EMITTER_TYPE_GRAVITY : Int = 0;
    public static inline var EMITTER_TYPE_RADIAL : Int = 1;

    public static inline var POSITION_TYPE_FREE : Int = 0;
    public static inline var POSITION_TYPE_RELATIVE : Int = 1;
    public static inline var POSITION_TYPE_GROUPED : Int = 2;

    public var colorChangeDelay : Float = 0.0;
    public var emitterType : Int = 0;
    public var maxParticles : Int = 0;
    public var positionType : Int = 0;
    public var duration : Float = 0.0;
    public var gravity : ParticleVector = new ParticleVector(0.0, 0.0);
    public var particleLifespan : Float = 0.0;
    public var particleLifespanVariance : Float = 0.0;
    public var speed : Float = 0.0;
    public var speedVariance : Float = 0.0;
    public var sourcePosition : ParticleVector = new ParticleVector(0.0, 0.0);
    public var sourcePositionVariance : ParticleVector = new ParticleVector(0.0, 0.0);
    public var angle : Float = 0.0;
    public var angleVariance : Float = 0.0;
    public var startParticleSize : Float = 0.0;
    public var startParticleSizeVariance : Float = 0.0;
    public var finishParticleSize : Float = 0.0;
    public var finishParticleSizeVariance : Float = 0.0;
    public var startColor : ParticleColor = new ParticleColor(0.0, 0.0, 0.0, 0.0);
    public var startColorVariance : ParticleColor = new ParticleColor(0.0, 0.0, 0.0, 0.0);
    public var finishColor : ParticleColor = new ParticleColor(0.0, 0.0, 0.0, 0.0);
    public var finishColorVariance : ParticleColor = new ParticleColor(0.0, 0.0, 0.0, 0.0);
    public var minRadius : Float = 0.0;
    public var minRadiusVariance : Float = 0.0;
    public var maxRadius : Float = 0.0;
    public var maxRadiusVariance : Float = 0.0;
    public var rotationStart : Float = 0.0;
    public var rotationStartVariance : Float = 0.0;
    public var rotationEnd : Float = 0.0;
    public var rotationEndVariance : Float = 0.0;
    public var radialAcceleration : Float = 0.0;
    public var radialAccelerationVariance : Float = 0.0;
    public var tangentialAcceleration : Float = 0.0;
    public var tangentialAccelerationVariance : Float = 0.0;
    public var rotatePerSecond : Float = 0.0;
    public var rotatePerSecondVariance : Float = 0.0;
    public var blendFuncSource : Int = 0;
    public var blendFuncDestination : Int = 0;
    public var textureBitmapData : Null<BitmapData> = null;
    public var active : Bool = false;
    public var restart : Bool = false;
    public var particleScaleX : Float = 1.0;
    public var particleScaleY : Float = 1.0;
    public var particleScaleSize : Float = 1.0;
    public var yCoordMultiplier : Float = 1.0;
    public var headToVelocity : Bool = false;
    public var emissionFreq : Float = 0.0;
    public var forceSquareTexture : Bool = false;

    private var prevTime : Float = -1.0;
    private var emitCounter : Float = 0.0;
    private var elapsedTime : Float = 0.0;

    public var __particleList : Array<Particle> = [];
    public var __particleCount : Int = 0;

    public function new() {
    }

    public function __initialize() : ParticleSystem {
        if (blendFuncSource == GL.DST_ALPHA) {
            blendFuncSource = GL.ONE;
        }

        if (blendFuncDestination == GL.DST_ALPHA) {
            blendFuncDestination = GL.ONE;
        }

        prevTime = -1.0;
        emitCounter = 0.0;
        elapsedTime = 0.0;

        if (emissionFreq <= 0.0) {
            var emissionRate : Float = maxParticles / Math.max(0.0001, particleLifespan);

            if (emissionRate > 0.0) {
                emissionFreq = 1.0 / emissionRate;
            }
        }

        __particleList = [];
        __particleCount = 0;

        for (i in 0 ... maxParticles) {
            __particleList[i] = new Particle();
        }

        return this;
    }

    public function __update() : Bool {
        var currentTime = Timer.stamp();

        if (prevTime < 0.0) {
            prevTime = currentTime;
            return false;
        }

        var dt = currentTime - prevTime;

        if (dt < 0.0001) {
            return false;
        }

        prevTime = currentTime;

        if (active && emissionFreq > 0.0) {
            emitCounter += dt;

            while (__particleCount < maxParticles && emitCounter > emissionFreq) {
                initParticle(__particleList[__particleCount]);
                __particleCount++;
                emitCounter -= emissionFreq;
            }

            if (emitCounter > emissionFreq) {
                emitCounter = (emitCounter % emissionFreq);
            }

            elapsedTime += dt;

            if (duration >= 0.0 && duration < elapsedTime) {
                stop();
            }
        }

        var updated = false;

        if (__particleCount > 0) {
            updated = true;
        }

        var index = 0;

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

    private function initParticle(p : Particle) : Void {
        // Common
        p.timeToLive = Math.max(0.0001, particleLifespan + particleLifespanVariance * MathHelper.rnd1to1());
        p.colorChangeDelay = colorChangeDelay;

        p.startPos.x = sourcePosition.x / particleScaleX;
        p.startPos.y = sourcePosition.y / particleScaleY;

        p.color.r = MathHelper.clamp(startColor.r + startColorVariance.r * MathHelper.rnd1to1());
        p.color.g = MathHelper.clamp(startColor.g + startColorVariance.g * MathHelper.rnd1to1());
        p.color.b = MathHelper.clamp(startColor.b + startColorVariance.b * MathHelper.rnd1to1());
        p.color.a = MathHelper.clamp(startColor.a + startColorVariance.a * MathHelper.rnd1to1());

        p.colorDelta.r = (
            MathHelper.clamp(finishColor.r + finishColorVariance.r * MathHelper.rnd1to1()) - p.color.r
        ) / (p.timeToLive - colorChangeDelay);

        p.colorDelta.g = (
            MathHelper.clamp(finishColor.g + finishColorVariance.g * MathHelper.rnd1to1()) - p.color.g
        ) / (p.timeToLive - colorChangeDelay);

        p.colorDelta.b = (
            MathHelper.clamp(finishColor.b + finishColorVariance.b * MathHelper.rnd1to1()) - p.color.b
        ) / (p.timeToLive - colorChangeDelay);

        p.colorDelta.a = (
            MathHelper.clamp(finishColor.a + finishColorVariance.a * MathHelper.rnd1to1()) - p.color.a
        ) / (p.timeToLive - colorChangeDelay);

        p.particleSize = Math.max(0.0, startParticleSize + startParticleSizeVariance * MathHelper.rnd1to1());

        p.particleSizeDelta = (Math.max(
            0.0,
            finishParticleSize + finishParticleSizeVariance * MathHelper.rnd1to1()) - p.particleSize
        ) / p.timeToLive;

        p.rotation = rotationStart + rotationStartVariance * MathHelper.rnd1to1();
        p.rotationDelta = (rotationEnd + rotationEndVariance * MathHelper.rnd1to1() - p.rotation) / p.timeToLive;

        var computedAngle = angle + angleVariance * MathHelper.rnd1to1();

        // For gravity emitter type
        var directionSpeed = speed + speedVariance * MathHelper.rnd1to1();

        p.position.x = p.startPos.x + sourcePositionVariance.x * MathHelper.rnd1to1();
        p.position.y = p.startPos.y + sourcePositionVariance.y * MathHelper.rnd1to1();
        p.direction.x = Math.cos(computedAngle) * directionSpeed;
        p.direction.y = Math.sin(computedAngle) * directionSpeed;
        p.radialAcceleration = radialAcceleration + radialAccelerationVariance * MathHelper.rnd1to1();
        p.tangentialAcceleration = tangentialAcceleration + tangentialAccelerationVariance * MathHelper.rnd1to1();

        // For radial emitter type
        p.angle = computedAngle;
        p.angleDelta = (rotatePerSecond + rotatePerSecondVariance * MathHelper.rnd1to1()) / p.timeToLive;
        p.radius = maxRadius + maxRadiusVariance * MathHelper.rnd1to1();
        p.radiusDelta = (minRadius + minRadiusVariance * MathHelper.rnd1to1() - p.radius) / p.timeToLive;
    }

    public function emit(?sourcePositionX : Null<Float>, ?sourcePositionY : Null<Float>) : Void {
        if (sourcePositionX != null) {
            sourcePosition.x = sourcePositionX;
        }

        if (sourcePositionY != null) {
            sourcePosition.y = sourcePositionY;
        }

        active = true;
    }

    public function stop() : Void {
        active = false;
        elapsedTime = 0.0;
        emitCounter = 0.0;
    }

    public function reset() : Void {
        stop();

        for (i in 0 ... __particleCount) {
            __particleList[i].timeToLive = 0.0;
        }
    }
}
