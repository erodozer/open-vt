#!/usr/bin/env bash

PROJ_ROOT=$(pwd)

pyenv local 3.13.0
pip install pipx scons --quiet
	
# build gd_cubism
build_gdcubism () {
	echo -e "\n#### Preparing gd_cubism\n\n"

	WORKDIR=$PROJ_ROOT/thirdparty/gd_cubism
	ADDONDIR=$PROJ_ROOT/addons/gd_cubism
	NATIVELIB=$(find $WORKDIR/thirdparty -type f -iwholename "*/linux/x86_64/libLive2DCubismCore.so" | head -n 1)

	if [ -z "$NATIVELIB" ]; then
		cat <<- xx
		CUBISM NATIVE LIBRARY: not found


		Cubism SDK must be acquired and prepared ahead of time
		Agreeing to terms of use are required for all developers building with the SDK
	
		https://www.live2d.com/en/sdk/download/native/


		xx

		return 1
	fi

	echo "CUBISM NATIVE LIBRARY:" $NATIVELIB

	mkdir -p $ADDONDIR
	
	cd $WORKDIR
	
	## Cubism SDK must be acquired and prepared ahead of time
	## Agreeing to terms of use are required for all developers building with the SDK
	##
	## https://www.live2d.com/en/sdk/download/native/
	##
	## OpenVT is currently developed against Native version 5 R4.1
	scons platform=linux arch=x86_64 target=template_debug debug_symbols=yes GDCUBISM_DYLIB=1
	cp -r $WORKDIR/demo/addons/gd_cubism/bin $ADDONDIR
	cp -r $WORKDIR/demo/addons/gd_cubism/res $ADDONDIR
	cp $WORKDIR/demo/addons/gd_cubism/gd_cubism.gdextension $ADDONDIR/gd_cubism.gdextension
	
	cp $NATIVELIB $ADDONDIR/bin/linux/x86_64/libLive2DCubismCore.so

	cp LICENSE.en.adoc $PROJ_ROOT/license/LICENSE.gdcubism.adoc
	cp README.en.adoc $ADDONDIR/README.en.adoc
	
	echo "*" > $ADDONDIR/.gitignore
	
	# log completion
	find $ADDONDIR -type f

	cd $PROJ_ROOT
}

build_virtualcamera () {
	echo -e "\n#### Preparing gd-virtualcamera\n\n"

	WORKDIR=$PROJ_ROOT/thirdparty/gd-virtualcamera
	ADDONDIR=$PROJ_ROOT/addons/gd-virtualcamera

	mkdir -p $ADDONDIR
	
	cd $WORKDIR
	
	scons platform=linux arch=x86_64 target=template_debug debug_symbols=yes
	cp -r $WORKDIR/demo/bin/* $ADDONDIR
	cp LICENSE.md $PROJ_ROOT/license/LICENSE.gdvirtualcamera.md
	cp README.md $ADDONDIR/README.md
	echo "*" > $ADDONDIR/.gitignore
	
	# log completion
	find $ADDONDIR -type f

	cd $PROJ_ROOT
}

build_keylogger() {
	echo -e "\n#### Preparing godot-keylogger\n\n"

	WORKDIR=$PROJ_ROOT/thirdparty/godot-keylogger
	ADDONDIR=$PROJ_ROOT/addons/keylogger

	mkdir -p $ADDONDIR

	cd $WORKDIR

	$WORKDIR/build.sh

	cp -r $WORKDIR/godot/addons/keylogger/* $ADDONDIR
	echo "*" > $ADDONDIR/.gitignore
	cp LICENSE.md $PROJ_ROOT/license/LICENSE.gdkeylogger.md
	
	# log completion
	find $ADDONDIR -type f

	cd $PROJ_ROOT
}

# fetch submodules if they haven't been already
git submodule update --init --recursive

build_gdcubism
build_virtualcamera
build_keylogger
