package org.zamedev.particles.loaders;

import haxe.Json;
import openfl.Assets;
import org.zamedev.particles.ParticleSystem;
import org.zamedev.particles.util.DynamicExt;
import org.zamedev.particles.util.MathHelper;
import org.zamedev.particles.util.ParticleColor;
import org.zamedev.particles.util.ParticleVector;
import openfl.gl.GL;

using org.zamedev.particles.util.DynamicTools;

class PixiParticleLoader {
    public static function load(path : String, texturePath : String) : ParticleSystem {
        var map:DynamicExt = Json.parse(Assets.getText(path));
        var ps = new ParticleSystem();

        ps.textureBitmapData = ParticleLoader.loadTexture(null, texturePath, path);
        if (ps.textureBitmapData == null)
        {
            return null;
        }

        var scale = map["scale"];
        
        //Assumes texture is rectangular!
        var startSize = scale["start"].asFloat() * ps.textureBitmapData.width;
        var endSize = scale["end"].asFloat() * ps.textureBitmapData.width;
        
        ps.startParticleSize = startSize;
        ps.startParticleSizeVariance = 0;
        ps.finishParticleSize = endSize;
        ps.finishParticleSizeVariance = 0;

        //TODO: There is not a good mapping between the spawn and emitter types, so assume radial for now
        var spawnType = map["spawnType"];
        ps.emitterType = ParticleSystem.EMITTER_TYPE_RADIAL;

        ps.maxParticles = map["maxParticles"].asInt();
        var emissionFreq = map["frequency"].asFloat();
        if (emissionFreq > 0.0) 
        {
            ps.emissionRate = 1.0 / emissionFreq;
        } 
        ps.positionType = 0;
        ps.duration = map["emitterLifetime"].asFloat();
        
        var life = map["lifetime"];
        var lifeMin = life["min"].asFloat();
        var lifeMax = life["max"].asFloat();
        var averageLife = (lifeMin+lifeMax)/2.0;
        ps.particleLifespan = (lifeMin+lifeMax)/2.0;
        ps.particleLifespanVariance = (lifeMax-lifeMin)/2.0;

        var speed = map["speed"];
        var speedMin = speed["min"].asFloat();
        var speedMax = speed["max"].asFloat();
        
        //only applies to gravity emitters (not radial)
        ps.speed = (speedMin+speedMax)/2.0;
        ps.speedVariance = (speedMax-speedMin)/2.0;
        
        ps.gravity = asVector(map, "gravity");
        ps.sourcePosition = { x: 0.0, y: 0.0 };
        ps.sourcePositionVariance = asVector(map, "sourcePositionVariance");
        
        var startRot = map["startRotation"];
        var startRotMin = startRot["min"].asFloat() + 180;
        var startRotMax = startRot["max"].asFloat() + 180;
        
        ps.angle = MathHelper.deg2rad((startRotMin+startRotMax)/2.0);
        ps.angleVariance = MathHelper.deg2rad((startRotMax-startRotMin)/2.0);

       //TODO: color animation not supported in html5
        ps.startColor = asColor(map, "color", "start");
        ps.startColorVariance = { r:0, g:0, b:0, a:0 };
        ps.finishColor = asColor(map, "color", "end");
        ps.finishColorVariance = { r:0, g:0, b:0, a:0 };
                
        var alpha = map["alpha"];        
        ps.startColor.a = alpha["start"].asFloat();        
        ps.finishColor.a = alpha["end"].asFloat();        
                
        //Pixi uses start,end speed, while pex uses a min and max radius for the radial emitter        
        var speed = map["speed"];
        var startSpeed = speed["start"].asFloat();                
        var endSpeed = speed["end"].asFloat();                
        var averageSpeed = (startSpeed + endSpeed)/2.0;
        var minDist = averageSpeed * lifeMin;        
        var maxDist = averageSpeed * lifeMax;
        var averageDist = averageSpeed * averageLife;        
                
        ps.minRadius = averageDist;
        ps.minRadiusVariance = (maxDist - minDist) / 2.0;
        ps.maxRadius = 0;
        ps.maxRadiusVariance = 0;
        
        var rotSpeed = map["rotationSpeed"];
        var rotSpeedMin = rotSpeed["min"].asFloat();
        var rotSpeedMax = rotSpeed["max"].asFloat();
        
        ps.rotationStart = MathHelper.deg2rad((startRotMin+startRotMax)/2.0);
        ps.rotationStartVariance = MathHelper.deg2rad((startRotMax-startRotMin)/2.0);

        var rotMin = rotSpeedMin * averageLife;
        var rotMax = rotSpeedMax * averageLife;
        
        ps.rotationEnd = ps.rotationStart + MathHelper.deg2rad(((rotMin + rotMax)/2.0));
        ps.rotationEndVariance = MathHelper.deg2rad((rotMax-rotMin)/2.0);
              
        //this rotates the emitter itself, which is not supported by pixi
        ps.rotatePerSecond = 0;
        ps.rotatePerSecondVariance = 0;
        
        var blendMode = map["blendMode"];
        if (blendMode == "normal")
        {
           ps.blendFuncSource =  GL.SRC_ALPHA;
           ps.blendFuncDestination = GL.ONE_MINUS_SRC_ALPHA; 
        }
        else if (blendMode == "add")
        {
           ps.blendFuncSource = GL.ONE;
           ps.blendFuncDestination = GL.ONE;
        }
        else if (blendMode == "multiply")
        {
           ps.blendFuncSource = GL.DST_COLOR ;
           ps.blendFuncDestination = GL.ONE_MINUS_SRC_ALPHA;
        }
        else
        {
           ps.blendFuncSource =  GL.SRC_ALPHA;
           ps.blendFuncDestination = GL.ONE_MINUS_SRC_ALPHA; 
        }
       
        ps.yCoordMultiplier = (map["yCoordFlipped"].asInt() == 1 ? -1.0 : 1.0);

        return ps;
    }

    private static function asVector(map : DynamicExt, prefix : String) : ParticleVector {
        return {
            x: map['${prefix}x'].asFloat(),
            y: map['${prefix}y'].asFloat(),
        };
    }

    private static function asColor(map : DynamicExt, param : String, subParam : String) : ParticleColor {
         var paramValue = map[param];
         if (null != paramValue)
         {
            var subParamValue = paramValue[subParam];
            
            var hexStr = StringTools.replace(subParamValue, "#", "0x");
            var hexVal:Int = Std.parseInt(hexStr);
            return
            {
               r:hexVal >> 16 & 0xFF,
               g:hexVal >> 8 & 0xFF,
               b:hexVal & 0xFF,
               a:255.0,
            };
         }
        return {
            r: 0.0,
            g: 0.0,
            b: 0.0,
            a: 255.0,
        };
    }
}
