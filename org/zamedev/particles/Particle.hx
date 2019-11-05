package org.zamedev.particles;

import org.zamedev.particles.util.MathHelper;
import org.zamedev.particles.util.ParticleColor;
import org.zamedev.particles.util.ParticleVector;

class Particle {
    public var startPos : ParticleVector = new ParticleVector(0.0, 0.0);
    public var position : ParticleVector = new ParticleVector(0.0, 0.0);
    public var prevPosition : ParticleVector = new ParticleVector(0.0, 0.0);
    public var direction : ParticleVector = new ParticleVector(0.0, 0.0);
    public var color : ParticleColor = new ParticleColor(0.0, 0.0, 0.0, 0.0);
    public var colorDelta : ParticleColor = new ParticleColor(0.0, 0.0, 0.0, 0.0);
    public var rotation : Float = 0.0;
    public var rotationDelta : Float = 0.0;
    public var radius : Float = 0.0;
    public var radiusDelta : Float = 0.0;
    public var angle : Float = 0.0;
    public var angleDelta : Float = 0.0;
    public var particleSize : Float = 0.0;
    public var particleSizeDelta : Float = 0.0;
    public var radialAcceleration : Float = 0.0;
    public var tangentialAcceleration : Float = 0.0;
    public var timeToLive : Float = 0.0;
    public var colorChangeDelay : Float = 0.0;
    private var timePassed : Float = 0.0;

    public function new() {
    }

    public function update(ps : ParticleSystem, dt : Float) : Bool {
        timeToLive -= dt;
        timePassed += dt;

        if (timeToLive <= 0.0) {
            timePassed = 0.0;
            return false;
        }

        prevPosition.x = position.x;
        prevPosition.y = position.y;

        if (ps.emitterType == ParticleSystem.EMITTER_TYPE_RADIAL) {
            angle += angleDelta * dt;
            radius += radiusDelta * dt;

            position.x = startPos.x - Math.cos(angle) * radius;
            position.y = startPos.y - Math.sin(angle) * radius * ps.yCoordMultiplier;
        } else {
            var radial = { x: 0.0, y: 0.0 };

            position.x -= startPos.x;
            position.y = (position.y - startPos.y) * ps.yCoordMultiplier;

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
            position.y = (position.y + direction.y * dt) * ps.yCoordMultiplier + startPos.y;
        }

        if (timePassed >= colorChangeDelay) {
            color.r += colorDelta.r * dt;
            color.g += colorDelta.g * dt;
            color.b += colorDelta.b * dt;
            color.a += colorDelta.a * dt;
        }

        particleSize += particleSizeDelta * dt;
        particleSize = Math.max(0, particleSize);

        if (ps.headToVelocity) {
            var vx = position.x - prevPosition.x;
            var vy = position.y - prevPosition.y;

            if (Math.abs(vx) > MathHelper.EPSILON || Math.abs(vy) > MathHelper.EPSILON) {
                rotation = Math.atan2(vy, vx);
            } else {
                rotation = Math.atan2(direction.y, direction.x);
            }
        } else {
            rotation += rotationDelta * dt;
        }

        return true;
    }
}
