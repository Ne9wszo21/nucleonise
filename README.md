<div align="center">

<img src="" width="120">

# **necleonize quickshell**

**a clean, minimal, and customizable desktop shell built with quickshell and qml.**

</div>

---

necleonize is designed to provide a cohesive desktop experience without getting in the way. it combines useful desktop components such as an osd, launcher, settings, and system integrations into one lightweight shell.

## table of contents

- [features](#features)
- [requirements](#requirements)
- [installation](#installation)
- [structure](#structure)
- [components](#components)
  - [osd](#osd)
  - [launcher](#launcher)
  - [settings](#settings)
- [configuration](#configuration)
- [customization](#customization)
- [troubleshooting](#troubleshooting)
  - [quickshell doesn't start](#quickshell-doesnt-start)
  - [audio osd doesn't work](#audio-osd-doesnt-work)
  - [changes aren't appearing](#changes-arent-appearing)
- [development](#development)
- [license](#license)
- [philosophy](#philosophy)

## features

- **minimal ui** — clean visuals designed to stay out of the way.
- **audio osd** — displays volume and audio-related changes using pipewire.
- **launcher** — quickly launch applications and access useful actions.
- **clipboard support** — convenient clipboard integration.
- **settings** — centralized configuration for customizing the shell.
- **quickshell-based** — built using quickshell and qt/qml.
- **modular design** — components can be modified or extended independently.
- **lightweight** — designed to provide useful desktop functionality without becoming a full desktop environment.

## requirements

- linux
- quickshell
- qt/qml
- pipewire
- wayland compositor

## installation

clone the repository:

```bash
git clone https://github.com/your-username/necleonize.git ~/.config/quickshell/necleonize
