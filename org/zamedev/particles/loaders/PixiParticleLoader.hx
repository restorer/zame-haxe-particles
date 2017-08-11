package org.zamedev.particles.loaders;

import haxe.Json;
import openfl.Assets;
import openfl.errors.Error;
import org.zamedev.particles.ParticleSystem;
import org.zamedev.particles.util.DynamicExt;
import org.zamedev.particles.util.MathHelper;
import org.zamedev.particles.util.ParticleColor;
import org.zamedev.particles.util.ParticleVector;

#if (openfl < "5.1.0")
    import openfl.gl.GL;
#else
    import lime.graphics.opengl.GL;
#end

using org.zamedev.particles.util.DynamicTools;

class PixiParticleLoader {
    private static inline var BLEND_MODE_NORMAL : String = "normal";
    private static inline var BLEND_MODE_ADD : String = "add";
    private static inline var BLEND_MODE_MULTIPLY : String = "multiply";

    public static function load(path : String, texturePath : String) : ParticleSystem {
        var map : DynamicExt = Json.parse(Assets.getText(path));
        var ps = new ParticleSystem();

        ps.textureBitmapData = ParticleLoader.loadTexture(null, texturePath, path);

        if (ps.textureBitmapData == null) {
            throw new Error('Expecting valid texture');
        }

        var scaleMap = map["scale"].asDynamic();

        // Assumes texture is rectangular!
        var startSize = scaleMap["start"].asFloat() * ps.textureBitmapData.width;
        var endSize = scaleMap["end"].asFloat() * ps.textureBitmapData.width;

        ps.startParticleSize = startSize;
        ps.startParticleSizeVariance = 0.0;

        ps.finishParticleSize = endSize;
        ps.finishParticleSizeVariance = 0.0;

        // TODO: There is not a good mapping between the spawn and emitter types, so assume radial for now
        // var spawnType = map["spawnType"].asString();
        ps.emitterType = ParticleSystem.EMITTER_TYPE_RADIAL;

        ps.maxParticles = map["maxParticles"].asInt();
        ps.positionType = 0;
        ps.duration = map["emitterLifetime"].asFloat();
        ps.emissionFreq = map["frequency"].asFloat();

        var lifeMap = map["lifetime"].asDynamic();
        var lifeMin = lifeMap["min"].asFloat();
        var lifeMax = lifeMap["max"].asFloat();
        var averageLife = (lifeMin + lifeMax) * 0.5;

        ps.particleLifespan = (lifeMin + lifeMax) * 0.5;
        ps.particleLifespanVariance = (lifeMax - lifeMin) * 0.5;

        var speedMap = map["speed"].asDynamic();
        var speedMin = speedMap["min"].asFloat();
        var speedMax = speedMap["max"].asFloat();

        // Only applies to gravity emitters (not radial)
        ps.speed = (speedMin + speedMax) * 0.5;
        ps.speedVariance = (speedMax - speedMin) * 0.5;

        ps.gravity = asVector(map, "gravity");
        ps.sourcePosition = { x: 0.0, y: 0.0 };
        ps.sourcePositionVariance = asVector(map, "sourcePositionVariance");

        var startRot = map["startRotation"].asDynamic();
        var startRotMin = startRot["min"].asFloat() + 180.0;
        var startRotMax = startRot["max"].asFloat() + 180.0;

        ps.angle = MathHelper.deg2rad((startRotMin + startRotMax) * 0.5);
        ps.angleVariance = MathHelper.deg2rad((startRotMax - startRotMin) * 0.5);

        // TODO: color animation not supported in html5
        ps.startColor = asColor(map, "color", "start");
        ps.startColorVariance = { r: 0.0, g: 0.0, b: 0.0, a: 0.0 };

        ps.finishColor = asColor(map, "color", "end");
        ps.finishColorVariance = { r: 0.0, g: 0.0, b: 0.0, a: 0.0 };

        var alpha = map["alpha"].asDynamic();
        ps.startColor.a = alpha["start"].asFloat();
        ps.finishColor.a = alpha["end"].asFloat();

        // Pixi uses start, end speed, while pex uses a min and max radius for the radial emitter
        var startSpeed = speedMap["start"].asFloat();
        var endSpeed = speedMap["end"].asFloat();
        var averageSpeed = (startSpeed + endSpeed) * 0.5;

        var minDist = averageSpeed * lifeMin;
        var maxDist = averageSpeed * lifeMax;
        var averageDist = averageSpeed * averageLife;

        ps.minRadius = averageDist;
        ps.minRadiusVariance = (maxDist - minDist) * 0.5;

        ps.maxRadius = 0.0;
        ps.maxRadiusVariance = 0.0;

        var rotSpeedMap = map["rotationSpeed"];
        var rotSpeedMin = rotSpeedMap["min"].asFloat();
        var rotSpeedMax = rotSpeedMap["max"].asFloat();

        // TODO: rotationStart and rotationStartVariance currently equal to angle and angleVariance, is it right?
        ps.rotationStart = MathHelper.deg2rad((startRotMin + startRotMax) * 0.5);
        ps.rotationStartVariance = MathHelper.deg2rad((startRotMax - startRotMin) * 0.5);

        var rotMin = rotSpeedMin * averageLife;
        var rotMax = rotSpeedMax * averageLife;

        ps.rotationEnd = ps.rotationStart + MathHelper.deg2rad((rotMin + rotMax) * 0.5);
        ps.rotationEndVariance = MathHelper.deg2rad((rotMax - rotMin) * 0.5);

        // This rotates the emitter itself, which is not supported by pixi
        ps.rotatePerSecond = 0.0;
        ps.rotatePerSecondVariance = 0.0;

        switch (map["blendMode"].asString()) {
            case BLEND_MODE_NORMAL:
                ps.blendFuncSource = GL.SRC_ALPHA;
                ps.blendFuncDestination = GL.ONE_MINUS_SRC_ALPHA;

            case BLEND_MODE_ADD:
                ps.blendFuncSource = GL.ONE;
                ps.blendFuncDestination = GL.ONE;

            case BLEND_MODE_MULTIPLY:
                ps.blendFuncSource = GL.DST_COLOR;
                ps.blendFuncDestination = GL.ONE_MINUS_SRC_ALPHA;

            default:
                ps.blendFuncSource =  GL.SRC_ALPHA;
                ps.blendFuncDestination = GL.ONE_MINUS_SRC_ALPHA;
        }

        ps.yCoordMultiplier = (map["yCoordFlipped"].asInt() == 1 ? -1.0 : 1.0);

        ps.radialAcceleration = 0.0;
        ps.radialAccelerationVariance = 0.0;
        ps.tangentialAcceleration = 0.0;
        ps.tangentialAccelerationVariance = 0.0;

        ps.forceSquareTexture = false;

        return ps;
    }

    private static function asVector(map : DynamicExt, prefix : String) : ParticleVector {
        return {
            x: map['${prefix}x'].asFloat(),
            y: map['${prefix}y'].asFloat(),
        };
    }

    private static function asColor(map : DynamicExt, param : String, subParam : String) : ParticleColor {
        if (!map.exists(param)) {
            return {
                r: 0.0,
                g: 0.0,
                b: 0.0,
                a: 1.0,
            };
        }

        var str = map[param].asDynamic()[subParam].asString();
        var val = Std.parseInt(StringTools.replace(str, "#", "0x"));

        return {
            r: ((val >> 16) & 0xff) / 255.0,
            g: ((val >> 8) & 0xff) / 255.0,
            b: (val & 0xff) / 255.0,
            a: 1.0,
        };
    }
}
