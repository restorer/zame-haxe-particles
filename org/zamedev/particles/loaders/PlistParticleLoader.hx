package org.zamedev.particles.loaders;

import openfl.Assets;
import openfl.errors.Error;
import org.zamedev.particles.ParticleSystem;
import org.zamedev.particles.util.MathHelper;
import org.zamedev.particles.util.ParticleColor;
import org.zamedev.particles.util.ParticleVector;

using org.zamedev.particles.util.DynamicTools;
using org.zamedev.particles.util.XmlExt;

class PlistParticleLoader {
    public static function load(path : String) : ParticleSystem {
        var root = Xml.parse(Assets.getText(path)).firstElement().firstElement();

        if (root.nodeName != "dict") {
            throw new Error('Expecting "dict", but "${root.nodeName}" found');
        }

        var key : String = null;
        var map : Map<String, Dynamic> = new Map<String, Dynamic>();

        for (node in root.elements()) {
            if (key == null) {
                if (node.nodeName == "key") {
                    key = node.innerText();

                    if (key == "") {
                        throw new Error("Empty key is not supported");
                    }

                    continue;
                }

                throw new Error('Expecting element "key", but "${node.nodeName}" found');
            }

            var textValue = node.innerText();

            switch (node.nodeName) {
                case "false":
                    map[key] = false;

                case "true":
                    map[key] = true;

                case "real":
                    var value = Std.parseFloat(textValue);

                    if (Math.isNaN(value)) {
                        throw new Error('Could not parse "${textValue}" as real (for key "${key}")');
                    }

                    map[key] = value;

                case "integer":
                    var value = Std.parseInt(textValue);

                    if (value == null) {
                        throw new Error('Could not parse "${textValue}" as integer (for key "${key}")');
                    }

                    map[key] = value;

                case "string":
                    map[key] = textValue;

                default:
                    throw new Error('Unsupported element "${node.nodeName}"');
            }

            key = null;
        }

        var ps = new ParticleSystem();

        ps.emitterType = map["emitterType"].asInt();
        ps.maxParticles = map["maxParticles"].asInt();
        ps.positionType = map["positionType"].asInt();
        ps.duration = map["duration"].asFloat();
        ps.gravity = asVector(map, "gravity");
        ps.particleLifespan = map["particleLifespan"].asFloat();
        ps.particleLifespanVariance = map["particleLifespanVariance"].asFloat();
        ps.speed = map["speed"].asFloat();
        ps.speedVariance = map["speedVariance"].asFloat();
        ps.sourcePosition = asVector(map, "sourcePosition");
        ps.sourcePositionVariance = asVector(map, "sourcePositionVariance");
        ps.angle = MathHelper.deg2rad(map["angle"].asFloat());
        ps.angleVariance = MathHelper.deg2rad(map["angleVariance"].asFloat());
        ps.startParticleSize = map["startParticleSize"].asFloat();
        ps.startParticleSizeVariance = map["startParticleSizeVariance"].asFloat();
        ps.finishParticleSize = map["finishParticleSize"].asFloat();
        ps.finishParticleSizeVariance = map["finishParticleSizeVariance"].asFloat();
        ps.startColor = asColor(map, "startColor");
        ps.startColorVariance = asColor(map, "startColorVariance");
        ps.finishColor = asColor(map, "finishColor");
        ps.finishColorVariance = asColor(map, "finishColorVariance");
        ps.minRadius = map["minRadius"].asFloat();
        ps.minRadiusVariance = map["minRadiusVariance"].asFloat();
        ps.maxRadius = map["maxRadius"].asFloat();
        ps.maxRadiusVariance = map["maxRadiusVariance"].asFloat();
        ps.rotationStart = MathHelper.deg2rad(map["rotationStart"].asFloat());
        ps.rotationStartVariance = MathHelper.deg2rad(map["rotationStartVariance"].asFloat());
        ps.rotationEnd = MathHelper.deg2rad(map["rotationEnd"].asFloat());
        ps.rotationEndVariance = MathHelper.deg2rad(map["rotationEndVariance"].asFloat());
        ps.rotatePerSecond = MathHelper.deg2rad(map["rotatePerSecond"].asFloat());
        ps.rotatePerSecondVariance = MathHelper.deg2rad(map["rotatePerSecondVariance"].asFloat());
        ps.radialAcceleration = map["radialAcceleration"].asFloat();
        ps.radialAccelerationVariance = map["radialAccelVariance"].asFloat();
        ps.tangentialAcceleration = map["tangentialAcceleration"].asFloat();
        ps.tangentialAccelerationVariance = map["tangentialAccelVariance"].asFloat();
        ps.blendFuncSource = map["blendFuncSource"].asInt();
        ps.blendFuncDestination = map["blendFuncDestination"].asInt();
        ps.textureBitmapData = ParticleLoader.loadTexture(map["textureImageData"].asString(), map["textureFileName"].asString(), path);
        ps.yCoordMultiplier = (map["yCoordFlipped"].asInt() == 1 ? -1.0 : 1.0);
        ps.forceSquareTexture = true;

        return ps;
    }

    private static function asVector(map : Map<String, Dynamic>, prefix : String) : ParticleVector {
        return {
            x: map['${prefix}x'].asFloat(),
            y: map['${prefix}y'].asFloat(),
        };
    }

    private static function asColor(map : Map<String, Dynamic>, prefix : String) : ParticleColor {
        return {
            r: map['${prefix}Red'].asFloat(),
            g: map['${prefix}Green'].asFloat(),
            b: map['${prefix}Blue'].asFloat(),
            a: map['${prefix}Alpha'].asFloat(),
        };
    }
}
