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

The majority of the vtuber ecosystem is built in Unity largely due to familiarity of the software for 3D applications and the available, well documented, first-party support Live2D by Cubism.
By contrast, OpenVT is built in Godot, leveraging much of the same open-source software for facial tracking, and native libraries for controlling models.  The application is designed to be easy to use and provide a consistent experience for streaming across operating systems, with Linux desktop support being a top priority.

### Guidelines

OpenVT attempts to use as much out of the box functionality of Godot as possible with low overhead and dependencies, as it's already a rather feature rich runtime.
As such, GDScript is the primary language of the codebase.

The codebase will generally target the latest stable 4.x series Godot runtimes to edit the project.
Be sure to grab the export templates if you wish to create standalone binaries.

### Building Dependencies

This should be done before attempting to open or run the project, otherwise Godot will complain about missing files and classes.

Please follow the readmes and build instructions of any git submodules included in the [thirdparty/](./thirdparty) directory to know of any specifics.  Git submodules are subject to changes as critical improvements in dependencies are made.

The provided [build_dependencies.sh](./build_dependencies.sh) script is designed to build each submodule and move its outputs to the required locations in the project filesystem for openvt to run.

## References

- https://github.com/DenchiSoft/VTubeStudio
- https://github.com/emilianavt/OpenSeeFace

## Licensing

Additional licenses are found in the [/license](./license) directory.
