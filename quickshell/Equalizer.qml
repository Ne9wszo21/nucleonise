import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Scope {
  id: eq
  required property var cfg
  readonly property string sinkName: "effect_input.quickshell_eq"
  readonly property var node: Pipewire.nodes.values.find(n => n.name === sinkName) ?? null
  readonly property int nodeId: node && node.id !== undefined ? node.id : -1
  readonly property bool available: nodeId >= 0
  readonly property bool active: !!Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.name === sinkName
  property int prevSink: -1
  property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  readonly property var freqs: ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
  readonly property var presets: [
    { n: "Flat", g: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
    { n: "Bass Boost", g: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0] },
    { n: "Treble Boost", g: [0, 0, 0, 0, 0, 0, 2, 4, 5, 6] },
    { n: "Vocal", g: [-2, -2, -1, 1, 3, 3, 2, 1, 0, -1] },
    { n: "Rock", g: [5, 4, 2, -1, -2, -1, 2, 4, 5, 5] },
    { n: "Pop", g: [-1, 1, 3, 4, 3, 0, -1, -1, 1, 2] },
    { n: "Electronic", g: [5, 4, 1, 0, -2, 2, 1, 2, 4, 5] },
    { n: "Classical", g: [0, 0, 0, 0, 0, 0, -2, -2, -2, -4] }
  ]

  function parse(s) {
    const a = String(s).split(",").map(x => parseFloat(x))
    const out = []
    for (let i = 0; i < 10; i++) out.push(isNaN(a[i]) ? 0 : Math.max(-12, Math.min(12, a[i])))
    return out
  }

  function push() {
    if (!available) return
    let p = ""
    for (let i = 0; i < 10; i++) p += '"eq_band_' + (i + 1) + ':Gain" ' + (cfg.eqOn ? gains[i] : 0).toFixed(1) + " "
    Quickshell.execDetached(["pw-cli", "s", String(nodeId), "Props", "{ params = [ " + p + "] }"])
  }

  function setBand(i, db) {
    const g = gains.slice()
    g[i] = db
    gains = g
    if (cfg.eqPreset !== "Custom") cfg.eqPreset = "Custom"
    saveT.restart()
    sched.restart()
  }

  function setPreset(pr) {
    gains = pr.g.slice()
    cfg.eqPreset = pr.n
    saveT.restart()
    sched.restart()
  }

  function toggleOn() { cfg.eqOn = !cfg.eqOn; sched.restart() }

  function useAsOutput(v) {
    if (!available) return
    if (v) {
      prevSink = Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.id : -1
      Quickshell.execDetached(["wpctl", "set-default", String(nodeId)])
    } else {
      const all = Pipewire.nodes.values
      const hw = all.find(n => n.id === prevSink && n.name !== sinkName)
        ?? all.find(n => n.isSink && !n.isStream && (n.name.startsWith("alsa_output") || n.name.startsWith("bluez_output")))
      if (hw) Quickshell.execDetached(["wpctl", "set-default", String(hw.id)])
    }
  }

  Timer { id: sched; interval: 90; onTriggered: eq.push() }
  Timer { id: saveT; interval: 600; onTriggered: eq.cfg.eqBands = eq.gains.join(",") }
  onNodeIdChanged: if (nodeId >= 0) sched.restart()
  Component.onCompleted: { gains = parse(cfg.eqBands); sched.restart() }

  Connections {
    target: eq.cfg
    function onEqBandsChanged() {
      if (eq.cfg.eqBands !== eq.gains.join(",")) { eq.gains = eq.parse(eq.cfg.eqBands); sched.restart() }
    }
    function onEqOnChanged() { sched.restart() }
  }
}
