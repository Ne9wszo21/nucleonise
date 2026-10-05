import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
  id: wp
  required property var cfg

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      screen: modelData

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      exclusionMode: ExclusionMode.Ignore
      color: "black"

      Item {
        anchors.fill: parent
        clip: true

        Image {
          id: wallpaper

          anchors.fill: parent

          source: wp.cfg.wallpaper !== ""
                  ? "file://" + wp.cfg.wallpaper
                  : ""

          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: false

          sourceSize {
            width: parent.width
            height: parent.height
          }

          opacity: status === Image.Ready ? 1 : 0

          Behavior on opacity {
            NumberAnimation {
              duration: 500
              easing.type: Easing.OutCubic
            }
          }

          onStatusChanged: {
            if (status === Image.Ready) {
              fade.restart()
            }
          }

          NumberAnimation {
            id: fade
            target: wallpaper
            property: "opacity"
            from: 0
            to: 1
            duration: 650
            easing.type: Easing.OutCubic
          }

          Behavior on source {
            enabled: false
          }
        }

        Rectangle {
          anchors.fill: parent
          color: "black"
          opacity: wallpaper.status === Image.Ready ? 0 : 0.35

          Behavior on opacity {
            NumberAnimation {
              duration: 450
              easing.type: Easing.OutCubic
            }
          }
        }
      }
    }
  }
}
