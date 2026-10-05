from pathlib import Path
import shutil

root = Path.home() / ".config" / "quickshell"

patches = {
    "Launcher.qml": [
        (
            '''    Rectangle {
      width: Math.min(680, parent.width - 40)
      height: Math.min(520, parent.height - 80)
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.14
      radius: ln.r''',
            '''    Rectangle {
      id: launcherCard
      width: Math.min(680, parent.width - 40)
      height: Math.min(520, parent.height - 80)
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.14
      radius: ln.r
      opacity: ln.shown ? 1 : 0
      scale: ln.shown ? 1 : 0.96

      Behavior on opacity {
        NumberAnimation {
          duration: 220
          easing.type: Easing.OutCubic
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: 260
          easing.type: Easing.OutBack
          easing.overshoot: 1.02
        }
      }'''
        )
    ],

    "MediaPanel.qml": [
        (
            '''    Rectangle {
      anchors.fill: parent
      radius: 24
      color: Qt.alpha(mp.base, 0.97)''',
            '''    Rectangle {
      id: mediaCard
      anchors.fill: parent
      radius: 24
      color: Qt.alpha(mp.base, 0.97)
      opacity: mp.shown ? 1 : 0
      scale: mp.shown ? 1 : 0.97

      Behavior on opacity {
        NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: 240
          easing.type: Easing.OutCubic
        }
      }'''
        )
    ],

    "Osd.qml": [
        (
            '''    Rectangle {
      anchors.fill: parent
      radius: 28
      color: Qt.alpha(osd.cfg.bg, 0.96)''',
            '''    Rectangle {
      id: osdCard
      anchors.fill: parent
      radius: 28
      color: Qt.alpha(osd.cfg.bg, 0.96)
      opacity: osd.show ? 1 : 0
      scale: osd.show ? 1 : 0.94

      Behavior on opacity {
        NumberAnimation {
          duration: 140
          easing.type: Easing.OutCubic
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: 180
          easing.type: Easing.OutBack
          easing.overshoot: 1.05
        }
      }'''
        )
    ],

    "Notifs.qml": [
        (
            '''          property bool live: true
          visible: live''',
            '''          property bool live: true
          property bool entering: true
          visible: true
          opacity: live ? 1 : 0
          scale: entering ? 0.96 : 1

          Behavior on opacity {
            NumberAnimation {
              duration: 180
              easing.type: Easing.OutCubic
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: 220
              easing.type: Easing.OutBack
              easing.overshoot: 1.02
            }
          }'''
        ),
        (
            '''          Component.onCompleted: ns.active++''',
            '''          Component.onCompleted: {
            ns.active++
            entering = false
          }'''
        )
    ],

    "LayoutEditor.qml": [
        (
            '''    opacity: ed.dragId === wid ? 0.35 : 1
    color:''',
            '''    opacity: ed.dragId === wid ? 0.35 : 1

    Behavior on opacity {
      NumberAnimation {
        duration: 120
        easing.type: Easing.OutCubic
      }
    }

    color:''',
        ),
        (
            '''  opacity: 0.95
''',
            '''  opacity: ed.dragId !== "" ? 0.95 : 0

  Behavior on opacity {
    NumberAnimation {
      duration: 120
      easing.type: Easing.OutCubic
    }
  }
'''
        )
    ]
}


def patch_file(name, replacements):
    path = root / name

    if not path.exists():
        print(f"[skip] {name}: file not found")
        return

    backup = path.with_suffix(path.suffix + ".pre-animation")
    if not backup.exists():
        shutil.copy2(path, backup)

    text = path.read_text()
    original = text
    changed = 0

    for old, new in replacements:
        count = text.count(old)

        if count == 0:
            print(f"[skip] {name}: pattern not found")
            continue

        if count > 1:
            print(f"[skip] {name}: pattern matched {count} times")
            continue

        text = text.replace(old, new, 1)
        changed += 1

    if text != original:
        path.write_text(text)
        print(f"[ok]   {name}: {changed} change(s)")
    else:
        print(f"[none] {name}: unchanged")


print("neucolonize animation pass")
print()

for name, replacements in patches.items():
    patch_file(name, replacements)

print()
print("done.")
print()
print("backups:")
for name in patches:
    backup = root / f"{name}.pre-animation"
    if backup.exists():
        print(f"  {backup.name}")
