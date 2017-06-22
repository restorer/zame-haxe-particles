package org.zamedev.particles.internal;

import openfl.display.Tilemap;

#if !flash

import openfl.display.DisplayObject;

class TilemapExt extends Tilemap {
    private override function __hitTest(
        x : Float,
        y : Float,
        shapeFlag : Bool,
        stack : Array<DisplayObject>,
        interactiveOnly : Bool,
        hitObject : DisplayObject
    ) : Bool {
        return false;
    }
}

#else

typedef TilemapExt = Tilemap;

#end
