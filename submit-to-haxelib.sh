#!/bin/bash

pushd `dirname "$0"`

[ -e zame-particles.zip ] && rm zame-particles.zip
[ -e samples/luxeengine/bin ] && rm -r samples/luxeengine/bin
[ -e samples/minimal/export ] && rm -r samples/minimal/export
[ -e samples/showcase/export ] && rm -r samples/showcase/export
[ -e samples/stresstest/export ] && rm -r samples/stresstest/export

zip -r -9 zame-particles.zip * -x submit-to-haxelib.sh

[ -e zame-particles.zip ] && haxelib submit zame-particles.zip
[ -e zame-particles.zip ] && rm zame-particles.zip

popd
