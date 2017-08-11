package org.zamedev.particles;

import haxe.Timer;
import openfl.display.BitmapData;
import org.zamedev.particles.util.MathHelper;
import org.zamedev.particles.util.ParticleColor;
import org.zamedev.particles.util.ParticleVector;

#if (openfl < "5.1.0")
    import openfl.gl.GL;
#else
    import lime.graphics.opengl.GL;
#end

class ParticleSystem {
    public static inline var EMITTER_TYPE_GRAVITY : Int = 0;
    public static inline var EMITTER_TYPE_RADIAL : Int = 1;

    public static inline var POSITION_TYPE_FREE : Int = 0;
    public static inline var POSITION_TYPE_RELATIVE : Int = 1;
    public static inline var POSITION_TYPE_GROUPED : Int = 2;

    public var emitterType : Int;
    public var maxParticles : Int;
    public var positionType : Int;
    public var duration : Float;
    public var gravity : ParticleVector;
    public var particleLifespan : Float;
    public var particleLifespanVariance : Float;
    public var speed : Float;
    public var speedVariance : Float;
    public var sourcePosition : ParticleVector;
    public var sourcePositionVariance : ParticleVector;
    public var angle : Float;
    public var angleVariance : Float;
    public var startParticleSize : Float;
    public var startParticleSizeVariance : Float;
    public var finishParticleSize : Float;
    public var finishParticleSizeVariance : Float;
    public var startColor : ParticleColor;
    public var startColorVariance : ParticleColor;
    public var finishColor : ParticleColor;
    public var finishColorVariance : ParticleColor;
    public var minRadius : Float;
    public var minRadiusVariance : Float;
    public var maxRadius : Float;
    public var maxRadiusVariance : Float;
    public var rotationStart : Float;
    public var rotationStartVariance : Float;
    public var rotationEnd : Float;
    public var rotationEndVariance : Float;
    public var radialAcceleration : Float;
    public var radialAccelerationVariance : Float;
    public var tangentialAcceleration : Float;
    public var tangentialAccelerationVariance : Float;
    public var rotatePerSecond : Float;
    public var rotatePerSecondVariance : Float;
    public var blendFuncSource : Int;
    public var blendFuncDestination : Int;
    public var textureBitmapData : BitmapData;
    public var active : Bool;
    public var restart : Bool;
    public var particleScaleX : Float;
    public var particleScaleY : Float;
    public var particleScaleSize : Float;
    public var yCoordMultiplier : Float;
    public var emissionFreq : Float;
    public var forceSquareTexture : Bool;

    private var prevTime : Float;
    private var emitCounter : Float;
    private var elapsedTime : Float;

    public var __particleList : Array<Particle>;
    public var __particleCount : Int;

    public function new() : Void {
        active = false;
        restart = false;
        particleScaleX = 1.0;
        particleScaleY = 1.0;
        particleScaleSize = 1.0;
        emissionFreq = 0.0;
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

        __particleList = new Array<Particle>();
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

        p.startPos.x = sourcePosition.x / particleScaleX;
        p.startPos.y = sourcePosition.y / particleScaleY;

        p.color = {
            r: MathHelper.clamp(startColor.r + startColorVariance.r * MathHelper.rnd1to1()),
            g: MathHelper.clamp(startColor.g + startColorVariance.g * MathHelper.rnd1to1()),
            b: MathHelper.clamp(startColor.b + startColorVariance.b * MathHelper.rnd1to1()),
            a: MathHelper.clamp(startColor.a + startColorVariance.a * MathHelper.rnd1to1()),
        };

        p.colorDelta = {
            r: (MathHelper.clamp(finishColor.r + finishColorVariance.r * MathHelper.rnd1to1()) - p.color.r) / p.timeToLive,
            g: (MathHelper.clamp(finishColor.g + finishColorVariance.g * MathHelper.rnd1to1()) - p.color.g) / p.timeToLive,
            b: (MathHelper.clamp(finishColor.b + finishColorVariance.b * MathHelper.rnd1to1()) - p.color.b) / p.timeToLive,
            a: (MathHelper.clamp(finishColor.a + finishColorVariance.a * MathHelper.rnd1to1()) - p.color.a) / p.timeToLive,
        };

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
