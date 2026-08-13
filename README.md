<p align="center">
  <img src="branding/monochrome.svg" width="180" />
</p>
<p align="center">OpenVT is software for 2D Vtubing</p>

<img src="https://img.itch.zone/aW1nLzIzOTYyMzE3LnBuZw==/original/RvA2OU.png" />
<img src="https://img.itch.zone/aW1nLzI0MzgwMzM0LnBuZw==/original/yLLOfx.png" />

### Supported Trackers

- OpenSeeFace (Separate executable required)
- VTubeStudio (TCP over Wi-fi)

### Differences from Alternatives

- native Linux support
- open source development allowing for community driven feature delivery 
- transparent window support to simplify alpha based capture in OBS
- adjustable filtering settings, allowing for sharper scaling of pixel art models
- multi-window popout controls

### VTube Studio Compatibility

OpenVT strives to be largely compatible with [VTubeStudio](https://denchisoft.com/).
Assets can be used between the two, sharing the same files without need to make adjustments.  Any OpenVT specific settings are kept separately to avoid possible collisions with namespacing.  Where possible, VTubeStudio will still be respected as the standard.

Feature parity with VTS is a goal, excluding more complex features such as plugin compatibility, and VNet.

## How is it Built?

The majority of the vtuber ecosystem is built in Unity, largely due to familiarity of the software for 3D applications and the direct support for Live2D being provided by Cubism. By contrast, OpenVT is built in Godot with entirely open source solutions.

Development of OpenVT also helps contribute to upstream dependencies, such as Ayagami, benefiting the wider community of games and applications made with Godot.

### Building Dependencies

This should be done before attempting to open or run the project, otherwise Godot will complain about missing files and classes.

Please follow the readmes and build instructions of any git submodules included in the [thirdparty/](./thirdparty) directory to know of any specifics, some may require additional dependencies to be installed.  Git submodules are subject to changes as critical improvements in dependencies are made.

The provided [build_dependencies.sh](./build_dependencies.sh) script is designed to build each submodule and move its outputs to the required locations in the project filesystem for openvt to run.

## References

- https://github.com/DenchiSoft/VTubeStudio
- https://github.com/emilianavt/OpenSeeFace

## Licensing

Additional licenses are found in the [/license](./license) directory.
