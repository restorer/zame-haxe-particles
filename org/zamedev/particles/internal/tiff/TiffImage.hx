package org.zamedev.particles.internal.tiff;

import openfl.utils.ByteArray;

class TiffImage {
    public var width : Int;
    public var height : Int;
    public var pixels : ByteArray;

    public function new(width : Int, height : Int, pixels : ByteArray) {
        this.width = width;
        this.height = height;
        this.pixels = pixels;
    }
}
