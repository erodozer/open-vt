# Open-vt

OpenVT is software for Vtubing with 2D Avatars, focused on stable, cross platform availability and compatibility with commercial alternatives. 

## Why should I care?

OpenVT strives to be largely compatible with [VTubeStudio](https://denchisoft.com/), the premier software for [Live2D](https://www.live2d.com/en/) based tracking for Vtubing.  
Models can be used between the two, sharing the same files without need to make adjustments.  Any OpenVT specific settings are kept separately to avoid possible collisions with namespacing. 
Whenever possible, VTubeStudio will still be respected as the standard.  OpenVT exists not as a competitor, but as an alternative to serve the niche that is not directly supported due to VTS's commercial obligations.

The majority of the vtuber ecosystem is built in Unity largely due to familiarity of the software for 3D applications and the available, well documented, first-party support Live2D by Cubism.
By contrast, OpenVT is built in Godot, leveraging much of the same open-source software for facial tracking, and native libraries for controlling models.  The application is designed to be easy to use and provide a consistent experience for streaming across operating systems, with Linux desktop support being a top priority.

### Supported Trackers

- OpenSeeFace
- VTubeStudio (TCP over Wi-fi)

### Examples of Improvements over VTS

- native Linux support
- open development allowing for transparent feature delivery
- transparent window support to simplify alpha based capture in OBS without the need for virtual camera or spout in all supported operating systems
- adjustable filtering settings, allowing for sharper scaling of pixel art models
- popout controls
- generally lower system requirements

## Building

OpenVT attempts to use as much out of the box functionality of Godot as possible with low overhead and dependencies, as it's already a rather feature rich runtime.
As such, GDScript is the primary language of the codebase.

Using the base version of at least Godot 4.3 will be enough to edit the project.
Be sure to grab the export templates if you wish to export standalone binaries.

### Building Dependencies

Please follow the readmes and build instructions of any git submodules to know of any specifics.
Git submodules are not expected to change frequently.  Building the dependencies for most will only need to be done once.

#### Requirements
- Godot >= 4.4
- Git
- Docker (for ease of setup)

From the project directory

```
docker build -t openvt-build .
docker run -v .:/app -it openvt-build /app/build_dependencies.sh
```

This volume mounts the project directory into a build container and runs the `build_dependencies.sh` script for you.
The script will moving the files into the appropriate locations.

## References

- https://github.com/DenchiSoft/VTubeStudio
- https://github.com/emilianavt/OpenSeeFace
- https://github.com/Inochi2D/facetrack-d
- https://www.live2d.com/en/
- https://github.com/MizunagiKB/gd_cubism
- https://github.com/Live2D/CubismNativeFramework

UI Icons from
https://github.com/free-icons/free-icons

OpenVT Mascot () Icon by @erodozer
