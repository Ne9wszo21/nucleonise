import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
  id: wp
  required property var cfg
  property bool shown: false
  property var walls: []
  property int sel: 0
  property string query: ""
  signal dismissed

  readonly property color base: cfg.bg
  readonly property color card: cfg.pill
  readonly property color acc: cfg.accent
  readonly property color txt: "#e6e6e6"
  readonly property color dim: "#99e6e6e6"
  readonly property string ff: cfg.fontFamily
  readonly property string ifont: cfg.iconFont
  readonly property int r: Math.min(cfg.wallpaperRadius + 8, 24)
  readonly property var list: walls.filter(w => query === "" || w.toLowerCase().includes(query.toLowerCase()))

  function pick(i) {
    const w = list[i]
    if (w) {
      cfg.wallpaper = w
      dismissed()
    }
  }

  function moveSelection(i) {
    if (list.length === 0)
      return

    sel = Math.max(0, Math.min(i, list.length - 1))
    lv.positionViewAtIndex(sel, ListView.Center)
  }

  onShownChanged: {
    if (shown) {
      wallP.running = true
      sq.text = ""
      sq.forceActiveFocus()
    }
  }

  Process {
    id: wallP

    command: [
      "sh",
      "-c",
      'd=$(printf %s "$1" | sed "s|^~|$HOME|"); find -L "$d" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) | sort | head -200',
      "x",
      wp.cfg.wallDir
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        wp.walls = this.text.split("\n").filter(x => x.trim() !== "")
        const i = wp.walls.indexOf(wp.cfg.wallpaper)
        wp.sel = i >= 0 ? i : 0

        Qt.callLater(() => {
          if (wp.list.length > 0)
            lv.positionViewAtIndex(wp.sel, ListView.Center)
        })
      }
    }
  }

  PanelWindow {
    id: win

    visible: wp.shown

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: wp.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "#88000000"

    MouseArea {
      anchors.fill: parent
      onClicked: wp.dismissed()
    }

    Rectangle {
      id: pickerCard

      clip: true

      width: Math.min(1000, parent.width - 40)
      height: Math.min(640, parent.height - 80)
      anchors.centerIn: parent

      radius: wp.r
      color: Qt.alpha(wp.base, 0.97)

      scale: wp.shown ? 1 : 0.94
      opacity: wp.shown ? 1 : 0

      Behavior on scale {
        NumberAnimation {
          duration: 280
          easing.type: Easing.OutCubic
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: 220
          easing.type: Easing.OutCubic
        }
      }
      border.width: 1
      border.color: "#33ffffff"

      MouseArea {
        anchors.fill: parent
      }

      ColumnLayout {
        anchors {
          fill: parent
          margins: 16
        }

        spacing: 12

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 50
          radius: wp.r - 4
          color: wp.card

          RowLayout {
            anchors {
              fill: parent
              leftMargin: 14
              rightMargin: 14
            }

            spacing: 10

            Text {
              text: "wallpaper"
              color: wp.acc
              font.family: wp.ifont
              font.pixelSize: 22
            }

            TextInput {
              id: sq

              Layout.fillWidth: true
              Layout.fillHeight: true

              verticalAlignment: TextInput.AlignVCenter

              color: wp.txt
              font.family: wp.ff
              font.pixelSize: 16

              clip: true
              selectByMouse: true

              onTextChanged: {
                wp.query = text
                wp.sel = 0

                Qt.callLater(() => {
                  if (wp.list.length > 0)
                    lv.positionViewAtIndex(0, ListView.Center)
                })
              }

              Keys.onPressed: e => {
                if (e.key === Qt.Key_Right)
                  wp.moveSelection(wp.sel + 1)
                else if (e.key === Qt.Key_Left)
                  wp.moveSelection(wp.sel - 1)
                else if (e.key === Qt.Key_Down)
                  wp.moveSelection(wp.sel + 1)
                else if (e.key === Qt.Key_Up)
                  wp.moveSelection(wp.sel - 1)
                else if (e.key === Qt.Key_Escape) {
                  wp.dismissed()
                  e.accepted = true
                  return
                }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                  wp.pick(wp.sel)
                  e.accepted = true
                  return
                }
                else
                  return

                e.accepted = true
              }

              Text {
                visible: sq.text === ""
                text: "Search wallpapers in " + wp.cfg.wallDir
                color: wp.dim
                font.family: wp.ff
                font.pixelSize: 15
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          ListView {
            id: lv

            anchors.fill: parent

            orientation: ListView.Horizontal
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 18

            model: wp.list

            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 170
            preferredHighlightEnd: width / 2 + 170

            highlightMoveDuration: 420
            snapMode: ListView.SnapToItem

            flickDeceleration: 1200
            maximumFlickVelocity: 1800

            delegate: Item {
              id: cell

              required property string modelData
              required property int index

              readonly property real distance:
                Math.abs((lv.contentX + lv.width / 2) -
                         (x + width / 2))

              readonly property real normalizedDistance:
                Math.min(distance / 360, 1)

              readonly property real focusAmount:
                1 - normalizedDistance

              readonly property bool active:
                wp.cfg.wallpaper === modelData

              width: 330
              height: lv.height

              transform: Scale {
                origin.x: width / 2
                origin.y: height / 2
                xScale: 0.78 + cell.focusAmount * 0.22
                yScale: 0.78 + cell.focusAmount * 0.22
              }

              opacity: 0.38 + cell.focusAmount * 0.62

              Behavior on opacity {
                NumberAnimation {
                  duration: 180
                  easing.type: Easing.OutCubic
                }
              }

              Rectangle {
                anchors.centerIn: parent

                width: 300
                height: 180

                radius: 18
                color: wp.card
                clip: true

                Image {
                  anchors.fill: parent
                  source: "file://" + cell.modelData
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  sourceSize.width: 640
                }

                Rectangle {
                  anchors.fill: parent
                  radius: 18
                  color: "transparent"

                  border.width: cell.focusAmount > 0.92 ? 3 : 0
                  border.color: wp.acc

                  opacity: cell.focusAmount

                  Behavior on opacity {
                    NumberAnimation {
                      duration: 180
                    }
                  }
                }

                Text {
                  visible: cell.active

                  text: "check_circle"

                  color: wp.acc
                  font.family: wp.ifont
                  font.pixelSize: 26

                  anchors {
                    top: parent.top
                    right: parent.right
                    margins: 8
                  }
                }

                Text {
                  anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 12
                    rightMargin: 12
                    bottomMargin: 10
                  }

                  text: cell.modelData.split("/").pop()

                  color: "#ffffff"

                  font.family: wp.ff
                  font.pixelSize: 12

                  elide: Text.ElideMiddle
                }
              }

              MouseArea {
                anchors.fill: parent

                onClicked: {
                  if (cell.focusAmount > 0.85)
                    wp.pick(cell.index)
                  else
                    wp.moveSelection(cell.index)
                }
              }
            }
          }
        }

        Text {
          visible: wp.list.length === 0

          text: "No images found in " + wp.cfg.wallDir

          color: wp.dim

          font.family: wp.ff
          font.pixelSize: 14

          Layout.alignment: Qt.AlignHCenter
        }

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter

          text: wp.list.length === 0
                ? ""
                : (wp.list[wp.sel]
                   ? wp.list[wp.sel].split("/").pop()
                   : "") +
                  "   ·   " +
                  (wp.sel + 1) +
                  " / " +
                  wp.list.length

          color: wp.txt
          font.family: wp.ff
          font.pixelSize: 13
        }
      }
    }
  }
}
