#!/usr/bin/env bash

PROJ_ROOT=$(pwd)

pyenv local 3.13.0
pip install pipx scons
	
# build gd_cubism
build_gdcubism () {
	WORKDIR=$PROJ_ROOT/thirdparty/gd_cubism

	cd $WORKDIR
	
	## Cubism SDK must be acquired and prepared ahead of time
	## Agreeing to terms of use are required for all developers building with the SDK
	##
	## https://www.live2d.com/en/sdk/download/native/
	##
	## OpenVT is currently developed against Native version 5 R3
	scons platform=linux arch=x86_64 target=template_debug debug_symbols=yes GDCUBISM_DYLIB=1
	cp -r $WORKDIR/demo/addons/gd_cubism $PROJ_ROOT/addons
	rm -r $PROJ_ROOT/addons/gd_cubism/example
	rm -r $PROJ_ROOT/addons/gd_cubism/cs
	cp LICENSE.en.adoc $PROJ_ROOT/addons/gd_cubism/LICENSE.en.adoc
	cp README.en.adoc $PROJ_ROOT/addons/gd_cubism/README.en.adoc
	
	echo "*" > $PROJ_ROOT/addons/gd_cubism/.gitignore
	
	cd $PROJ_ROOT
}

build_virtualcamera () {
	WORKDIR=$PROJ_ROOT/thirdparty/gd-virtualcamera

	cd $WORKDIR
	
	scons platform=linux arch=x86_64 target=template_debug debug_symbols=yes
	scons platform=linux arch=x86_64 target=template_release
	cp -r $WORKDIR/demo/bin $PROJ_ROOT/addons/gd-virtualcamera
	cp LICENSE.md $PROJ_ROOT/addons/gd-virtualcamera/LICENSE.md
	cp README.md $PROJ_ROOT/addons/gd-virtualcamera/README.md
	echo "*" > $PROJ_ROOT/addons/gd-virtualcamera/.gitignore
	
	cd $PROJ_ROOT
}

build_keylogger() {
	WORKDIR=$PROJ_ROOT/thirdparty/godot-keylogger

	cd $WORKDIR

	$WORKDIR/build.sh

	cp -r $WORKDIR/godot/addons/keylogger $PROJ_ROOT/addons
	echo "*" > $PROJ_ROOT/addons/keylogger/.gitignore
}

# fetch submodules if they haven't been already
git fetch --recurse-submodules

build_gdcubism
build_virtualcamera
build_keylogger
