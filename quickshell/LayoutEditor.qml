import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: ed
  required property var host
  implicitWidth: col.implicitWidth
  implicitHeight: col.implicitHeight

  readonly property var catalog: [
    { id: "launcher", label: "Launcher", icon: "apps" },
    { id: "workspaces", label: "Workspaces", icon: "grid_view" },
    { id: "media", label: "Media player", icon: "music_note" },
    { id: "apps", label: "Running apps", icon: "view_carousel" },
    { id: "tray", label: "System tray", icon: "category" },
    { id: "vitals", label: "CPU and RAM", icon: "speed" },
    { id: "weather", label: "Weather", icon: "partly_cloudy_day" },
    { id: "status", label: "Status icons", icon: "wifi" },
    { id: "cc", label: "Control center", icon: "tune" },
    { id: "settings", label: "Settings", icon: "settings" },
    { id: "clock", label: "Clock", icon: "schedule" },
    { id: "wallpaper", label: "Wallpaper", icon: "wallpaper" }
  ]
  readonly property var keys: ["layoutLeft", "layoutCenter", "layoutRight"]
  readonly property string placed: host.cfg.layoutLeft + "," + host.cfg.layoutCenter + "," + host.cfg.layoutRight
  readonly property var available: catalog.filter(c => !placed.split(",").includes(c.id))

  property string dragId: ""
  property string hover: ""
  property real ghostX: 0
  property real ghostY: 0
  property string widgetSettingsId: ""
  property bool widgetSettingsOpen: false
  signal widgetSettingsRequested(string widgetId)

  function openSettings(id) {
    widgetSettingsId = id
    widgetSettingsRequested(id)
  }

  function closeSettings() {
    widgetSettingsOpen = false
  }

  function setCfg(name, value) {
    host.cfg[name] = value
  }

  function cfg(name, fallback) {
    const v = host.cfg[name]
    return v === undefined ? fallback : v
  }

  function info(id) { return catalog.find(c => c.id === id) ?? { id: id, label: id, icon: "widgets" } }
  function list(z) { return String(host.cfg[z]).split(",").filter(x => x !== "") }
  function save(z, a) { host.cfg[z] = a.join(",") }

  function strip(id) {
    for (const z of keys) {
      const a = list(z)
      const i = a.indexOf(id)
      if (i >= 0) { a.splice(i, 1); save(z, a) }
    }
  }

  function drop(id, zone, index) {
    const target = zone && zone !== "avail" ? zone : ""
    let idx = index
    if (target) {
      const from = list(target).indexOf(id)
      if (from >= 0 && from < idx) idx -= 1
    }
    strip(id)
    if (target) {
      const a = list(target)
      a.splice(Math.max(0, Math.min(idx, a.length)), 0, id)
      save(target, a)
    }
  }

  function reset() {
    host.cfg.layoutLeft = "launcher,workspaces,media"
    host.cfg.layoutCenter = "apps"
    host.cfg.layoutRight = "tray,vitals,weather,status,cc,clock"
  }

  function itemFor(z) { return z === "layoutLeft" ? zL : z === "layoutCenter" ? zC : zR }

  function zoneAt(p) {
    const spots = [[zL, "layoutLeft"], [zC, "layoutCenter"], [zR, "layoutRight"], [avBox, "avail"]]
    for (const s of spots) {
      const q = ed.mapToItem(s[0], p.x, p.y)
      if (q.x >= 0 && q.y >= 0 && q.x <= s[0].width && q.y <= s[0].height) return s[1]
    }
    return ""
  }

  function indexIn(z, p) {
    const zone = itemFor(z)
    const q = ed.mapToItem(zone.list, p.x, p.y)
    let n = 0
    for (let i = 0; i < zone.rep.count; i++) {
      const it = zone.rep.itemAt(i)
      if (it && it.y + it.height / 2 < q.y) n++
    }
    return n
  }

  function track(p) {
    ghostX = p.x - 85
    ghostY = p.y - 19
    hover = zoneAt(p)
  }

  component Ico: Text { property string name; text: name; color: ed.host.txt; font.family: ed.host.ifont; font.pixelSize: 18 }
  component Lbl: Text { color: ed.host.txt; font.family: ed.host.ff; font.pixelSize: 14 }

  component Chip: Rectangle {
    id: ch
    property string wid
    property string src
    readonly property bool inZone: src !== "avail"

    Layout.fillWidth: true
    implicitHeight: 40
    radius: 12
    color: cm.containsMouse ? Qt.lighter(ed.host.card, 1.5) : Qt.lighter(ed.host.card, 1.25)
    opacity: ed.dragId === wid ? 0.35 : 1

    Behavior on opacity {
      NumberAnimation {
        duration: 120
        easing.type: Easing.OutCubic
      }
    }

    RowLayout {
      anchors {
        fill: parent
        leftMargin: 10
        rightMargin: 42
      }
      spacing: 8

      Ico {
        name: ed.info(ch.wid).icon
      }

      Lbl {
        text: ed.info(ch.wid).label
        font.pixelSize: 13
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Ico {
        visible: ch.inZone
        name: "close"
        font.pixelSize: 16
        color: ed.host.dim

        MouseArea {
          anchors.fill: parent
          anchors.margins: -6
          z: 30
          onClicked: function(mouse) {
            mouse.accepted = true
            ed.drop(ch.wid, "avail", 0)
          }
        }
      }
    }

    MouseArea {
      id: cm
      anchors.fill: parent
      anchors.rightMargin: ch.inZone ? 38 : 0
      hoverEnabled: true
      preventStealing: true
      cursorShape: Qt.OpenHandCursor

      onPressed: function(m) {
        ed.dragId = ch.wid
        ed.track(mapToItem(ed, m.x, m.y))
      }

      onPositionChanged: function(m) {
        if (pressed)
          ed.track(mapToItem(ed, m.x, m.y))
      }

      onReleased: function(m) {
        const p = mapToItem(ed, m.x, m.y)
        const z = ed.zoneAt(p)
        const i = z !== "" && z !== "avail" ? ed.indexIn(z, p) : 0
        const id = ch.wid

        ed.dragId = ""
        ed.hover = ""

        if (z !== "")
          ed.drop(id, z, i)
      }

      onCanceled: {
        ed.dragId = ""
        ed.hover = ""
      }
    }

    Rectangle {
      visible: ch.inZone
      z: 100
      width: 30
      height: 30
      radius: 9
      anchors.right: parent.right
      anchors.rightMargin: 5
      anchors.verticalCenter: parent.verticalCenter
      color: gear.containsMouse ? "#35ffffff" : "#18ffffff"
      border.width: 1
      border.color: gear.containsMouse ? "#70ffffff" : "#30ffffff"

      Text {
        anchors.centerIn: parent
        text: "settings"
        color: gear.containsMouse ? ed.host.acc : ed.host.dim
        font.family: ed.host.ifont
        font.pixelSize: 17
      }

      MouseArea {
        id: gear
        anchors.fill: parent
        z: 200
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        onPressed: function(mouse) {
          mouse.accepted = true
        }

        onClicked: function(mouse) {
          mouse.accepted = true
          ed.dragId = ""
          ed.hover = ""
          ed.host.openWidget(ch.wid)
        }
      }
    }
  }

  component Zone: Rectangle {
    id: zc
    property string zone
    property string title
    property string items
    property alias list: lst
    property alias rep: rp
    readonly property var arr: items.split(",").filter(x => x !== "")
    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.fillHeight: true
    implicitHeight: Math.max(230, lst.implicitHeight + 70)
    radius: ed.host.r
    color: ed.host.card
    border.width: ed.hover === zc.zone ? 2 : 1
    border.color: ed.hover === zc.zone ? ed.host.acc : "#22ffffff"

    ColumnLayout {
      anchors { fill: parent; margins: 12 }
      spacing: 8
      Lbl { text: zc.title; font.bold: true }
      ColumnLayout {
        id: lst
        Layout.fillWidth: true
        spacing: 6
        Repeater {
          id: rp
          model: zc.arr
          Chip { required property string modelData; wid: modelData; src: zc.zone }
        }
      }
      Lbl { visible: zc.arr.length === 0; text: "Drop widgets here"; color: ed.host.dim; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
      Item { Layout.fillHeight: true }
    }
  }

  ColumnLayout {
    id: col
    anchors.fill: parent
    spacing: 14

    // available widgets
    Rectangle {
      id: avBox
      Layout.fillWidth: true
      implicitHeight: av.implicitHeight + 28
      radius: ed.host.r
      color: ed.host.card
      border.width: ed.hover === "avail" ? 2 : 1
      border.color: ed.hover === "avail" ? ed.host.acc : "#22ffffff"

      ColumnLayout {
        id: av
        anchors { fill: parent; margins: 14 }
        spacing: 10
        Lbl { text: "Available widgets"; font.bold: true }
        Lbl { text: "Drag a widget into a box below. Drop it back here to remove it."; color: ed.host.dim; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        GridLayout {
          Layout.fillWidth: true
          columns: 3; columnSpacing: 8; rowSpacing: 8
          Repeater {
            model: ed.available
            Chip { required property var modelData; wid: modelData.id; src: "avail"; Layout.preferredWidth: 1 }
          }
        }
        Lbl { visible: ed.available.length === 0; text: "Every widget is on the bar"; color: ed.host.dim; font.pixelSize: 12 }
      }
    }

    // zones
    RowLayout {
      Layout.fillWidth: true
      spacing: 12
      Zone { id: zL; zone: "layoutLeft"; title: "Left"; items: host.cfg.layoutLeft }
      Zone { id: zC; zone: "layoutCenter"; title: "Center"; items: host.cfg.layoutCenter }
      Zone { id: zR; zone: "layoutRight"; title: "Right"; items: host.cfg.layoutRight }
    }

    Rectangle {
      implicitWidth: rl.implicitWidth + 24; implicitHeight: 32; radius: 16
      color: rm.containsMouse ? "#33ffffff" : "#1affffff"
      Lbl { id: rl; anchors.centerIn: parent; text: "Reset layout"; font.pixelSize: 12 }
      MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; onClicked: ed.reset() }
    }
  }

  component Toggle: Rectangle {
    id: tg
    property bool value: false
    property string title: ""
    property string description: ""
    signal toggled(bool value)

    implicitWidth: 48
    implicitHeight: 28
    radius: 14
    color: tg.value ? ed.host.acc : "#333333"
    border.width: 1
    border.color: tg.value ? ed.host.acc : "#44ffffff"

    Rectangle {
      width: 22
      height: 22
      radius: 11
      anchors.verticalCenter: parent.verticalCenter
      x: tg.value ? parent.width - width - 3 : 3
      color: "#ffffff"

      Behavior on x {
        NumberAnimation { duration: 140 }
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: tg.toggled(!tg.value)
    }
  }

  component Choice: Rectangle {
    id: choice
    property string value: ""
    property string current: ""
    property string description: ""
    signal selected(string value)

    implicitHeight: 32
    implicitWidth: Math.max(76, tx.implicitWidth + 22)
    radius: 16
    color: choice.current === choice.value ? ed.host.acc : "#22ffffff"
    border.width: 1
    border.color: choice.current === choice.value ? ed.host.acc : "#33ffffff"

    Text {
      id: tx
      anchors.centerIn: parent
      text: choice.value
      color: choice.current === choice.value ? ed.host.onAcc : ed.host.txt
      font.family: ed.host.ff
      font.pixelSize: 12
    }

    MouseArea {
      anchors.fill: parent
      onClicked: choice.selected(choice.value)
    }
  }

  component Setting: ColumnLayout {
    id: setting
    property string title: ""
    property string description: ""

    spacing: 3

    RowLayout {
      Layout.fillWidth: true
      Text {
        text: setting.title
        color: ed.host.txt
        font.family: ed.host.ff
        font.pixelSize: 13
        Layout.fillWidth: true
      }
      Item {
        implicitWidth: 1
        implicitHeight: 1
      }
    }

    Text {
      text: setting.description
      color: ed.host.dim
      font.family: ed.host.ff
      font.pixelSize: 11
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    default property alias controls: controlsItem.data
    Item {
      id: controlsItem
      Layout.fillWidth: true
      implicitHeight: childrenRect.height
    }
  }

  // floating chip that follows the cursor while dragging
  Rectangle {
    visible: ed.dragId !== ""
    z: 100
    x: ed.ghostX; y: ed.ghostY
    width: 170; height: 38; radius: 19
    color: ed.host.acc
    opacity: ed.dragId !== "" ? 0.95 : 0

  Behavior on opacity {
    NumberAnimation {
      duration: 120
      easing.type: Easing.OutCubic
    }
  }
    RowLayout {
      anchors.centerIn: parent
      spacing: 8
      Ico { name: ed.info(ed.dragId).icon; color: ed.host.acc }
      Lbl { text: ed.info(ed.dragId).label; color: ed.host.acc; font.bold: true; font.pixelSize: 13 }
    }
  }
}
