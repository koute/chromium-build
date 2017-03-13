#!/bin/bash

pushd chromium-build/chromium
cp out/Release/{character_data_generator,proto_zero_plugin,protoc,genmacro,genmodule,genstring,genversion,genperf,re2c,yasm,mojo_runner} $TRAVIS_BUILD_DIR/cache/ || true
