import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: ex
  required property var cfg
  property bool launcherOpen: false
  property bool ccOpen: false
  property bool mediaOpen: false
  property bool wallOpen: false
  property real mediaClosedAt: 0
  signal openSettings

  function toggleMedia() {
    if (Date.now() - mediaClosedAt < 400) return
    mediaOpen = !mediaOpen
  }

  Effects { id: fxr; cfg: ex.cfg }
  Notifs { id: nsrv; cfg: ex.cfg }
  Osd { cfg: ex.cfg }
  Launcher { cfg: ex.cfg; shown: ex.launcherOpen; onDismissed: ex.launcherOpen = false }
  WallpaperPicker { cfg: ex.cfg; shown: ex.wallOpen; onDismissed: ex.wallOpen = false }
  ControlCenter {
    cfg: ex.cfg
    notifs: nsrv
    shown: ex.ccOpen
    onDismissed: ex.ccOpen = false
    onOpenSettings: { ex.ccOpen = false; ex.openSettings() }
  }
  MediaPanel {
    cfg: ex.cfg
    fx: fxr
    shown: ex.mediaOpen
    onDismissed: { ex.mediaClosedAt = Date.now(); ex.mediaOpen = false }
  }

  IpcHandler { target: "launcher"; function toggle(): void { ex.launcherOpen = !ex.launcherOpen } }
  IpcHandler { target: "cc"; function toggle(): void { ex.ccOpen = !ex.ccOpen } }
  IpcHandler { target: "media"; function toggle(): void { ex.toggleMedia() } }
  IpcHandler { target: "wallpaper"; function toggle(): void { ex.wallOpen = !ex.wallOpen } }
}
