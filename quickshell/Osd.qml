import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Scope {
  id: osd
  required property var cfg
  property var audio: Pipewire.defaultAudioSink?.audio
  property bool ready: false
  property bool show: false

  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
  Timer { interval: 2500; running: true; onTriggered: osd.ready = true }
  Timer { id: hideT; interval: 1400; onTriggered: osd.show = false }

  function pop() {
    if (!ready) return
    show = true
    hideT.restart()
  }

  Connections {
    target: osd.audio
    function onVolumeChanged() { osd.pop() }
    function onMutedChanged() { osd.pop() }
  }

  PanelWindow {
    visible: osd.show
    anchors { bottom: true }
    margins { bottom: osd.cfg.barTop ? 60 : osd.cfg.barHeight + osd.cfg.barMargin + 24 }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 270
    implicitHeight: 56
    color: "transparent"

    Rectangle {
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
      }
      border.width: 1
      border.color: "#33ffffff"
      RowLayout {
        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
        spacing: 12
        Text {
          text: !osd.audio || osd.audio.muted || osd.audio.volume === 0 ? "volume_off" : (osd.audio.volume < 0.4 ? "volume_down" : "volume_up")
          color: "#e6e6e6"; font.family: osd.cfg.iconFont; font.pixelSize: 24
        }
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 8; radius: 4; color: "#33ffffff"
          Rectangle { width: parent.width * Math.min(1, osd.audio ? osd.audio.volume : 0); height: parent.height; radius: 4; color: osd.cfg.accent }
        }
        Text { text: osd.audio ? Math.round(osd.audio.volume * 100) + "%" : ""; color: "#e6e6e6"; font.family: osd.cfg.fontFamily; font.pixelSize: 13; Layout.preferredWidth: 38 }
      }
    }
  }
}
