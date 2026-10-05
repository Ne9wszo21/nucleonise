import Quickshell
import QtQuick

Item {
  id: host

  required property var widgetData
  required property bool editMode
  required property var manager
  required property int widgetIndex

  x: widgetData.x ?? 80
  y: widgetData.y ?? 80
  width: widgetData.width ?? 240
  height: widgetData.height ?? 160

  Loader {
    anchors.fill: parent

    source: host.widgetData.source ?? ""

    active: host.widgetData.source !== ""
  }

  Rectangle {
    anchors.fill: parent

    color: "transparent"

    border.width: host.editMode ? 2 : 0
    border.color: "#66ffffff"
    radius: 12
  }

  MouseArea {
    id: moveArea

    anchors.fill: parent

    enabled: host.editMode && manager.mode === ""

    cursorShape: Qt.SizeAllCursor

    property real startX
    property real startY
    property real startMouseX
    property real startMouseY

    onPressed: {
      startX = host.x
      startY = host.y
      startMouseX = mouse.x
      startMouseY = mouse.y
    }

    onPositionChanged: {
      if (!pressed)
        return

      host.x = startX + mouse.x - startMouseX
      host.y = startY + mouse.y - startMouseY

      manager.updateWidget(
        host.widgetIndex,
        host.x,
        host.y,
        host.width,
        host.height
      )
    }
  }

  MouseArea {
    anchors.fill: parent

    enabled: host.editMode && manager.mode === "remove"

    cursorShape: Qt.PointingHandCursor

    onClicked: {
      manager.removeWidget(host.widgetIndex)
    }
  }

  Rectangle {
    visible: host.editMode && manager.mode === "resize"

    width: 20
    height: 20
    radius: 10

    color: "#eeffffff"

    anchors {
      right: parent.right
      bottom: parent.bottom
      margins: -8
    }

    MouseArea {
      anchors.fill: parent

      cursorShape: Qt.SizeFDiagCursor

      property real startWidth
      property real startHeight
      property real startMouseX
      property real startMouseY

      onPressed: {
        startWidth = host.width
        startHeight = host.height
        startMouseX = mouse.x
        startMouseY = mouse.y
      }

      onPositionChanged: {
        if (!pressed)
          return

        host.width = Math.max(
          100,
          startWidth + mouse.x - startMouseX
        )

        host.height = Math.max(
          70,
          startHeight + mouse.y - startMouseY
        )

        manager.updateWidget(
          host.widgetIndex,
          host.x,
          host.y,
          host.width,
          host.height
        )
      }
    }
  }
}
