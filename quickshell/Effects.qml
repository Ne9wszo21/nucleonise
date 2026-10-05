import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: fx
  required property var cfg
  property var presets: []
  property bool ready: false

  function refresh() { listP.running = true }
  function load(name) { cfg.eqPreset = name; Quickshell.execDetached(["easyeffects", "-l", name]) }
  function setOn(v) { cfg.eqOn = v }
  function openApp() { Quickshell.execDetached(["easyeffects"]) }

  Process {
    id: listP
    command: ["sh", "-c", 'for d in "$HOME/.local/share/easyeffects/output" "$HOME/.config/easyeffects/output" /usr/share/easyeffects/output; do ls "$d" 2>/dev/null; done | sed "s/[.]json$//" | sort -u']
    stdout: StdioCollector { onStreamFinished: fx.presets = this.text.split("\n").filter(x => x.trim() !== "") }
  }

  Timer { interval: 3000; running: true; onTriggered: fx.ready = true }

  Connections {
    target: fx.cfg
    function onEqOnChanged() {
      if (fx.ready) Quickshell.execDetached(["easyeffects", "-b", fx.cfg.eqOn ? "2" : "1"])
    }
  }

  Component.onCompleted: refresh()
}
