package org.zamedev.particles.internal.tiff;

import haxe.io.Bytes;
import openfl.utils.ByteArray;

// http://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf

class TiffDecoder {
    private var data : Bytes;
    private var isBigEndian : Bool;
    private var ifdOffset : Int;

    public function new(data : Bytes) {
        if (data.length < 8) {
            throw "invalid header: size";
        }

        this.data = data;

        if (data.get(0) == 0x4d && data.get(1) == 0x4d) {
            isBigEndian = true;
        } else if (data.get(0) == 0x49 && data.get(1) == 0x49) {
            isBigEndian = false;
        } else {
            throw "invalid header: Identifier";
        }

        if (getUShort(2) != 0x2a) {
            throw "invalid header: Version";
        }

        ifdOffset = getULong(4);

        if (ifdOffset >= data.length) {
            throw "invalid header: IFDOffset";
        }
    }

    public function run() : TiffImage {
        return parseIfd(ifdOffset);
    }

    private function parseIfd(pos : Int) : TiffImage {
        var numDirEntries = getUShort(pos);
        pos += 2;

        var tagMap = new Map<Int, Array<Int>>();

        for (i in 0 ... numDirEntries) {
            parseTag(pos, tagMap);
            pos += 12;
        }

        // getULong(pos) - next IFD offset, but:
        // "A Baseline TIFF reader is not required to read any IFDs beyond the first one"

        return parseImage(tagMap);
    }

    private function parseImage(tagMap : Map<Int, Array<Int>>) : TiffImage {
        if (!tagMap.exists(cast TagId.ImageWidth)
            || !tagMap.exists(cast TagId.ImageLength)
            || !tagMap.exists(cast TagId.PhotometricInterpretation)
            || !tagMap.exists(cast TagId.StripOffsets)
            || !tagMap.exists(cast TagId.StripByteCounts)
        ) {
            throw "required tags are missing: ImageWidth | ImageLength | PhotometricInterpretation | StripOffsets | StripByteCounts";
        }

        if (tagMap[cast TagId.PhotometricInterpretation][0] != cast PhotometricInterpretation.RGB) {
            throw "PhotometricInterpretation must be = RGB";
        }

        if (getOrDefault(tagMap, TagId.Compression, [cast Compression.Uncompressed])[0] != cast Compression.Uncompressed) {
            throw "Compression must be = Uncompressed";
        }

        if (getOrDefault(tagMap, TagId.Orientation, [1])[0] != 1) {
            throw "Orientation must be = 1";
        }

        if (getOrDefault(tagMap, TagId.PlanarConfiguration, [cast PlanarConfiguration.Chunky])[0] != cast PlanarConfiguration.Chunky) {
            throw "PlanarConfiguration must be = Chunky";
        }

        var imageLength = tagMap[cast TagId.ImageLength][0];
        var rowsPerStrip = getOrDefault(tagMap, TagId.RowsPerStrip, [0xffffffff])[0];
        var stripsPerImage = Std.int((imageLength + rowsPerStrip - 1) / rowsPerStrip);

        if (getOrDefault(tagMap, TagId.SamplesPerPixel, [1])[0] != 4) {
            throw "SamplesPerPixel must be = 4";
        }

        if (!compareArray(getOrDefault(tagMap, TagId.BitsPerSample, [1, 1, 1, 1]), [8, 8, 8, 8])) {
            throw "BitsPerSample must be = [8, 8, 8, 8]";
        }

        var sampleFormat = getOrDefault(
            tagMap,
            TagId.SampleFormat,
            [cast SampleFormat.Unsigned, cast SampleFormat.Unsigned, cast SampleFormat.Unsigned, cast SampleFormat.Unsigned]
        );

        for (i in 0 ... sampleFormat.length) {
            if (sampleFormat[i] == cast SampleFormat.Undefined) {
                sampleFormat[i] = cast SampleFormat.Unsigned;
            }
        }

        if (!compareArray(
            sampleFormat,
            [cast SampleFormat.Unsigned, cast SampleFormat.Unsigned, cast SampleFormat.Unsigned, cast SampleFormat.Unsigned]
        )) {
            throw "unsupported SampleFormat value";
        }

        var extraSamples = getOrDefault(tagMap, TagId.ExtraSamples, []);

        if (extraSamples.length != 1) {
            throw "ExtraSamples.length must be = 1";
        }

        var extraSampleValue:Int = extraSamples[0];

        if ((extraSampleValue != cast ExtraSamples.AssociatedAlpha) && (extraSampleValue != cast ExtraSamples.UnassociatedAlpha)) {
            throw "unsupported ExtraSamples value";
        }

        var stripOffsets = tagMap[cast TagId.StripOffsets];

        if (stripOffsets.length != stripsPerImage) {
            throw "invalid StripOffsets length";
        }

        var stripByteCounts = tagMap[cast TagId.StripByteCounts];

        if (stripOffsets.length != stripsPerImage) {
            throw "invalid StripByteCounts length";
        }

        var imageWidth = tagMap[cast TagId.ImageWidth][0];
        var computedSize = Lambda.fold(stripByteCounts, function(a : Int, b : Int) : Int { return a + b; }, 0);

        if (imageWidth * imageLength * 4 != computedSize) {
            throw "invalid StripByteCounts value";
        }

        for (bc in stripByteCounts) {
            if (bc % 4 != 0) {
                throw "each StripByteCounts element must be dividable by 4";
            }
        }

        #if flash
            var pixels = new ByteArray();
            pixels.length = computedSize;
        #else
            var pixels = new ByteArray(computedSize);
        #end

        pixels.position = 0;

        #if js
            var ba = ByteArray.fromBytes(data);

            for (i in 0 ... stripsPerImage) {
                ba.position = stripOffsets[i];
                var count = Std.int(stripByteCounts[i] / 4);

                for (j in 0 ... count) {
                    var a = ba.readUnsignedByte();
                    var r = ba.readUnsignedByte();
                    var g = ba.readUnsignedByte();
                    var b = ba.readUnsignedByte();

                    pixels.writeByte(a);
                    pixels.writeByte(r);
                    pixels.writeByte(g);
                    pixels.writeByte(b);
                }
            }
        #else
            for (i in 0 ... stripsPerImage) {
                var offset = stripOffsets[i];
                var count = Std.int(stripByteCounts[i] / 4);

                for (j in 0 ... count) {
                    #if flash
                        pixels.writeByte(data.get(offset + 3));
                        pixels.writeByte(data.get(offset + 0));
                        pixels.writeByte(data.get(offset + 1));
                        pixels.writeByte(data.get(offset + 2));
                    #else
                        pixels.writeByte(data.get(offset + 0));
                        pixels.writeByte(data.get(offset + 1));
                        pixels.writeByte(data.get(offset + 2));
                        pixels.writeByte(data.get(offset + 3));
                    #end

                    offset += 4;
                }
            }
        #end

        pixels.position = 0;
        return new TiffImage(imageWidth, imageLength, pixels);
    }

