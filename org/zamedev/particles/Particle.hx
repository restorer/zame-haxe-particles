package org.zamedev.particles;

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

    public function update(ps:ParticleSystem, dt:Float):Bool {
        timeToLive -= dt;

        if (timeToLive <= 0.0) {
            return false;
        }

        if (ps.emitterType == ParticleSystem.EMITTER_TYPE_RADIAL) {
            angle += angleDelta * dt;
            radius += radiusDelta * dt;

            position.x = ps.sourcePosition.x - Math.cos(angle) * radius;
            position.y = ps.sourcePosition.y - Math.sin(angle) * radius * ps.yCoordMultiplier;
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
            position.y += direction.y * dt * ps.yCoordMultiplier + startPos.y;
        }

        color.r += colorDelta.r * dt;
        color.g += colorDelta.g * dt;
        color.b += colorDelta.b * dt;
        color.a += colorDelta.a * dt;

        particleSize += particleSizeDelta * dt;
        rotation += rotationDelta * dt;

        return true;
    }
}
