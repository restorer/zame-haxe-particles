package org.zamedev.particles;

import openfl.Assets;
import openfl.gl.GL;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import org.zamedev.lib.FileUtils;

using StringTools;
using org.zamedev.lib.DynamicTools;
using org.zamedev.lib.XmlExt;

class ParticleSystemLoader {
    public static function loadFromPlist(path:String):ParticleSystem {
        var root = Xml.parse(Assets.getText(path)).firstElement().firstElement();

        if (root.nodeName != "dict") {
            throw new Error('Expecting element "dict", but "${root.nodeName}" found');
        }

        var key:String = null;
        var map:Map<String, Dynamic> = new Map<String, Dynamic>();
        var basePath:String = FileUtils.dirname(path);

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

                    map[key] = value;

                case "string":
                    map[key] = textValue;

                default:
                    throw new Error('Unsupported element "${node.nodeName}"');
            }

            key = null;
        }

        var ps = new ParticleSystem();

        ps.emitterType = map["emitterType".toLowerCase()].asInt();
        ps.maxParticles = map["maxParticles".toLowerCase()].asInt();
        ps.positionType = map["positionType".toLowerCase()].asInt();
        ps.duration = map["duration".toLowerCase()].asFloat();
        ps.gravity = asVector(map, "gravity");
        ps.particleLifespan = map["particleLifespan".toLowerCase()].asFloat();
        ps.particleLifespanVariance = map["particleLifespanVariance".toLowerCase()].asFloat();
        ps.speed = map["speed".toLowerCase()].asFloat();
        ps.speedVariance = map["speedVariance".toLowerCase()].asFloat();
        ps.sourcePosition = asVector(map, "sourcePosition");
        ps.sourcePositionVariance = asVector(map, "sourcePositionVariance");
        ps.angle = map["angle".toLowerCase()].asFloat() / 180.0 * Math.PI;
        ps.angleVariance = map["angleVariance".toLowerCase()].asFloat() / 180.0 * Math.PI;
        ps.startParticleSize = map["startParticleSize".toLowerCase()].asFloat();
        ps.startParticleSizeVariance = map["startParticleSizeVariance".toLowerCase()].asFloat();
        ps.finishParticleSize = map["finishParticleSize".toLowerCase()].asFloat();
        ps.finishParticleSizeVariance = map["finishParticleSizeVariance".toLowerCase()].asFloat();
        ps.startColor = asColor(map, "startColor");
        ps.startColorVariance = asColor(map, "startColorVariance");
        ps.finishColor = asColor(map, "finishColor");
        ps.finishColorVariance = asColor(map, "finishColorVariance");
        ps.minRadius = map["minRadius".toLowerCase()].asFloat();
        ps.minRadiusVariance = map["minRadiusVariance".toLowerCase()].asFloat();
        ps.maxRadius = map["maxRadius".toLowerCase()].asFloat();
        ps.maxRadiusVariance = map["maxRadiusVariance".toLowerCase()].asFloat();
        ps.rotationStart = map["rotationStart".toLowerCase()].asFloat();
        ps.rotationStartVariance = map["rotationStartVariance".toLowerCase()].asFloat();
        ps.rotationEnd = map["rotationEnd".toLowerCase()].asFloat();
        ps.rotationEndVariance = map["rotationEndVariance".toLowerCase()].asFloat();
        ps.rotatePerSecond = map["rotatePerSecond".toLowerCase()].asFloat() / 180.0 * Math.PI;
        ps.rotatePerSecondVariance = map["rotatePerSecondVariance".toLowerCase()].asFloat() / 180.0 * Math.PI;
        ps.radialAcceleration = map["radialAcceleration".toLowerCase()].asFloat();
        ps.radialAccelerationVariance = map["radialAccelVariance".toLowerCase()].asFloat();
        ps.tangentialAcceleration = map["tangentialAcceleration".toLowerCase()].asFloat();
        ps.tangentialAccelerationVariance = map["tangentialAccelVariance".toLowerCase()].asFloat();
        ps.blendFuncSource = map["blendFuncSource".toLowerCase()].asInt();
        ps.blendFuncDestination = map["blendFuncDestination".toLowerCase()].asInt();
        ps.textureBitmapData = Assets.getBitmapData(basePath + "/" + map["textureFileName".toLowerCase()].asString());
        ps.yCoordMultiplier = (map["yCoordFlipped".toLowerCase()].asInt() == 1 ? -1.0 : 1.0);

        if (ps.blendFuncDestination == GL.DST_ALPHA) {
            ps.blendFuncDestination = GL.ONE;
        }

        return ps;
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
