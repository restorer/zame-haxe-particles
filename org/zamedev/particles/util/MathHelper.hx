package org.zamedev.particles.util;

class MathHelper {
    public static inline var EPSILON : Float = 0.00000001;

    public static inline function deg2rad(deg : Float) : Float {
        return deg / 180.0 * Math.PI;
    }

    public static inline function rnd1to1() : Float {
        return Math.random() * 2.0 - 1.0;
    }

    public static function clamp(value : Float) : Float {
        return (value < 0.0 ? 0.0 : (value < 1.0 ? value : 1.0));
    }
}
