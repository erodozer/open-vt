#!/usr/bin/env bash

PROJ_ROOT=$(pwd)

pyenv local 3.13.0
pip install pipx scons
	
# build gd_cubism
build_gdcubism () {
	WORKDIR=$PROJ_ROOT/thirdparty/gd_cubism

	cd $WORKDIR
	
	## Fetch Cubism SDK
	curl -o sdk.zip https://cubism.live2d.com/sdk-native/bin/CubismSdkForNative-5-r.1.zip
	unzip -o sdk.zip -d thirdparty
	rm sdk.zip
	scons platform=linux arch=x86_64 target=template_debug
	scons platform=linux arch=x86_64 target=template_release
	cp -r $WORKDIR/demo/addons/gd_cubism $PROJ_ROOT/addons
	rm -r $PROJ_ROOT/addons/gd_cubism/example
	rm -r $PROJ_ROOT/addons/gd_cubism/cs
	cp LICENSE.en.adoc $PROJ_ROOT/addons/gd_cubism/LICENSE.en.adoc
	cp README.en.adoc $PROJ_ROOT/addons/gd_cubism/README.en.adoc
	echo "*" > $PROJ_ROOT/addons/gd_cubism/.gitignore
	
	cd $PROJ_ROOT
}

build_keylogger() {
	WORKDIR=$PROJ_ROOT/thirdparty/godot-keylogger

	cd $WORKDIR

	$WORKDIR/build.sh

	cp -r $WORKDIR/godot/addons/keylogger $PROJ_ROOT/addons
	echo "*" > $PROJ_ROOT/addons/keylogger/.gitignore
}

# build openseeface
openseeface () {
	WORKDIR=$PROJ_ROOT/thirdparty/OpenSeeFace

	cd $WORKDIR
	poetry install
	poetry run pyinstaller --onedir --clean --noconfirm facetracker.py
	cp -r models dist/facetracker/models

	# remove previous binaries
	rm -r $PROJ_ROOT/bin/openseeface
	mv dist/facetracker $PROJ_ROOT/bin/openseeface

	cd $PROJ_ROOT
}

# fetch submodules if they haven't been already
git fetch --recurse-submodules

# build_gdcubism
# openseeface
build_keylogger