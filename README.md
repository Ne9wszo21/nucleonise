<div align="center">**necleonize quickshell**

a clean, minimal, and customizable desktop shell built with quickshell and qml.

</div>---

necleonize is designed to provide a cohesive desktop experience without getting in the way. it combines useful desktop components such as an osd, launcher, settings, and system integrations into one lightweight shell.

table of contents

- "features" (#features)
- "requirements" (#requirements)
- "installation" (#installation)
- "structure" (#structure)
- "components" (#components)
  - "osd" (#osd)
  - "launcher" (#launcher)
  - "settings" (#settings)
- "configuration" (#configuration)
- "customization" (#customization)
- "troubleshooting" (#troubleshooting)
  - "quickshell doesn't start" (#quickshell-doesnt-start)
  - "audio osd doesn't work" (#audio-osd-doesnt-work)
  - "changes aren't appearing" (#changes-arent-appearing)
- "development" (#development)
- "license" (#license)
- "philosophy" (#philosophy)

features

- minimal ui — clean visuals designed to stay out of the way.
- audio osd — displays volume and audio-related changes using pipewire.
- launcher — quickly launch applications and access useful actions.
- clipboard support — convenient clipboard integration.
- settings — centralized configuration for customizing the shell.
- quickshell-based — built using quickshell and qt/qml.
- modular design — components can be modified or extended independently.
- lightweight — designed to provide useful desktop functionality without becoming a full desktop environment.

requirements

- linux
- quickshell
- qt/qml
- pipewire
- wayland compositor

installation

clone the repository:

git clone <your-repository-url> ~/.config/quickshell/necleonize

then start necleonize:

quickshell -c necleonize

structure

necleonize/
├── shell.qml
├── osd.qml
├── settings.qml
├── launcher.qml
├── config/
└── assets/

the exact structure may change as the project develops.

components

osd

handles on-screen displays such as volume changes and other temporary system feedback.

necleonize uses quickshell's pipewire integration for audio information.

launcher

provides the application launcher and related actions.

settings

contains user-facing configuration and settings used by the shell.

configuration

necleonize is designed to keep user configuration separate from individual ui components.

configuration can include:

- osd duration
- ui behavior
- launcher options
- appearance
- animations
- system integration settings

customization

because necleonize is written in qml, most visual aspects can be customized directly.

you can modify:

- colors
- fonts
- spacing
- animations
- corner radius
- osd behavior
- launcher appearance
- component positioning

troubleshooting

quickshell doesn't start

run necleonize directly from a terminal:

quickshell -c necleonize

check the terminal output for qml or quickshell errors.

audio osd doesn't work

check that pipewire is running:

systemctl --user status pipewire

also make sure your audio sink is available to quickshell.

changes aren't appearing

restart necleonize:

quickshell -c necleonize

running quickshell from a terminal while developing makes qml errors easier to identify.

development

necleonize is an evolving project.

the goal is to keep the shell:

- simple
- fast
- modular
- customizable
- easy to maintain

contributions, fixes, and improvements are welcome.

license

choose a license for the project and place the license text in:

LICENSE

philosophy

«a desktop shell should enhance the desktop, not become the desktop.»

necleonize aims to provide useful desktop functionality while keeping the interface clean, responsive, and unobtrusive.

---

<div align="center">necleonize quickshell

minimal. modular. yours.

</div>
