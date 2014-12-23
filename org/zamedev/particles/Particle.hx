package org.zamedev.particles;

import openfl.Assets;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import org.zamedev.lib.FileUtils;

using StringTools;
using org.zamedev.lib.DynamicTools;
using org.zamedev.lib.XmlExt;

class Particle {
    public var startPos:ParticleVector;
    public var position:ParticleVector;
    public var direction:ParticleVector;
    public var color:ParticleColor;
    public var colorDelta:ParticleColor;
    public var rotation:Float;
    public var rotationDelta:Float;
    public var radius:Float;
    public var radiusDelta:Float;
    public var angle:Float;
    public var angleDelta:Float;
    public var particleSize:Float;
    public var particleSizeDelta:Float;
    public var radialAcceleration:Float;
    public var tangentialAcceleration:Float;
    public var timeToLive:Float;

    public function new() {
        position = { x: 0.0, y: 0.0 };
        direction = { x: 0.0, y: 0.0 };
        startPos = { x: 0.0, y: 0.0 };
        color = { r: 0.0, g: 0.0, b: 0.0, a: 0.0 };
        colorDelta = { r: 0.0, g: 0.0, b: 0.0, a: 0.0 };
    }

    public function init(ps:ParticleSystem):Void {
        timeToLive = Math.max(0.0001, ps.particleLifespan + ps.particleLifespanVariance * rnd());

        var directionAngle = ps.angle + ps.angleVariance * rnd();
        var directionSpeed = ps.speed + ps.speedVariance * rnd();

        startPos.x = ps.sourcePosition.x / ps.particleScaleX;
        startPos.y = ps.sourcePosition.y / ps.particleScaleY;
        position.x = startPos.x + ps.sourcePositionVariance.x * rnd();
        position.y = startPos.y + ps.sourcePositionVariance.y * rnd();
        direction.x = Math.cos(directionAngle) * directionSpeed;
        direction.y = Math.sin(directionAngle) * directionSpeed;
        radius = ps.maxRadius + ps.maxRadiusVariance * rnd();
        radiusDelta = (ps.minRadius + ps.minRadiusVariance * rnd() - radius) / timeToLive;
        angle = ps.angle + ps.angleVariance * rnd();
        angleDelta = ps.rotatePerSecond + ps.rotatePerSecondVariance * rnd();
        radialAcceleration = ps.radialAcceleration;
        particleSize = Math.max(0.0, ps.startParticleSize + ps.startParticleSizeVariance * rnd());
        particleSizeDelta = (Math.max(0.0, ps.startParticleSize + ps.startParticleSizeVariance * rnd()) - particleSize) / timeToLive;
        rotation = ps.rotationStart + ps.rotationStartVariance * rnd();
        rotationDelta = (ps.rotationEnd + ps.rotationEndVariance * rnd() - rotation) / timeToLive;
        radialAcceleration = ps.radialAcceleration + ps.radialAccelerationVariance * rnd();
        tangentialAcceleration = ps.tangentialAcceleration + ps.tangentialAccelerationVariance * rnd();

        color = {
            r: clamp(ps.startColor.r + ps.startColorVariance.r * rnd()),
            g: clamp(ps.startColor.g + ps.startColorVariance.g * rnd()),
            b: clamp(ps.startColor.b + ps.startColorVariance.b * rnd()),
            a: clamp(ps.startColor.a + ps.startColorVariance.a * rnd()),
        };

        colorDelta = {
            r: (clamp(ps.finishColor.r + ps.finishColorVariance.r * rnd()) - color.r) / timeToLive,
            g: (clamp(ps.finishColor.g + ps.finishColorVariance.g * rnd()) - color.g) / timeToLive,
            b: (clamp(ps.finishColor.b + ps.finishColorVariance.b * rnd()) - color.b) / timeToLive,
            a: (clamp(ps.finishColor.a + ps.finishColorVariance.a * rnd()) - color.a) / timeToLive,
        };
    }

    public function update(ps:ParticleSystem, dt:Float):Bool {
        timeToLive -= dt;

        if (timeToLive <= 0.0) {
            return false;
        }

        if (ps.emitterType == ParticleSystem.EMITTER_TYPE_RADIAL) {
            angle += angleDelta * dt;
            radius += radiusDelta * dt;

            position.x = ps.sourcePosition.x - Math.cos(angle) * radius;
            position.y = ps.sourcePosition.y - Math.sin(angle) * radius;
        } else {
            var radial = { x: 0.0, y: 0.0 };

            position.x -= startPos.x;
            position.y -= startPos.y;

            if (position.x != 0.0 || position.y != 0.0) {
                var length = Math.sqrt(position.x * position.x + position.y * position.y);

                radial.x = position.x / length;
                radial.y = position.y / length;
            }

            var tangential = {
                x: - radial.y,
                y: radial.x,
            };

            radial.x *= radialAcceleration;
            radial.y *= radialAcceleration;

            tangential.x *= tangentialAcceleration;
            tangential.y *= tangentialAcceleration;

            direction.x += (radial.x + tangential.x + ps.gravity.x) * dt;
            direction.y += (radial.y + tangential.y + ps.gravity.y) * dt;

            position.x += direction.x * dt + startPos.x;
            position.y += direction.y * dt + startPos.y;
        }

        color.r += colorDelta.r * dt;
        color.g += colorDelta.g * dt;
        color.b += colorDelta.b * dt;
        color.a += colorDelta.a * dt;

        particleSize += particleSizeDelta * dt;
        rotation += rotationDelta * dt;

        return true;
    }

    private inline static function rnd():Float {
        return Math.random() * 2.0 - 1.0;
    }

    private static function clamp(value:Float):Float {
        return (value < 0.0 ? 0.0 : (value < 1.0 ? value : 1.0));
    }
}
