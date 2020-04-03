#!/bin/bash

cd $(dirname "$0")
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [ "$BRANCH" == "HEAD" ] ; then
    echo "Publishing is not allowed from \"detached HEAD\""
    echo "Switch to \"master\", \"develop\" or other valid branch and retry"
    exit
fi

if [ "$(git status -s)" != "" ] ; then
    echo "Seems that you have uncommitted changes. Commit and push first, than publish."
    git status -s
    exit
fi

if [ "$(git log --format=format:%H origin/${BRANCH}..${BRANCH})" != "" ] ; then
    echo "Seems that you have unpushed changes. Pull/push first, than publish."
    git log --format=format:"%C(auto)%H %C(green)%an%C(reset) %s" "origin/${BRANCH}..${BRANCH}"
    exit
fi

VERSION="$(cat "./haxelib.json" | grep -e '^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"[0-9.]*"[[:space:]]*,[[:space:]]*$' | sed 's/[^0-9.]//g')"
ESCAPED_VERSION="$(echo "$VERSION" | sed 's/\./\\./g')"
HAS_TAG="$(git tag | grep -e "^v${ESCAPED_VERSION}$")"

if [ "$HAS_TAG" != "" ] ; then
    if [ "$1" == "--retag" ] || [ "$2" == "--retag" ] ; then
        git tag -d "v${VERSION}"
        git push origin ":v${VERSION}"
    else
        echo "Git tag v${VERSION} already exists. If you want to recreate tag, use:"
        echo "$0 --retag"
        exit
    fi
fi

[ -e zame-particles.zip ] && rm zame-particles.zip

zip -r -9 zame-particles.zip * \
    -x 'samples/minimal/export/*' \
    -x 'samples/rendertotexture/export/*' \
    -x 'samples/showcase/export/*' \
    -x 'samples/stresstest/export/*' \
    -x 'samples/tilecontainer/export/*' \
    -x publish-release.sh

if [ "$1" == "--dry-run" ] || [ "$2" == "--dry-run" ] ; then
    exit
fi

[ -e zame-particles.zip ] && haxelib submit zame-particles.zip
[ -e zame-particles.zip ] && rm zame-particles.zip
