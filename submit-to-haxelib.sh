#!/bin/bash

pushd `dirname "$0"`

[ -e zame-particles.zip ] && rm zame-particles.zip

zip -r -9 zame-particles.zip * \
    -x 'samples/minimal/export/*' \
    -x 'samples/rendertotexture/export/*' \
    -x 'samples/showcase/export/*' \
    -x 'samples/stresstest/export/*' \
    -x submit-to-haxelib.sh

[ -e zame-particles.zip ] && haxelib submit zame-particles.zip
[ -e zame-particles.zip ] && rm zame-particles.zip

popd
