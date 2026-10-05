import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Scope {
  id: mp
  required property var cfg
  required property var fx
  property bool shown: false
  signal dismissed
  property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

  readonly property color base: cfg.bg
  readonly property color card: cfg.pill
  readonly property color acc: cfg.accent
  readonly property color onAcc: (acc.r * 0.299 + acc.g * 0.587 + acc.b * 0.114) > 0.55 ? "#141218" : "#ffffff"
  readonly property color txt: "#e6e6e6"
  readonly property color dim: "#99e6e6e6"
  readonly property string ff: cfg.fontFamily
  readonly property string ifont: cfg.iconFont
  readonly property int r: Math.min(cfg.mediaRadius + 6, 22)

  function fmt(t) {
    const s = Math.max(0, Math.floor(t || 0))
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
  }

  onShownChanged: if (shown) fx.refresh()
  HyprlandFocusGrab { windows: [win]; active: mp.shown; onCleared: mp.dismissed() }
  Timer { interval: 1000; running: mp.shown && mp.player !== null && mp.player.isPlaying; repeat: true; onTriggered: mp.player.positionChanged() }

  component Ico: Text { property string name; text: name; color: mp.txt; font.family: mp.ifont; font.pixelSize: 20 }
  component Lbl: Text { color: mp.txt; font.family: mp.ff; font.pixelSize: 14 }

  component RBtn: Rectangle {
    id: rb
    property string icon
    property int size: 34
    property bool big: false
    signal clicked
    implicitWidth: size; implicitHeight: size; radius: size / 2
    color: big ? mp.acc : (rm.containsMouse ? "#33ffffff" : "#1affffff")
    Ico { anchors.centerIn: parent; name: rb.icon; font.pixelSize: rb.big ? 28 : 20; color: rb.big ? mp.onAcc : mp.txt }
    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; onClicked: rb.clicked() }
  }

  component Chip: Rectangle {
    id: ch
    property string label
    signal clicked
    implicitWidth: cl.implicitWidth + 24; implicitHeight: 32; radius: 16
    color: cm.containsMouse ? "#33ffffff" : "#1affffff"
    Lbl { id: cl; anchors.centerIn: parent; text: ch.label; font.pixelSize: 12 }
    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: ch.clicked() }
  }

  component Toggle: Rectangle {
    id: tg
    property bool on
    signal flip
    implicitWidth: 44; implicitHeight: 24; radius: 12
    color: on ? mp.acc : "#44ffffff"
    Rectangle {
      width: 18; height: 18; radius: 9; y: 3
      x: tg.on ? 23 : 3
      color: tg.on ? mp.onAcc : "#fff"
      Behavior on x { NumberAnimation { duration: 120 } }
    }
    MouseArea { anchors.fill: parent; onClicked: tg.flip() }
  }

  PanelWindow {
    id: win
    visible: mp.shown
    anchors { left: true; bottom: !mp.cfg.barTop; top: mp.cfg.barTop }
    margins { left: 10 + mp.cfg.barMargin; bottom: mp.cfg.barHeight + mp.cfg.barMargin + 8; top: mp.cfg.barHeight + mp.cfg.barMargin + 8 }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 460
    implicitHeight: body.implicitHeight + 28
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      radius: 24
      color: Qt.alpha(mp.base, 0.97)
      border.width: 1
      border.color: "#33ffffff"

      ColumnLayout {
        id: body
        anchors { fill: parent; margins: 14 }
        spacing: 12

        // now playing
        RowLayout {
          Layout.fillWidth: true
          spacing: 14
          Rectangle {
            implicitWidth: 92; implicitHeight: 92; radius: 14; color: mp.card; clip: true
            Image { anchors.fill: parent; source: mp.player ? mp.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
            Ico { anchors.centerIn: parent; visible: !mp.player || mp.player.trackArtUrl === ""; name: "music_note"; color: mp.dim; font.pixelSize: 36 }
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Lbl { text: mp.player ? mp.player.trackTitle : "Nothing playing"; font.bold: true; font.pixelSize: 17; Layout.fillWidth: true; elide: Text.ElideRight }
            Lbl { text: mp.player ? mp.player.trackArtist : ""; color: mp.dim; Layout.fillWidth: true; elide: Text.ElideRight }
            Lbl { text: mp.player ? mp.player.identity : ""; color: mp.acc; font.pixelSize: 12 }
          }
        }

        // seek
        RowLayout {
          Layout.fillWidth: true
          spacing: 8
          Lbl { text: mp.fmt(mp.player ? mp.player.position : 0); font.pixelSize: 11; color: mp.dim }
          Rectangle {
            id: seek
            Layout.fillWidth: true
            implicitHeight: 6; radius: 3; color: "#33ffffff"
            Rectangle {
              width: mp.player && mp.player.length > 0 ? seek.width * Math.min(1, mp.player.position / mp.player.length) : 0
              height: parent.height; radius: 3; color: mp.acc
            }
            MouseArea {
              anchors { fill: parent; topMargin: -8; bottomMargin: -8 }
              onClicked: m => { if (mp.player && mp.player.canSeek && mp.player.length > 0) mp.player.position = m.x / seek.width * mp.player.length }
            }
          }
          Lbl { text: mp.fmt(mp.player ? mp.player.length : 0); font.pixelSize: 11; color: mp.dim }
        }

        // controls
        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 14
          RBtn { icon: "skip_previous"; onClicked: mp.player?.previous() }
          RBtn { icon: mp.player && mp.player.isPlaying ? "pause" : "play_arrow"; size: 48; big: true; onClicked: mp.player?.togglePlaying() }
          RBtn { icon: "skip_next"; onClicked: mp.player?.next() }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "#22ffffff" }

        // EasyEffects
        RowLayout {
          Layout.fillWidth: true
          spacing: 10
          Ico { name: "equalizer"; color: mp.acc }
          Lbl { text: "EasyEffects"; font.bold: true }
          Lbl { text: mp.cfg.eqPreset; color: mp.dim; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
          Toggle { on: mp.cfg.eqOn; onFlip: mp.fx.setOn(!mp.cfg.eqOn) }
        }

        Rectangle {
          visible: mp.fx.presets.length === 0
          Layout.fillWidth: true
          implicitHeight: nf.implicitHeight + 24; radius: mp.r; color: mp.card
          Lbl { id: nf; anchors { fill: parent; margins: 12 } wrapMode: Text.WordWrap; font.pixelSize: 12; color: mp.dim
                text: "No EasyEffects presets found. Install easyeffects, open it once and save or load a preset, then press Refresh." }
        }

        ListView {
          visible: mp.fx.presets.length > 0
          Layout.fillWidth: true
          Layout.preferredHeight: 170
          clip: true; spacing: 4
          opacity: mp.cfg.eqOn ? 1 : 0.5
          model: mp.fx.presets
          boundsBehavior: Flickable.StopAtBounds
          delegate: Rectangle {
            id: pr
            required property string modelData
            readonly property bool cur: mp.cfg.eqPreset === modelData
            width: ListView.view.width
            height: 36; radius: 12
            color: cur ? Qt.alpha(mp.acc, 0.25) : (pm.containsMouse ? "#1affffff" : mp.card)
            border.width: cur ? 1 : 0
            border.color: mp.acc
            RowLayout {
              anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
              Lbl { text: pr.modelData; Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 13 }
              Ico { visible: pr.cur; name: "check"; color: mp.acc; font.pixelSize: 18 }
            }
            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: mp.fx.load(pr.modelData) }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 8
          Chip { label: "Refresh"; onClicked: mp.fx.refresh() }
          Chip { label: "Open EasyEffects"; onClicked: mp.fx.openApp() }
        }
      }
    }
  }
}
