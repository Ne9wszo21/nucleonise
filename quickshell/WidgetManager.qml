import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
  id: wm

  property bool editMode: false
  property string mode: ""
  property var registry: ({})
  property var widgets: []

  function registerWidget(id, source) {
    var r = {}

    for (var key in registry)
      r[key] = registry[key]

    r[id] = source
    registry = r
  }

  function addWidget(id) {
    if (!registry[id])
      return

    var list = widgets.slice()

    list.push({
      id: id,
      source: registry[id],
      x: 80 + list.length * 30,
      y: 80 + list.length * 30,
      width: 240,
      height: 160
    })

    widgets = list
    mode = ""
  }

  function removeWidget(index) {
    var list = widgets.slice()

    if (index < 0 || index >= list.length)
      return

    list.splice(index, 1)
    widgets = list
    mode = ""
  }

  function changeWidget(index, id) {
    if (!registry[id])
      return

    var list = widgets.slice()

    if (index < 0 || index >= list.length)
      return

    list[index].id = id
    list[index].source = registry[id]
    widgets = list
  }

  function updateWidget(index, x, y, width, height) {
    var list = widgets.slice()

    if (index < 0 || index >= list.length)
      return

    list[index].x = x
    list[index].y = y
    list[index].width = width
    list[index].height = height

    widgets = list
  }

  function clearWidgets() {
    widgets = []
  }

  function toggleEdit() {
    editMode = !editMode

    if (!editMode)
      mode = ""
  }

  IpcHandler {
    target: "widgets"

    function toggleEdit(): void {
      wm.toggleEdit()
    }

    function add(id: string): void {
      wm.addWidget(id)
    }

    function remove(index: int): void {
      wm.removeWidget(index)
    }

    function change(index: int, id: string): void {
      wm.changeWidget(index, id)
    }

    function clear(): void {
      wm.clearWidgets()
    }
  }

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

      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      exclusionMode: ExclusionMode.Ignore
      color: "transparent"

      Item {
        anchors.fill: parent

        Repeater {
          model: wm.widgets

          delegate: WidgetHost {
            required property var modelData
            required property int index

            widgetData: modelData
            editMode: wm.editMode
            manager: wm
            widgetIndex: index
          }
        }
      }
    }
  }

  PanelWindow {
    visible: wm.editMode

    width: 330
    height: 52

    anchors {
      top: true
      left: true
    }

    margins.top: 18

    color: "transparent"

    Rectangle {
      anchors.fill: parent
      radius: 16
      color: "#dd151515"
      border.width: 1
      border.color: "#30ffffff"

      Row {
        anchors.fill: parent
        anchors.margins: 7
        spacing: 5

        Rectangle {
          width: 100
          height: 38
          radius: 11
          color: wm.mode === "add" ? "#404040" : "#252525"

          Text {
            anchors.centerIn: parent
            text: "＋  Add"
            color: "white"
            font.pixelSize: 14
          }

          MouseArea {
            anchors.fill: parent

            onClicked: {
              wm.mode = wm.mode === "add" ? "" : "add"
            }
          }
        }

        Rectangle {
          width: 100
          height: 38
          radius: 11
          color: wm.mode === "remove" ? "#404040" : "#252525"

          Text {
            anchors.centerIn: parent
            text: "−  Remove"
            color: "white"
            font.pixelSize: 14
          }

          MouseArea {
            anchors.fill: parent

            onClicked: {
              wm.mode = wm.mode === "remove" ? "" : "remove"
            }
          }
        }

        Rectangle {
          width: 100
          height: 38
          radius: 11
          color: wm.mode === "resize" ? "#404040" : "#252525"

          Text {
            anchors.centerIn: parent
            text: "⛶  Resize"
            color: "white"
            font.pixelSize: 14
          }

          MouseArea {
            anchors.fill: parent

            onClicked: {
              wm.mode = wm.mode === "resize" ? "" : "resize"
            }
          }
        }
      }
    }
  }

}
