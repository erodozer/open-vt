<p align="center">
  <img src="branding/monochrome.svg" width="180" />
</p>
<p align="center">OpenVT is software for Vtubing with 2D Avatars<br>Focused on stable, cross platform availability and compatibility with commercial alternatives</p>

## Why should I care?

OpenVT strives to be largely compatible with [VTubeStudio](https://denchisoft.com/), the premier software for [Live2D](https://www.live2d.com/en/) based tracking for Vtubing.  
Models can be used between the two, sharing the same files without need to make adjustments.  Any OpenVT specific settings are kept separately to avoid possible collisions with namespacing. 
Whenever possible, VTubeStudio will still be respected as the standard.  OpenVT exists not as a competitor, but as an alternative to serve the niche that is not directly supported due to VTS's commercial obligations.

The majority of the vtuber ecosystem is built in Unity largely due to familiarity of the software for 3D applications and the available, well documented, first-party support Live2D by Cubism.
By contrast, OpenVT is built in Godot, leveraging much of the same open-source software for facial tracking, and native libraries for controlling models.  The application is designed to be easy to use and provide a consistent experience for streaming across operating systems, with Linux desktop support being a top priority.

<img src="https://github.com/user-attachments/assets/1b473b34-d3a2-4ca8-aaba-4869706a4d8f" />
<img src="https://github.com/user-attachments/assets/33037252-d183-49a2-8af0-e43e935797d6" />

### Supported Trackers

- OpenSeeFace (Separate executable required)
- VTubeStudio (TCP over Wi-fi)

### Examples of Improvements over VTS

- native Linux support
- open source development allowing for community driven feature delivery 
- transparent window support to simplify alpha based capture in OBS in all supported operating systems
- adjustable filtering settings, allowing for sharper scaling of pixel art models
- popout controls
- generally lower system requirements

## Building

OpenVT attempts to use as much out of the box functionality of Godot as possible with low overhead and dependencies, as it's already a rather feature rich runtime.
As such, GDScript is the primary language of the codebase.

Using the base version of at least Godot 4.5 will be enough to edit the project.
Be sure to grab the export templates if you wish to export standalone binaries.

### Building Dependencies

This should be done before attempting to open or run the project, otherwise Godot will complain about missing files and classes.

Please follow the readmes and build instructions of any git submodules to know of any specifics dependencies.
Git submodules are not expected to change frequently.  Building the dependencies for most will only need to be done once.

The provided `build_dependencies.sh` script is designed to build each submodule and move its outputs to the required locations in the project filesystem for openvt to run.

## References

- https://github.com/DenchiSoft/VTubeStudio
- https://github.com/emilianavt/OpenSeeFace
- https://www.live2d.com/en/
- https://github.com/MizunagiKB/gd_cubism
- https://github.com/Live2D/CubismNativeFramework

UI Icons from
https://github.com/free-icons/free-icons

OpenVT Mascot by @erodozer

## Licensing

For full functionality, this application depends on the Live2D Cubism SDK, a copyrighted work developed by Live2D Inc

Any forks and distributions of OpenVT by third parties are not directly covered, with developers requiring explicit permission as per the [license agreement](https://www.live2d.com/eula/live2d-proprietary-software-license-agreement_en.html) and qualify as an Expandable Application.
