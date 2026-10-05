import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Scope {
  id: ns
  required property var cfg
  property alias server: srv
  property int active: 0

  Process {
    id: notifSound
    command: ["canberra-gtk-play", "-f", "/home/tekmaster/Downloads/windows-error.wav"]
  }

  NotificationServer {
    id: srv
    keepOnReload: false
    bodySupported: true
    actionsSupported: true
    imageSupported: true
    onNotification: n => {
      n.tracked = true
      notifSound.running = true
    }
  }

  PanelWindow {
    visible: ns.active > 0 && !ns.cfg.dnd
    anchors { top: true; right: true }
    margins { top: 8; right: 12 }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 340
    implicitHeight: col.implicitHeight + 2
    color: "transparent"

    ColumnLayout {
      id: col
      width: parent.width
      spacing: 8

      Repeater {
        model: srv.trackedNotifications

        Rectangle {
          id: card
          required property var modelData
          property bool live: true
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
          }
          Layout.fillWidth: true
          implicitHeight: tc.implicitHeight + 24
          radius: Math.min(ns.cfg.notifsRadius + 6, 22)
          color: Qt.alpha(ns.cfg.bg, 0.96)
          border.width: 1
          border.color: "#66ffffff"

          Component.onCompleted: {
            ns.active++
            entering = false
          }
          Component.onDestruction: if (live) ns.active--
          onLiveChanged: if (!live) ns.active--

          Timer {
            running: true
            interval: 6000
            onTriggered: card.live = false
          }

          ColumnLayout {
            id: tc
            anchors { fill: parent; margins: 12 }
            spacing: 2

            Text {
              text: card.modelData.appName
              color: ns.cfg.accent
              font.family: ns.cfg.fontFamily
              font.pixelSize: 11
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            Text {
              text: card.modelData.summary
              color: "#ffffff"
              font.family: ns.cfg.fontFamily
              font.pixelSize: 14
              font.bold: true
              Layout.fillWidth: true
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
            }

            Text {
              visible: text !== ""
              text: card.modelData.body
              color: "#cce6e6e6"
              font.family: ns.cfg.fontFamily
              font.pixelSize: 12
              Layout.fillWidth: true
              wrapMode: Text.Wrap
              maximumLineCount: 3
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: card.modelData.dismiss()
          }
        }
      }
    }
  }
}
