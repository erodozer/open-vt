# Godot Standards

## GDScript internal, Rust external

OpenVT attempts to use as much out of the box functionality of Godot as possible with low overhead and dependencies, as it's already a rather feature rich runtime.
As such, GDScript is the primary language of the codebase of OpenVT itself.

When integrating with native libraries, Godot-Rust is the preferred tool of choice.  Such integrations should be general purpose enough to be developed outside of OpenVT and depended on.  The /thirdparty directory holds git submodules to various external dependencies that are built and loaded into the /addons folder of the project.

## Minimum engine version, Engine patching

The codebase will generally target the latest stable 4.x series Godot runtimes to edit the project.  Due to necessary patches against Godot for rendering models, at least version 4.7.1 is required.

Unless absolutely necessary, such as with the Ayagami patches, the project should strive not to rely on custom engine builds.  This lowers the maintenance complexity and lowers the overhead for making contributions.

# AI models and agents

Please do not use AI agents to contribute to this project, neither directly or indirectly. Examples of forbidden conduct include using an AI agent to do any of the following:

- Author any code related to this project
- Analyze this repository's code
- Review code intended for contribution

Any attempts to contribute that ignore or circumvent these rules will result in immediate rejection, and the user barred from further contributions.

# Do it for your Oshi

OpenVT is a project born out of the love of vtubers and respect for its human community of hard working creators.  Building software for their sake using AI agents spits in the face of those same creators.  To give them ethically built tools that empower their artistry is the highest priority of OpenVT.

There's no pressure to implement anything as fast as possible, it's not a race.  If you wish to contribute, take the time to learn and build with your own imagination and skills, even if for no other sake than to make your oshi proud.