    private function getOrDefault(tagMap : Map<Int, Array<Int>>, tagId : TagId, def : Array<Int>) : Array<Int> {
        return (tagMap.exists(cast tagId) ? tagMap[cast tagId] : def);
    }

    private function compareArray(a : Array<Int>, b : Array<Int>) : Bool {
        if (a.length != b.length) {
            return false;
        }

        for (i in 0 ... a.length) {
            if (a[i] != b[i]) {
                return false;
            }
        }

        return true;
    }

    private function parseTag(pos : Int, tagMap : Map<Int, Array<Int>>) : Void {
        var tagId : TagId = cast getUShort(pos);

        switch (tagId) {
            case ImageWidth
                    | ImageLength
                    | BitsPerSample
                    | Compression
                    | PhotometricInterpretation
                    | StripOffsets
                    | Orientation
                    | SamplesPerPixel
                    | RowsPerStrip
                    | StripByteCounts
                    | PlanarConfiguration
                    | ExtraSamples
                    | SampleFormat:
                tagMap[cast tagId] = parseTagData(pos);

            default:
        }
    }

    private function parseTagData(pos : Int) : Array<Int> {
        var dataType : DataType = cast getUShort(pos + 2);
        var dataCount = getULong(pos + 4);

        if (dataCount == 0) {
            throw "data count is zero";
        }

        var sizeInBytes = dataCount * switch (dataType) {
            case BYTE | ASCII | SBYTE | UNDEFINED: 1;
            case SHORT | SSHORT: 2;
            case LONG | SLONG: 4;
            case FLOAT: throw "unsupported data type: FLOAT"; // 4
            case RATIONAL | SRATIONAL | DOUBLE: throw "unsupported data type: RATIONAL | SRATIONAL | DOUBLE"; // 8
        };

        var dataPos = (sizeInBytes <= 4 ? pos + 8 : getULong(pos + 8));
        var result = new Array<Int>();

        for (i in 0 ... dataCount) {
            switch (dataType) {
                case BYTE | ASCII | UNDEFINED:
                    result.push(data.get(dataPos));
                    dataPos++;

                case SBYTE:
                    result.push(getSByte(dataPos));
                    dataPos++;

                case SHORT:
                    result.push(getUShort(dataPos));
                    dataPos += 2;

                case SSHORT:
                    result.push(getSShort(dataPos));
                    dataPos += 2;

                case LONG:
                    result.push(getULong(dataPos));
                    dataPos += 4;

                case SLONG:
                    result.push(getSLong(dataPos));
                    dataPos += 4;

                default:
            }
        }

        return result;
    }

    private function getSByte(pos : Int) : Int {
        var value = data.get(pos);
        return (value <= 0x7f ? value : value - 0x100);
    }

    private function getUShort(pos : Int) : Int {
        if (isBigEndian) {
            return (data.get(pos) << 8) | data.get(pos + 1);
        } else {
            return data.get(pos) | (data.get(pos + 1) << 8);
        }
    }

    private function getSShort(pos : Int) : Int {
        var value = getUShort(pos);
        return (value <= 0x7fff ? value : value - 0x10000);
    }

    private function getULong(pos : Int) : Int {
        if (isBigEndian) {
            return (data.get(pos) << 24) | (data.get(pos + 1) << 16) | (data.get(pos + 2) << 8) | data.get(pos + 3);
        } else {
            return data.get(pos) | (data.get(pos + 1) << 8) | (data.get(pos + 2) << 16) | (data.get(pos + 3) << 24);
        }
    }

    private function getSLong(pos : Int) : Int {
        var value = getULong(pos);
        return (value <= 0x7fffffff ? value : ((value - 0x7fffffff) - 0x7fffffff) - 2);
    }

    public static function decode(data : Bytes) : TiffImage {
        var decoder = new TiffDecoder(data);
        return decoder.run();
    }
}
