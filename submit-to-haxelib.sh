#!/bin/bash

pushd `dirname "$0"`

[ -e zame-particles.zip ] && rm zame-particles.zip

zip -r -9 zame-particles.zip * \
    -x 'samples/luxeengine/bin/*' \
    -x 'samples/minimal/export/*' \
    -x 'samples/rendertotexture/export/*' \
    -x 'samples/showcase/export/*' \
    -x 'samples/stresstest/export/*' \
    -x 'todo-stage3d/*' \
    -x submit-to-haxelib.sh \
    -x _TODO.md \

[ -e zame-particles.zip ] && haxelib submit zame-particles.zip
[ -e zame-particles.zip ] && rm zame-particles.zip

popd
